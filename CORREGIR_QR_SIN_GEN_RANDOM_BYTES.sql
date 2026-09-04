-- ============================================================
-- CORRECCION QR DINAMICO SIN gen_random_bytes()
-- Ejecutar en Supabase > SQL Editor > Run.
-- NO borra estudiantes, clases ni asistencias.
-- ============================================================

-- Reemplaza la función de generación/rotación del token QR por una versión
-- compatible que no requiere pgcrypto/gen_random_bytes().

create table if not exists public.session_qr_tokens (
  session_ref bigint primary key references public.sessions(id) on delete cascade,
  token text not null,
  valid_until timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table public.session_qr_tokens enable row level security;

create or replace function public.rotate_session_qr(p_session_ref bigint)
returns table(token text, valid_until timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
  v_until timestamptz;
begin
  if auth.uid() is null then
    raise exception 'Acceso no autorizado';
  end if;

  if not exists(
    select 1 from public.sessions
    where id=p_session_ref and active=true
  ) then
    raise exception 'La clase no existe o no está activa';
  end if;

  v_token := md5(
    random()::text ||
    clock_timestamp()::text ||
    p_session_ref::text ||
    coalesce(auth.uid()::text,'')
  );
  v_until := now() + interval '30 seconds';

  insert into public.session_qr_tokens(session_ref,token,valid_until,updated_at)
  values(p_session_ref,v_token,v_until,now())
  on conflict(session_ref) do update
    set token=excluded.token,
        valid_until=excluded.valid_until,
        updated_at=now();

  return query select v_token,v_until;
end;
$$;

revoke all on function public.rotate_session_qr(bigint) from public;
grant execute on function public.rotate_session_qr(bigint) to authenticated;

create or replace function public.validate_session_qr(
  p_session_ref bigint,
  p_token text
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists(
    select 1
    from public.session_qr_tokens q
    join public.sessions s on s.id=q.session_ref
    where q.session_ref=p_session_ref
      and q.token=btrim(coalesce(p_token,''))
      and q.valid_until>now()
      and s.active=true
  );
$$;

revoke all on function public.validate_session_qr(bigint,text) from public;
grant execute on function public.validate_session_qr(bigint,text) to anon, authenticated;
