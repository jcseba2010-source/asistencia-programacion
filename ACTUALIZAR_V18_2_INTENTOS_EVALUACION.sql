-- V18.2 - MOSTRAR Y ELIMINAR INTENTOS DE EVALUACIÓN
-- Ejecutar UNA sola vez en Supabase > SQL Editor.
-- NO borra estudiantes, matrículas ni asistencias.

create or replace function public.admin_list_exam_attempts()
returns table(
  attempt_id bigint,
  exam_id bigint,
  title text,
  subject text,
  cedula text,
  student_name text,
  group_name text,
  active boolean,
  security_violations integer,
  started_at timestamptz,
  last_seen_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  return query
  select
    ea.id as attempt_id,
    ea.exam_id,
    e.title,
    e.subject,
    ea.cedula,
    coalesce(sr.name,'') as student_name,
    ea.group_name,
    ea.active,
    ea.security_violations,
    ea.started_at,
    ea.last_seen_at
  from public.exam_attempts ea
  join public.exams e on e.id = ea.exam_id
  left join public.student_registry sr on sr.cedula = ea.cedula
  order by ea.started_at desc;
end;
$$;

revoke all on function public.admin_list_exam_attempts() from public;
grant execute on function public.admin_list_exam_attempts() to authenticated;


create or replace function public.admin_delete_exam_attempt_by_id(p_attempt_id bigint)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_cedula text;
  v_exam_id bigint;
  v_group text;
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  select coalesce(sr.name,''), ea.cedula, ea.exam_id, ea.group_name
    into v_name, v_cedula, v_exam_id, v_group
  from public.exam_attempts ea
  left join public.student_registry sr on sr.cedula = ea.cedula
  where ea.id = p_attempt_id;

  if not found then
    raise exception 'No se encontró el intento de evaluación';
  end if;

  -- Si por alguna razón existe una calificación asociada al mismo examen,
  -- cédula y grupo, también la limpia para permitir una nueva presentación.
  delete from public.exam_results
  where exam_id = v_exam_id
    and cedula = v_cedula
    and group_name = v_group;

  delete from public.exam_attempts
  where id = p_attempt_id;

  return 'Intento eliminado: ' ||
         coalesce(nullif(v_name,''),'Estudiante') ||
         ' · ' || coalesce(v_cedula,'');
end;
$$;

revoke all on function public.admin_delete_exam_attempt_by_id(bigint) from public;
grant execute on function public.admin_delete_exam_attempt_by_id(bigint) to authenticated;
