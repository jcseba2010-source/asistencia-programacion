-- ============================================================
-- CLAVE SEGURA PARA "BORRAR TODO"
-- Ejecutar en Supabase > SQL Editor.
-- NO borra datos al instalar esta actualización.
-- Clave inicial: ADMIN2026
-- Cámbiala desde el panel docente después de instalar.
-- ============================================================

alter table public.app_settings
  add column if not exists delete_key_hash text;

-- Instala clave inicial SOLO si todavía no existe una.
update public.app_settings
set delete_key_hash = md5('ADMIN2026')
where id=1 and delete_key_hash is null;

create or replace function public.admin_change_delete_key(
  p_current_key text,
  p_new_key text
)
returns table(ok boolean,message text)
language plpgsql
security definer
set search_path=public
as $$
declare v_hash text;
begin
  if auth.uid() is null then
    return query select false,'Acceso no autorizado.'::text; return;
  end if;

  select a.delete_key_hash into v_hash
  from public.app_settings a where a.id=1;

  if v_hash is null or v_hash <> md5(coalesce(p_current_key,'')) then
    return query select false,'La clave actual es incorrecta.'::text; return;
  end if;

  if length(coalesce(p_new_key,'')) < 8 then
    return query select false,'La nueva clave debe tener minimo 8 caracteres.'::text; return;
  end if;

  update public.app_settings
  set delete_key_hash=md5(p_new_key)
  where id=1;

  return query select true,'Clave de borrado cambiada correctamente.'::text;
end;
$$;

revoke all on function public.admin_change_delete_key(text,text) from public;
grant execute on function public.admin_change_delete_key(text,text) to authenticated;

-- Función segura: exige sesión docente + clave adicional.
create or replace function public.admin_reset_system_secure(p_delete_key text)
returns table(ok boolean,message text)
language plpgsql
security definer
set search_path=public
as $$
declare v_hash text;
begin
  if auth.uid() is null then
    return query select false,'Acceso no autorizado.'::text; return;
  end if;

  select a.delete_key_hash into v_hash
  from public.app_settings a where a.id=1;

  if v_hash is null or v_hash <> md5(coalesce(p_delete_key,'')) then
    return query select false,'Clave de seguridad incorrecta.'::text; return;
  end if;

  -- Orden seguro por dependencias. No elimina el usuario Auth del docente.
  delete from public.attendance_scan_permits;
  delete from public.session_qr_tokens;
  delete from public.attendance;
  delete from public.student_enrollments;
  delete from public.sessions;
  delete from public.student_registry;
  delete from public.class_groups;

  return query select true,
    'Sistema reiniciado correctamente. Se borraron clases, asistencias, matriculas, estudiantes y grupos. La cuenta del docente y la configuracion permanecen.'::text;
end;
$$;

revoke all on function public.admin_reset_system_secure(text) from public;
grant execute on function public.admin_reset_system_secure(text) to authenticated;

-- Bloquear la antigua función de borrado total para que no permita saltarse la clave.
revoke all on function public.admin_reset_system() from anon, authenticated;

notify pgrst, 'reload schema';
