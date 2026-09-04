-- ============================================================
-- QR DINÁMICO 60 SEGUNDOS + VALIDACIÓN DE UBICACIÓN
-- No elimina estudiantes, asistencias, materias ni grupos.
-- Ejecutar UNA VEZ en Supabase > SQL Editor.
-- ============================================================

-- 1) Guardar el punto autorizado del aula en app_settings.
alter table public.app_settings
  add column if not exists attendance_lat double precision,
  add column if not exists attendance_lng double precision,
  add column if not exists attendance_radius_m integer not null default 100;

-- 2) El docente autenticado puede guardar la ubicación actual del aula.
create or replace function public.admin_set_attendance_location(
  p_lat double precision,
  p_lng double precision,
  p_radius_m integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_radius integer;
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  if p_lat is null or p_lng is null
     or p_lat < -90 or p_lat > 90
     or p_lng < -180 or p_lng > 180 then
    raise exception 'Ubicacion invalida';
  end if;

  v_radius := greatest(20, least(1000, coalesce(p_radius_m,100)));

  insert into public.app_settings(id,attendance_lat,attendance_lng,attendance_radius_m)
  values(1,p_lat,p_lng,v_radius)
  on conflict(id) do update set
    attendance_lat=excluded.attendance_lat,
    attendance_lng=excluded.attendance_lng,
    attendance_radius_m=excluded.attendance_radius_m;

  return jsonb_build_object(
    'ok',true,
    'message','Ubicacion del aula guardada.',
    'radius_m',v_radius
  );
end;
$$;

revoke all on function public.admin_set_attendance_location(double precision,double precision,integer) from public;
grant execute on function public.admin_set_attendance_location(double precision,double precision,integer) to authenticated;

-- 3) QR válido exactamente 60 segundos.
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
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  if not exists(
    select 1 from public.sessions s
    where s.id=p_session_ref and s.active=true
  ) then
    raise exception 'La clase no esta activa';
  end if;

  v_token := md5(
    random()::text ||
    clock_timestamp()::text ||
    p_session_ref::text ||
    coalesce(auth.uid()::text,'')
  );
  v_exp := now() + interval '60 seconds';

  insert into public.session_qr_tokens(session_ref,token,issued_at,expires_at)
  values(p_session_ref,v_token,now(),v_exp)
  on conflict(session_ref) do update
    set token=excluded.token,
        issued_at=excluded.issued_at,
        expires_at=excluded.expires_at;

  return query select v_token,v_exp;
end;
$$;

revoke all on function public.rotate_qr_token(bigint) from public;
grant execute on function public.rotate_qr_token(bigint) to authenticated;

-- 4) Eliminar la versión anterior SIN ubicación para que no pueda saltarse
--    la comprobación llamando directamente al RPC antiguo.
drop function if exists public.registrar_asistencia(
  bigint,text,text,text,text,integer,text,text
);

