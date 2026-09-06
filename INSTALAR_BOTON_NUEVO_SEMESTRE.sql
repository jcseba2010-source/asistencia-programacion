-- ============================================================
-- INSTALAR BOTON "INICIAR NUEVO SEMESTRE"
-- Ejecutar UNA SOLA VEZ en Supabase > SQL Editor.
-- Después el borrado se hace directamente desde docente.html.
-- ============================================================

create or replace function public.admin_start_new_semester()
returns text
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  -- Evaluaciones: primero tablas dependientes.
  if to_regclass('public.exam_results') is not null then
    delete from public.exam_results;
  end if;

  if to_regclass('public.exam_attempts') is not null then
    delete from public.exam_attempts;
  end if;

  if to_regclass('public.exam_publications') is not null then
    delete from public.exam_publications;
  end if;

  if to_regclass('public.exams') is not null then
    delete from public.exams;
  end if;

  -- Asistencia y clases.
  if to_regclass('public.attendance') is not null then
    delete from public.attendance;
  end if;

  if to_regclass('public.sessions') is not null then
    delete from public.sessions;
  end if;

  -- Matrículas antes de estudiantes.
  if to_regclass('public.student_enrollments') is not null then
    delete from public.student_enrollments;
  end if;

  if to_regclass('public.student_registry') is not null then
    delete from public.student_registry;
  end if;

  -- El docente podrá crear los grupos nuevos del siguiente semestre.
  if to_regclass('public.class_groups') is not null then
    delete from public.class_groups;
  end if;

  -- Se conserva app_settings (nombre del profesor/configuración)
  -- y NO se toca auth.users.

  return 'Nuevo semestre iniciado correctamente. Se borraron estudiantes, matrículas, asistencias, clases, grupos, evaluaciones, intentos y calificaciones. Tu acceso docente y la configuración se conservaron.';
end;
$$;

revoke all on function public.admin_start_new_semester() from public;
grant execute on function public.admin_start_new_semester() to authenticated;

-- Verificación de instalación.
select
  routine_name
from information_schema.routines
where routine_schema='public'
  and routine_name='admin_start_new_semester';
