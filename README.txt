SISTEMA DE ASISTENCIA - VERSION COMPATIBLE BIGINT

Esta versión está adaptada a la estructura detectada en tu Supabase:
- public.sessions.id = BIGINT
- public.attendance.session_id existente = UUID

Para no borrar ni convertir registros antiguos, se conserva attendance.session_id y se crea:
- attendance.session_ref BIGINT

La página de estudiantes registra las asistencias nuevas usando session_ref.
El panel docente relaciona las asistencias con las clases usando session_ref.

PASOS:
1. En Supabase > SQL Editor, pega y ejecuta TODO el contenido de supabase.sql.
2. Debe finalizar sin el error UUID/BIGINT de attendance_session_id_fkey.
3. Sube index.html, docente.html y config.js a tu repositorio de GitHub Pages.
4. Prueba creando una clase desde el panel docente.
5. Desde el celular abre la página y registra una asistencia.

IMPORTANTE:
- No borres la tabla attendance.
- No borres la tabla sessions.
- No necesitas convertir attendance.session_id.
- Los registros históricos quedan conservados.

REGLA DE GRUPO UNICO
--------------------
Esta version crea student_registry y aplica la regla:
UNA CEDULA = UN ESTUDIANTE = UN SOLO GRUPO.
Si una cedula intenta registrarse en otro grupo, el sistema la rechaza.
Primero ejecute supabase.sql completo y despues publique los archivos en GitHub Pages.


MEJORA PANEL DOCENTE
- Estudiantes registrados: una sola fila por cédula desde student_registry.
- Historial de asistencias: una fila por asistencia/clase.
- Exportación CSV separada para estudiantes y asistencias.
- No permite iniciar una nueva clase si ya existe otra clase activa.

IMPORTANTE: vuelve a ejecutar supabase.sql para habilitar la lectura docente de student_registry.
