-- ============================================================
-- V7 - CORRECCION DEFINITIVA DE GRUPOS POR SESION
-- Seguro para la base actual: NO borra estudiantes ni asistencias.
-- Ejecutar una sola vez en Supabase > SQL Editor.
-- ============================================================

update public.sessions
set group_name = "group"
where group_name is null
  and "group" is not null;

update public.sessions
set "group" = group_name
where "group" is null
  and group_name is not null;

create or replace function public.sync_session_group_fields()
returns trigger
language plpgsql
set search_path=public
as $$
begin
  if new."group" is null and new.group_name is not null then
    new."group" := new.group_name;
  end if;

  if new."group" is not null then
    new.group_name := new."group";
  end if;

  return new;
end;
$$;

drop trigger if exists trg_sync_session_group_fields on public.sessions;

create trigger trg_sync_session_group_fields
before insert or update of "group", group_name
on public.sessions
for each row
execute function public.sync_session_group_fields();

notify pgrst, 'reload schema';

select
  id,
  subject,
  "group",
  group_name,
  code,
  created_at
from public.sessions
order by id desc
limit 20;