-- 5) Registrar asistencia: QR vigente + ubicación dentro del radio.
create or replace function public.registrar_asistencia(
  p_session_ref bigint,
  p_name text,
  p_cedula text,
  p_celular text,
  p_carrera text,
  p_semestre integer,
  p_correo text,
  p_qr_token text,
  p_lat double precision,
  p_lng double precision
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
  v_aula_lat double precision;
  v_aula_lng double precision;
  v_radio integer;
  v_distancia double precision;
  v_cos double precision;
begin
  if v_cedula='' then
    return query select false,'Debes escribir el numero de cedula.',null::text,null::text;
    return;
  end if;

  select * into v_session
  from public.sessions s
  where s.id=p_session_ref and s.active=true
  limit 1;

  if not found then
    return query select false,'La clase no existe o fue finalizada.',null::text,null::text;
    return;
  end if;

  select * into v_qr
  from public.session_qr_tokens q
  where q.session_ref=p_session_ref
  limit 1;

  if not found
     or v_qr.token is distinct from btrim(coalesce(p_qr_token,''))
     or v_qr.expires_at<=now() then
    return query select false,
      'El QR vencio. Escanea nuevamente el QR actual proyectado por el docente.',
      null::text,v_session."group";
    return;
  end if;

  select a.attendance_lat,a.attendance_lng,a.attendance_radius_m
    into v_aula_lat,v_aula_lng,v_radio
  from public.app_settings a
  where a.id=1;

  if v_aula_lat is null or v_aula_lng is null then
    return query select false,
      'El docente aun no ha configurado la ubicacion autorizada del aula.',
      null::text,v_session."group";
    return;
  end if;

  if p_lat is null or p_lng is null
     or p_lat < -90 or p_lat > 90
     or p_lng < -180 or p_lng > 180 then
    return query select false,
      'No fue posible validar tu ubicacion. Activa la ubicacion del celular.',
      null::text,v_session."group";
    return;
  end if;

  -- Distancia de gran círculo (Haversine equivalente mediante acos), en metros.
  v_cos :=
      cos(radians(v_aula_lat)) * cos(radians(p_lat))
      * cos(radians(p_lng - v_aula_lng))
      + sin(radians(v_aula_lat)) * sin(radians(p_lat));

  v_distancia := 6371000.0 * acos(greatest(-1.0,least(1.0,v_cos)));

  if v_distancia > coalesce(v_radio,100) then
    return query select false,
      ('Estas fuera del area autorizada para registrar asistencia. Distancia aproximada: '
       || round(v_distancia)::text || ' m. Radio permitido: '
       || coalesce(v_radio,100)::text || ' m.')::text,
      null::text,v_session."group";
    return;
  end if;

  select * into v_student
  from public.student_registry sr
  where sr.cedula=v_cedula
  limit 1;

  if found then
    if exists(
      select 1 from public.attendance a
      where a.session_ref=p_session_ref and a.cedula=v_cedula
    ) then
      return query select false,
        'Este estudiante ya registro asistencia en esta clase.',
        v_student.name,v_session."group";
      return;
    end if;

    insert into public.student_enrollments(cedula,subject,group_name,created_at)
    values(v_cedula,v_session.subject,v_session."group",now())
    on conflict(cedula,subject,group_name) do nothing;

    insert into public.attendance(
      session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at
    )
    values(
      p_session_ref,v_student.name,v_student.cedula,v_student.celular,
      v_student.carrera,v_student.semestre,v_student.correo,v_session."group",now()
    );

    return query select true,
      ('Asistencia registrada correctamente. Ubicacion validada a '
       || round(v_distancia)::text || ' m del punto autorizado.')::text,
      v_student.name,v_session."group";
    return;
  end if;

  if btrim(coalesce(p_name,''))=''
     or btrim(coalesce(p_celular,''))=''
     or btrim(coalesce(p_carrera,''))=''
     or p_semestre is null
     or v_correo='' then
    return query select false,
      'REGISTRO_NUEVO: Esta cedula no esta registrada. Completa tus datos una sola vez para continuar.',
      null::text,v_session."group";
    return;
  end if;

  if exists(
    select 1 from public.student_registry sr
    where sr.correo is not null and sr.correo<>''
      and lower(sr.correo)=v_correo
      and sr.cedula<>v_cedula
  ) then
    return query select false,
      'Este correo ya pertenece a otro estudiante.',
      null::text,null::text;
    return;
  end if;

  insert into public.student_registry(
    cedula,name,celular,carrera,semestre,correo,"group",created_at,updated_at
  )
  values(
    v_cedula,btrim(p_name),btrim(p_celular),btrim(p_carrera),
    p_semestre,v_correo,v_session."group",now(),now()
  )
  returning * into v_student;

  insert into public.student_enrollments(cedula,subject,group_name,created_at)
  values(v_cedula,v_session.subject,v_session."group",now())
  on conflict(cedula,subject,group_name) do nothing;

  insert into public.attendance(
    session_ref,name,cedula,celular,carrera,semestre,correo,"group",created_at
  )
  values(
    p_session_ref,v_student.name,v_student.cedula,v_student.celular,
    v_student.carrera,v_student.semestre,v_student.correo,v_session."group",now()
  );

  return query select true,
    ('Estudiante registrado y asistencia guardada. Ubicacion validada a '
     || round(v_distancia)::text || ' m del punto autorizado.')::text,
    v_student.name,v_session."group";

exception
  when unique_violation then
    return query select false,
      'Este estudiante ya registro asistencia en esta clase.',
      coalesce(v_student.name,p_name),v_session."group";
end;
$$;

revoke all on function public.registrar_asistencia(
  bigint,text,text,text,text,integer,text,text,double precision,double precision
) from public;

grant execute on function public.registrar_asistencia(
  bigint,text,text,text,text,integer,text,text,double precision,double precision
) to anon, authenticated;

notify pgrst, 'reload schema';
