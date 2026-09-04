-- ============================================================
-- CARGAR CLASE EN LA PÁGINA DEL ESTUDIANTE
-- Seguro: no borra ni modifica estudiantes, asistencias o clases.
-- El código manual SOLO consulta materia/grupo.
-- ============================================================

create or replace function public.cargar_clase_estudiante(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id bigint;
  v_subject text;
  v_group text;
  v_expires timestamptz;
  v_active boolean;
begin
  select
    s.id,
    s.subject,
    coalesce(nullif(trim(s.group_name),''), nullif(trim(s."group"),'')),
    s.expires_at,
    s.active
  into
    v_id,
    v_subject,
    v_group,
    v_expires,
    v_active
  from public.sessions s
  where upper(trim(s.code)) = upper(trim(p_code))
  order by s.created_at desc nulls last, s.id desc
  limit 1;

  if v_id is null then
    return jsonb_build_object(
      'ok', false,
      'message', 'No existe una clase con ese código.'
    );
  end if;

  if coalesce(v_active,false) = false then
    return jsonb_build_object(
      'ok', false,
      'message', 'La clase está cerrada.'
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'message', 'Clase encontrada.',
    'session_ref', v_id,
    'subject', coalesce(v_subject,''),
    'group_name', coalesce(v_group,''),
    'class_expires_at', v_expires
  );
end;
$$;

revoke all on function public.cargar_clase_estudiante(text) from public;
grant execute on function public.cargar_clase_estudiante(text) to anon;
grant execute on function public.cargar_clase_estudiante(text) to authenticated;

-- Recargar el caché de esquema de PostgREST/Supabase.
notify pgrst, 'reload schema';
