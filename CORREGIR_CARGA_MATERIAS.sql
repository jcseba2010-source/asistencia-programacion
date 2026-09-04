-- ============================================================
-- CORRECCIÓN: CARGAR MATERIA/GRUPO CON CÓDIGO MANUAL
-- No borra datos.
-- El código permite consultar la clase, pero NO registrar asistencia.
-- ============================================================

create or replace function public.consultar_clase_por_codigo(p_code text)
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
  s record;
begin
  select
    id,
    sessions.subject,
    coalesce(nullif(sessions.group_name,''), nullif(sessions."group",'')) as grp,
    sessions.expires_at,
    sessions.active
  into s
  from public.sessions
  where upper(trim(code)) = upper(trim(p_code))
  order by created_at desc nulls last, id desc
  limit 1;

  if not found then
    return query
    select false, 'No existe una clase con ese código.', null::bigint,
           null::text, null::text, null::timestamptz;
    return;
  end if;

  if coalesce(s.active,false) = false then
    return query
    select false, 'La clase está cerrada.', null::bigint,
           null::text, null::text, null::timestamptz;
    return;
  end if;

  return query
  select true,
         'Clase encontrada.',
         s.id::bigint,
         s.subject::text,
         s.grp::text,
         s.expires_at::timestamptz;
end;
$$;

revoke all on function public.consultar_clase_por_codigo(text) from public;
grant execute on function public.consultar_clase_por_codigo(text) to anon;
grant execute on function public.consultar_clase_por_codigo(text) to authenticated;
