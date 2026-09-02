-- Ejecutar en Supabase > SQL Editor
create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  subject text not null check (subject in ('Programación I','Programación II')),
  "group" text not null check ("group" in ('I','V','A','B','H')),
  code text not null unique,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  active boolean not null default true
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  name text not null,
  cedula text not null,
  celular text not null,
  carrera text not null,
  semestre integer not null check (semestre between 1 and 10),
  correo text not null,
  "group" text not null check ("group" in ('I','V','A','B','H')),
  created_at timestamptz not null default now(),
  unique(session_id, cedula),
  unique(session_id, correo)
);

alter table public.sessions enable row level security;
alter table public.attendance enable row level security;

drop policy if exists "public read sessions" on public.sessions;
create policy "public read sessions" on public.sessions for select to anon using (true);

drop policy if exists "public create sessions" on public.sessions;
create policy "public create sessions" on public.sessions for insert to anon with check (true);

drop policy if exists "public update sessions" on public.sessions;
create policy "public update sessions" on public.sessions for update to anon using (true) with check (true);

drop policy if exists "public read attendance" on public.attendance;
create policy "public read attendance" on public.attendance for select to anon using (true);

drop policy if exists "public create attendance" on public.attendance;
create policy "public create attendance" on public.attendance for insert to anon with check (true);

-- IMPORTANTE:
-- Estas políticas son apropiadas para un prototipo, no para datos institucionales sensibles.
-- Antes de uso real en producción, añade autenticación del docente y políticas RLS
-- que restrinjan el panel y minimicen la exposición de datos personales.
