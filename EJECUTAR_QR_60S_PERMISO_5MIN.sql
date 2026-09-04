-- ============================================================
-- QR 60 SEGUNDOS + PERMISO DE 5 MINUTOS + UBICACION
-- NO borra estudiantes, asistencias, materias ni grupos.
-- Ejecutar en Supabase > SQL Editor.
-- ============================================================

create table if not exists public.attendance_scan_permits (
  permit_token text primary key,
  session_ref bigint not null references public.sessions(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

alter table public.attendance_scan_permits enable row level security;
revoke all on table public.attendance_scan_permits from anon, authenticated;

-- Intercambia un QR vigente por un permiso temporal de 5 minutos.
create or replace function public.crear_permiso_asistencia(
  p_code text,
  p_qr_token text
)
returns table(
  ok boolean,
  message text,
  permit_token text,
  permit_expires_at timestamptz
)
language plpgsql
security definer
set search_path=public
as $$
declare
  v_session_ref bigint;
  v_permit text;
  v_exp timestamptz;
begin
  select s.id
    into v_session_ref
  from public.sessions s
  join public.session_qr_tokens q on q.session_ref=s.id
  where upper(btrim(s.code))=upper(btrim(p_code))
    and s.active=true
    and q.token=btrim(coalesce(p_qr_token,''))
    and q.expires_at>now()
  order by s.created_at desc
  limit 1;

  if v_session_ref is null then
    return query select false,'El QR no es valido o ya vencio.'::text,null::text,null::timestamptz;
    return;
  end if;

  v_permit := md5(
    random()::text ||
    clock_timestamp()::text ||
    v_session_ref::text ||
    coalesce(p_qr_token,'')
  );
  v_exp := now() + interval '5 minutes';

  insert into public.attendance_scan_permits(permit_token,session_ref,created_at,expires_at)
  values(v_permit,v_session_ref,now(),v_exp);

  -- Limpieza ligera de permisos viejos.
  delete from public.attendance_scan_permits p
  where p.expires_at < now() - interval '1 day';

  return query select true,
    'QR validado. Tienes 5 minutos para completar el registro.'::text,
    v_permit,
    v_exp;
end;
$$;

revoke all on function public.crear_permiso_asistencia(text,text) from public;
grant execute on function public.crear_permiso_asistencia(text,text) to anon, authenticated;

-- Quitar la versión de asistencia anterior basada directamente en el QR.
drop function if exists public.registrar_asistencia(
  bigint,text,text,text,text,integer,text,text,double precision,double precision
);

-- Registrar asistencia usando el permiso temporal obtenido al escanear el QR.
create or replace function public.registrar_asistencia(
  p_session_ref bigint,
  p_name text,
  p_cedula text,
  p_celular text,
  p_carrera text,
  p_semestre integer,
  p_correo text,
  p_permit_token text,
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

  if not exists(
    select 1
    from public.attendance_scan_permits p
    where p.permit_token=btrim(coalesce(p_permit_token,''))
      and p.session_ref=p_session_ref
      and p.expires_at>now()
  ) then
    return query select false,
      'El permiso de 5 minutos vencio. Escanea nuevamente el QR actual.',
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

  v_cos :=
      cos(radians(v_aula_lat)) * cos(radians(p_lat))
      * cos(radians(p_lng-v_aula_lng))
      + sin(radians(v_aula_lat)) * sin(radians(p_lat));

  v_distancia := 6371000.0 * acos(greatest(-1.0,least(1.0,v_cos)));

  if v_distancia > coalesce(v_radio,100) then
    return query select false,
      ('Estas fuera del area autorizada. Distancia aproximada: '
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

    -- El permiso se consume al registrar correctamente.
    delete from public.attendance_scan_permits p
    where p.permit_token=btrim(coalesce(p_permit_token,''));

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
      'REGISTRO_NUEVO: Esta cedula no esta registrada. Completa tus datos para continuar.',
      null::text,v_session."group";
    return;
  end if;

  if exists(
    select 1 from public.student_registry sr
    where sr.correo is not null and sr.correo<>''
      and lower(sr.correo)=v_correo
      and sr.cedula<>v_cedula
  ) then
    return query select false,'Este correo ya pertenece a otro estudiante.',null::text,null::text;
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

  delete from public.attendance_scan_permits p
  where p.permit_token=btrim(coalesce(p_permit_token,''));

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
