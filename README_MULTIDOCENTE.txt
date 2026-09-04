SISTEMA DE ASISTENCIA MULTIDOCENTE
Universidad de Pamplona

CAMBIO PRINCIPAL
- Cada profesor entra con su propio correo y contraseña de Supabase Authentication.
- Cada profesor ve solamente sus clases, estudiantes matriculados y asistencias.
- Un mismo estudiante puede estar con varios profesores, asignaturas o grupos.
- Los datos personales del estudiante se registran una sola vez por cédula.
- Cada profesor puede limpiar solo sus propios datos.
- El primer profesor que entre después de ejecutar la migración queda como Administrador General.
- El Administrador General también puede limpiar toda la plataforma.

IMPORTANTE: NO BORRAR LOS DATOS EXISTENTES
1. Sube los archivos del ZIP a GitHub Pages.
2. En Supabase > SQL Editor ejecuta SOLO: MIGRACION_MULTIDOCENTE.sql
3. Después inicia sesión PRIMERO con la cuenta actual de Julio César.
   Esa primera cuenta quedará como Administrador General y reclamará los datos históricos.
4. Luego crea las demás cuentas de profesores en:
   Supabase > Authentication > Users.
5. Cada profesor entra por docente.html con su propio correo y contraseña.

NO es necesario borrar las tablas actuales.
La migración conserva sesiones, estudiantes y asistencias existentes.
