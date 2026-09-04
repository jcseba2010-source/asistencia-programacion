-- Permite que el panel docente autenticado lea estudiantes, asistencias y sesiones.
-- No borra ni modifica registros existentes.

alter table public.student_registry enable row level security;
alter table public.attendance enable row level security;
alter table public.sessions enable row level security;

drop policy if exists "docente lee estudiantes" on public.student_registry;
create policy "docente lee estudiantes"
on public.student_registry
for select
to authenticated
using (true);

drop policy if exists "docente lee asistencias" on public.attendance;
create policy "docente lee asistencias"
on public.attendance
for select
to authenticated
using (true);

drop policy if exists "docente lee sesiones" on public.sessions;
create policy "docente lee sesiones"
on public.sessions
for select
to authenticated
using (true);

grant select on public.student_registry to authenticated;
grant select on public.attendance to authenticated;
grant select on public.sessions to authenticated;
