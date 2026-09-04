-- ============================================================
-- SISTEMA DE ASISTENCIA - MIGRACION SEGURA PARA TU BASE ACTUAL
-- Compatible con sessions.id BIGINT y attendance.session_id UUID.
-- NO elimina tablas, NO borra registros y NO convierte IDs antiguos.
-- ============================================================

-- 1) Asegurar columnas necesarias en SESSIONS sin borrar nada.
alter table public.sessions add column if not exists subject text;
alter table public.sessions add column if not exists group_name text;
alter table public.sessions add column if not exists "group" text;
alter table public.sessions add column if not exists code text;
alter table public.sessions add column if not exists starts_at timestamptz default now();
alter table public.sessions add column if not exists expires_at timestamptz;
alter table public.sessions add column if not exists active boolean default true;

-- Completar group desde group_name cuando sea posible.
update public.sessions
set "group" = group_name
where ("group" is null or "group" = '')
  and group_name is not null;

-- Completar group_name desde group cuando sea posible.
update public.sessions
set group_name = "group"
where (group_name is null or group_name = '')
  and "group" is not null;

-- 2) Asegurar columnas necesarias en ATTENDANCE sin borrar nada.
alter table public.attendance add column if not exists name text;
alter table public.attendance add column if not exists cedula text;
alter table public.attendance add column if not exists celular text;
alter table public.attendance add column if not exists carrera text;
alter table public.attendance add column if not exists semestre integer;
alter table public.attendance add column if not exists correo text;
alter table public.attendance add column if not exists "group" text;
alter table public.attendance add column if not exists created_at timestamptz default now();

-- IMPORTANTE:
-- Tu attendance.session_id existente es UUID y sessions.id es BIGINT.
-- Se conserva session_id para no tocar registros antiguos.
-- Esta nueva columna enlaza las asistencias nuevas con sessions.id BIGINT.
alter table public.attendance add column if not exists session_ref bigint;

-- 3) Compatibilidad con nombres de columnas antiguas.
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='attendance' and column_name='nombres'
  ) then
    execute $q$
      update public.attendance
      set name = coalesce(nullif(name,''), nombres)
      where (name is null or name='') and nombres is not null
    $q$;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='attendance' and column_name='codigo'
  ) then
    execute $q$
      update public.attendance
      set cedula = coalesce(nullif(cedula,''), codigo::text)
      where (cedula is null or cedula='') and codigo is not null
    $q$;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='attendance' and column_name='grupo'
  ) then
    execute $q$
      update public.attendance
      set "group" = coalesce(nullif("group",''), grupo::text)
      where ("group" is null or "group"='') and grupo is not null
    $q$;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='attendance' and column_name='carrrera'
  ) then
    execute $q$
      update public.attendance
      set carrera = coalesce(nullif(carrera,''), carrrera::text)
      where (carrera is null or carrera='') and carrrera is not null
    $q$;
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='attendance' and column_name='fecha_registro'
  ) then
    execute $q$
      update public.attendance
      set created_at = fecha_registro
      where created_at is null and fecha_registro is not null
    $q$;
  end if;
end $$;

update public.attendance set created_at = now() where created_at is null;
alter table public.attendance alter column created_at set default now();

-- 4) Índices para evitar duplicados por clase/estudiante.
create index if not exists attendance_session_ref_idx on public.attendance(session_ref);
create index if not exists attendance_cedula_idx on public.attendance(cedula);
create index if not exists attendance_correo_idx on public.attendance(correo);

create unique index if not exists attendance_session_ref_cedula_uq
on public.attendance(session_ref, cedula)
where session_ref is not null and cedula is not null and cedula <> '';

create unique index if not exists attendance_session_ref_correo_uq
on public.attendance(session_ref, correo)
where session_ref is not null and correo is not null and correo <> '';

-- 5) Clave foránea CORRECTA: BIGINT -> BIGINT.
-- No se toca la columna UUID attendance.session_id antigua.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='attendance_session_ref_fkey'
      and conrelid='public.attendance'::regclass
  ) then
    alter table public.attendance
      add constraint attendance_session_ref_fkey
      foreign key (session_ref)
      references public.sessions(id)
      on delete cascade;
  end if;
end $$;

-- 6) Seguridad RLS.
alter table public.sessions enable row level security;
alter table public.attendance enable row level security;

drop policy if exists "sessions_public_active_read" on public.sessions;
create policy "sessions_public_active_read"
on public.sessions for select
to anon
using (active = true and expires_at > now());

drop policy if exists "sessions_teacher_read" on public.sessions;
create policy "sessions_teacher_read"
on public.sessions for select
to authenticated
using (true);

drop policy if exists "sessions_teacher_insert" on public.sessions;
create policy "sessions_teacher_insert"
on public.sessions for insert
to authenticated
with check (true);

drop policy if exists "sessions_teacher_update" on public.sessions;
create policy "sessions_teacher_update"
on public.sessions for update
to authenticated
using (true)
with check (true);

drop policy if exists "attendance_student_insert" on public.attendance;
create policy "attendance_student_insert"
on public.attendance for insert
to anon
with check (
  exists (
    select 1
    from public.sessions s
    where s.id = public.attendance.session_ref
      and s.active = true
      and s.expires_at > now()
      and s."group" = public.attendance."group"
  )
);

drop policy if exists "attendance_teacher_read" on public.attendance;
create policy "attendance_teacher_read"
on public.attendance for select
to authenticated
using (true);

-- ============================================================
-- CAMPOS USADOS POR ESTA VERSION:
-- name + cedula + celular + carrera + semestre + correo + group
-- session_ref enlaza attendance con sessions.id BIGINT.
-- attendance.session_id UUID antiguo se conserva intacto.
-- ============================================================

