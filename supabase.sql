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
