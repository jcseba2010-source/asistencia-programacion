-- ============================================================
-- QR DINAMICO SEGURO - ROTACION CADA 30 SEGUNDOS
-- Compatible con la version MULTIMATERIA.
-- NO BORRA estudiantes, materias, sesiones ni asistencias existentes.
-- Ejecutar UNA VEZ en Supabase > SQL Editor > Run.
-- ============================================================

create table if not exists public.session_qr_tokens (
  session_ref bigint primary key references public.sessions(id) on delete cascade,
  token text not null unique,
  issued_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table public.session_qr_tokens enable row level security;
revoke all on public.session_qr_tokens from anon, authenticated;

-- El docente autenticado genera un token nuevo. El token anterior deja de servir inmediatamente.
create or replace function public.rotate_qr_token(p_session_ref bigint)
returns table(token text, expires_at timestamptz)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_token text;
  v_exp timestamptz;
begin
  if auth.uid() is null then raise exception 'Acceso no autorizado'; end if;
  if not exists(select 1 from public.sessions where id=p_session_ref and active=true) then
    raise exception 'La clase no esta activa';
  end if;

  -- 36 s da un pequeño margen de red, pero el panel rota cada 30 s.
  v_token := encode(gen_random_bytes(24),'hex');
  v_exp := now()+interval '36 seconds';

  insert into public.session_qr_tokens(session_ref,token,issued_at,expires_at)
  values(p_session_ref,v_token,now(),v_exp)
  on conflict(session_ref) do update
    set token=excluded.token,issued_at=excluded.issued_at,expires_at=excluded.expires_at;

  return query select v_token,v_exp;
end;
$$;
revoke all on function public.rotate_qr_token(bigint) from public, anon;
grant execute on function public.rotate_qr_token(bigint) to authenticated;

-- Valida el QR sin exponer la tabla de tokens.
create or replace function public.validar_qr_dinamico(p_code text,p_token text)
returns table(
  ok boolean,
  message text,
  session_ref bigint,
  subject text,
  group_name text,
  class_expires_at timestamptz
)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session public.sessions%rowtype;
  v_qr public.session_qr_tokens%rowtype;
begin
  select * into v_session from public.sessions
  where code=btrim(coalesce(p_code,'')) and active=true limit 1;
  if not found then
    return query select false,'La clase no existe o ya fue finalizada.',null::bigint,null::text,null::text,null::timestamptz; return;
  end if;

  select * into v_qr from public.session_qr_tokens
  where session_ref=v_session.id limit 1;
  if not found or v_qr.token is distinct from btrim(coalesce(p_token,'')) or v_qr.expires_at<=now() then
    return query select false,'Este QR ya vencio. Escanea el QR actual proyectado por el docente.',null::bigint,null::text,null::text,null::timestamptz; return;
  end if;

  return query select true,'QR valido.',v_session.id,v_session.subject,v_session."group",v_session.expires_at;
end;
$$;
revoke all on function public.validar_qr_dinamico(text,text) from public;
grant execute on function public.validar_qr_dinamico(text,text) to anon, authenticated;

-- Se elimina la firma anterior para impedir registrar asistencia sin QR.
drop function if exists public.registrar_asistencia(bigint,text,text,text,text,integer,text);

create or replace function public.registrar_asistencia(
  p_session_ref bigint,
  p_name text,
  p_cedula text,
  p_celular text,
  p_carrera text,
  p_semestre integer,
  p_correo text,
  p_qr_token text
)
returns table(ok boolean,message text,name text,student_group text)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session public.sessions%rowtype;
  v_student public.student_registry%rowtype;
  v_cedula text:=btrim(coalesce(p_cedula,''));
  v_correo text:=lower(btrim(coalesce(p_correo,'')));
  v_qr public.session_qr_tokens%rowtype;
begin
  if v_cedula='' then return query select false,'Debes escribir el numero de cedula.',null::text,null::text;return;end if;

  select * into v_session from public.sessions where id=p_session_ref and active=true limit 1;
  if not found then return query select false,'La clase no existe o fue finalizada.',null::text,null::text;return;end if;

  select * into v_qr from public.session_qr_tokens where session_ref=p_session_ref limit 1;
  if not found or v_qr.token is distinct from btrim(coalesce(p_qr_token,'')) or v_qr.expires_at<=now() then
    return query select false,'El QR vencio. Escanea nuevamente el QR actual proyectado por el docente.',null::text,v_session."group";return;
  end if;

  select * into v_student from public.student_registry where cedula=v_cedula limit 1;
  if found then
    if exists(select 1 from public.attendance where session_ref=p_session_ref and cedula=v_cedula) then
      return query select false,'Este estudiante ya registro asistencia en esta clase.',v_student.name,v_session."group";return;
    end if;

    insert into public.student_enrollments(cedula,subject,group_name,created_at)
    values(v_cedula,v_session.subject,v_session."group",now())
    on conflict(cedula,subject,group_name) do nothing;

    insert into public.attendance(session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at)
    values(p_session_ref,v_student.name,v_student.cedula,v_student.celular,v_student.carrera,v_student.semestre,v_student.correo,v_session."group",now());

    return query select true,'Asistencia registrada correctamente.',v_student.name,v_session."group";return;
  end if;

  if btrim(coalesce(p_name,''))='' or btrim(coalesce(p_celular,''))='' or btrim(coalesce(p_carrera,''))='' or p_semestre is null or v_correo='' then
    return query select false,'REGISTRO_NUEVO: Esta cedula no esta registrada. Completa tus datos una sola vez para continuar.',null::text,v_session."group";return;
  end if;

  if exists(select 1 from public.student_registry where correo is not null and correo<>'' and lower(correo)=v_correo and cedula<>v_cedula) then
    return query select false,'Este correo ya pertenece a otro estudiante.',null::text,null::text;return;
  end if;

  insert into public.student_registry(cedula,name,celular,carrera,semestre,correo,"group",created_at,updated_at)
  values(v_cedula,btrim(p_name),btrim(p_celular),btrim(p_carrera),p_semestre,v_correo,v_session."group",now(),now())
  returning * into v_student;

  insert into public.student_enrollments(cedula,subject,group_name,created_at)
  values(v_cedula,v_session.subject,v_session."group",now())
  on conflict(cedula,subject,group_name) do nothing;

  insert into public.attendance(session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at)
  values(p_session_ref,v_student.name,v_student.cedula,v_student.celular,v_student.carrera,v_student.semestre,v_student.correo,v_session."group",now());

  return query select true,'Estudiante registrado y asistencia guardada correctamente.',v_student.name,v_session."group";
exception when unique_violation then
  return query select false,'Este estudiante ya registro asistencia en esta clase.',coalesce(v_student.name,p_name),v_session."group";
end;
$$;
revoke all on function public.registrar_asistencia(bigint,text,text,text,text,integer,text,text) from public;
grant execute on function public.registrar_asistencia(bigint,text,text,text,text,integer,text,text) to anon, authenticated;

-- Seguridad adicional: el token se borra al finalizar una clase desde el panel opcionalmente
-- (ON DELETE CASCADE aplica si la sesion se elimina). Al marcar active=false, la validacion ya lo rechaza.