-- ============================================================
-- 7) REGISTRO UNICO DE ESTUDIANTES POR CEDULA Y GRUPO
-- Una cedula = un estudiante = un solo grupo.
-- No elimina ni modifica las asistencias historicas existentes.
-- ============================================================

create table if not exists public.student_registry (
  id bigint generated by default as identity primary key,
  cedula text not null unique,
  name text not null,
  celular text,
  carrera text,
  semestre integer,
  correo text,
  "group" text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.student_registry add column if not exists cedula text;
alter table public.student_registry add column if not exists name text;
alter table public.student_registry add column if not exists celular text;
alter table public.student_registry add column if not exists carrera text;
alter table public.student_registry add column if not exists semestre integer;
alter table public.student_registry add column if not exists correo text;
alter table public.student_registry add column if not exists "group" text;
alter table public.student_registry add column if not exists created_at timestamptz default now();
alter table public.student_registry add column if not exists updated_at timestamptz default now();

create unique index if not exists student_registry_cedula_uq
on public.student_registry(cedula)
where cedula is not null and cedula <> '';

-- Inicializa el registro unico usando la PRIMERA asistencia conocida de cada cedula.
-- Si una cedula ya aparece en varios grupos, conserva el grupo del registro mas antiguo.
insert into public.student_registry (cedula,name,celular,carrera,semestre,correo,"group",created_at,updated_at)
select x.cedula,
       coalesce(nullif(x.name,''),'Estudiante'),
       x.celular,x.carrera,x.semestre,x.correo,x."group",
       coalesce(x.created_at,now()),now()
from (
  select distinct on (cedula)
         cedula,name,celular,carrera,semestre,correo,"group",created_at
  from public.attendance
  where cedula is not null and cedula <> ''
    and "group" is not null and "group" <> ''
  order by cedula, created_at asc nulls last
) x
on conflict (cedula) do nothing;

alter table public.student_registry enable row level security;

-- Los estudiantes no necesitan leer directamente el registro completo.
-- Toda la validacion se hace mediante la funcion segura registrar_asistencia().
revoke all on table public.student_registry from anon;
revoke all on table public.student_registry from authenticated;

-- Evita saltarse la validacion insertando directamente en attendance desde la web.
revoke insert on table public.attendance from anon;

create or replace function public.registrar_asistencia(
  p_session_ref bigint,
  p_name text,
  p_cedula text,
  p_celular text,
  p_carrera text,
  p_semestre integer,
  p_correo text
)
returns table(ok boolean, message text, name text, student_group text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_session public.sessions%rowtype;
  v_student public.student_registry%rowtype;
  v_cedula text := btrim(coalesce(p_cedula,''));
  v_correo text := lower(btrim(coalesce(p_correo,'')));
begin
  if v_cedula = '' then
    return query select false,'Debes escribir el numero de cedula.',null::text,null::text;
    return;
  end if;

  select * into v_session
  from public.sessions
  where id=p_session_ref
    and active=true
    and expires_at > now()
  limit 1;

  if not found then
    return query select false,'La clase no existe, esta cerrada o ya vencio.',null::text,null::text;
    return;
  end if;

  select * into v_student
  from public.student_registry
  where cedula=v_cedula
  limit 1;

  if found then
    if v_student."group" is distinct from v_session."group" then
      return query select false,
        format('Esta cedula ya esta registrada en el grupo %s y no puede registrarse en el grupo %s.',v_student."group",v_session."group"),
        v_student.name,v_student."group";
      return;
    end if;

    if exists (
      select 1 from public.attendance
      where session_ref=p_session_ref and cedula=v_cedula
    ) then
      return query select false,'Este estudiante ya registro asistencia en esta clase.',v_student.name,v_student."group";
      return;
    end if;

    insert into public.attendance(session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at)
    values(p_session_ref,v_student.name,v_student.cedula,v_student.celular,v_student.carrera,v_student.semestre,v_student.correo,v_student."group",now());

    return query select true,'Asistencia registrada correctamente.',v_student.name,v_student."group";
    return;
  end if;

  if exists (
    select 1 from public.student_registry
    where correo is not null and correo <> ''
      and lower(correo)=v_correo
      and cedula<>v_cedula
  ) then
    return query select false,'Este correo ya pertenece a otro estudiante.',null::text,null::text;
    return;
  end if;

  insert into public.student_registry(cedula,name,celular,carrera,semestre,correo,"group",created_at,updated_at)
  values(v_cedula,btrim(p_name),btrim(p_celular),btrim(p_carrera),p_semestre,v_correo,v_session."group",now(),now())
  returning * into v_student;

  insert into public.attendance(session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at)
  values(p_session_ref,v_student.name,v_student.cedula,v_student.celular,v_student.carrera,v_student.semestre,v_student.correo,v_student."group",now());

  return query select true,'Estudiante registrado y asistencia guardada correctamente.',v_student.name,v_student."group";
exception
  when unique_violation then
    return query select false,'Este estudiante ya registro asistencia en esta clase.',coalesce(v_student.name,p_name),coalesce(v_student."group",v_session."group");
end;
$$;

revoke all on function public.registrar_asistencia(bigint,text,text,text,text,integer,text) from public;
grant execute on function public.registrar_asistencia(bigint,text,text,text,text,integer,text) to anon, authenticated;

-- ============================================================
-- REGLA FINAL:
-- student_registry.cedula es unica y fija el grupo del estudiante.
-- attendance puede tener muchas asistencias de la misma cedula,
-- pero solo una por sesion, y nunca en un grupo diferente.
-- ============================================================
