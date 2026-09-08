-- BOTÓN "ELIMINAR INTENTO" DE EVALUACIÓN
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- IMPORTANTE: NO borra al estudiante ni su matrícula/asistencia.
-- Solo elimina el resultado/intento de examen seleccionado para permitir una nueva prueba.

create or replace function public.admin_delete_exam_attempt(p_result_id bigint)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_cedula text;
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  select student_name, cedula
    into v_name, v_cedula
  from public.exam_results
  where id = p_result_id;

  if not found then
    raise exception 'No se encontró el intento de evaluación';
  end if;

  delete from public.exam_results
  where id = p_result_id;

  return 'Intento eliminado: ' || coalesce(v_name,'Estudiante') || ' · ' || coalesce(v_cedula,'');
end;
$$;

revoke all on function public.admin_delete_exam_attempt(bigint) from public;
grant execute on function public.admin_delete_exam_attempt(bigint) to authenticated;
