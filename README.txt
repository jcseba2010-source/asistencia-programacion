# Sistema de Asistencia — Programación I y II

## Archivos
- `index.html`: página del estudiante.
- `docente.html`: panel del docente.
- `config.js`: configuración de Supabase.
- `supabase.sql`: tablas, restricciones y políticas iniciales.
- `README.txt`: instrucciones.

## Grupos
- Programación I: I, V, A y B.
- Programación II: H.

## Publicar en GitHub Pages
Sube todos los archivos a la raíz del repositorio y activa Settings > Pages > Deploy from a branch > main > /(root).

## Activar base de datos compartida
1. Crea un proyecto en Supabase.
2. Abre SQL Editor y ejecuta `supabase.sql`.
3. En Project Settings > API copia la URL del proyecto y la clave pública `anon`.
4. Abre `config.js` y completa `supabaseUrl` y `supabaseAnonKey`.
5. Vuelve a subir `config.js` a GitHub Pages.

No uses nunca la `service_role key` en `config.js`.

## Funcionamiento
Docente -> Iniciar nueva clase -> se genera código dinámico + QR.
Estudiante -> escanea QR -> diligencia nombre, cédula, celular, carrera, semestre, correo y grupo -> registra asistencia.
El sistema evita dos registros de la misma cédula o correo dentro de una misma sesión.
El panel docente consulta los registros compartidos y permite filtrar/exportar CSV.

## Nota de seguridad
La versión incluida deja políticas públicas para facilitar la puesta en marcha del prototipo. Para uso institucional con datos personales, se recomienda añadir autenticación del docente y políticas RLS más restrictivas antes de producción.
