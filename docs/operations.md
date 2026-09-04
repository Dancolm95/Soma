# Operaciones — Soma

> Documenta solo lo decidido hasta ahora.
> No inventar pipelines, proveedores adicionales ni herramientas de
> observabilidad no aprobadas.

## Desarrollo local

- Windows/WSL
- macOS

## Secretos

- Secretos fuera del repositorio.
- Nunca commitear secretos.
- Flutter solo recibe la publishable (anon) key de Supabase.
- service_role, JWT signing secret y contraseña de base de datos son
  exclusivamente backend y nunca llegan al cliente.

## Configuración Supabase

La aplicación necesita dos valores en tiempo de compilación, proporcionados
mediante `--dart-define`. No se almacenan en el repositorio.

| Variable                   | Descripción                                      |
|----------------------------|--------------------------------------------------|
| `SUPABASE_URL`             | URL del proyecto Supabase (https://xxx.supabase.co) |
| `SUPABASE_PUBLISHABLE_KEY` | Publishable (anon) key del proyecto              |

### WSL / Linux

```bash
flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key> \
  --dart-define=APP_ENV=development
```

Para evitar exponer valores en el historial de la terminal, usa un
archivo local (no versionado):

```bash
# .supabase.local  (añadido a .gitignore via *.local)
export SUPABASE_URL="https://<ref>.supabase.co"
export SUPABASE_PUBLISHABLE_KEY="<publishable-key>"
```

```bash
source .supabase.local
flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

### macOS

Mismo procedimiento. Reemplazar `-d web-server` por `-d chrome`
o el dispositivo/simulador correspondiente.

```bash
source .supabase.local
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=$SUPABASE_PUBLISHABLE_KEY
```

## Supabase CLI y stack local

La CLI de Supabase (v2.116.0) está inicializada en el repositorio
(`supabase/config.toml`). El stack local completo requiere Docker.

- **WSL**: Docker 25.0.3 disponible y verificado. `supabase start` ejecutado
  correctamente (Tarea 2.1).
- **macOS**: instalar Docker Desktop y ejecutar `supabase start`
  desde la raíz del repositorio.

El stack local expone:

| Servicio      | URL por defecto              |
|---------------|------------------------------|
| API / Auth    | http://127.0.0.1:54321       |
| Studio        | http://127.0.0.1:54323       |
| PostgreSQL    | postgresql://postgres:postgres@127.0.0.1:54322/postgres |

Las credenciales del stack local (publishable key y URL) se obtienen
de la salida de `supabase start` y se proporcionan via `--dart-define`.
No se commitean.

Para detener el stack: `supabase stop`.

## Entornos

- Separación futura de entornos (a definir antes de producción).
- Región aprobada para producción: São Paulo / sa-east-1.

### soma-dev (desarrollo)

- Proyecto Supabase remoto exclusivo de desarrollo.
- Región: São Paulo / sa-east-1.
- El esquema remoto se gobierna exclusivamente mediante migraciones
  versionadas del repositorio (`supabase db push`).
- Prohibido modificar tablas/schema manualmente desde Dashboard o SQL Editor.
- Prohibido `db reset --linked`, `migration repair`, `db pull` u operaciones
  destructivas sin aprobación previa.
- Flujo de despliegue:
  1. `supabase link --project-ref <PROJECT_REF>` (una sola vez).
  2. `supabase migration list` (inspeccionar pendientes).
  3. `supabase db push --dry-run` (validar).
  4. `supabase db push`.
  5. `supabase migration list` (confirmar sincronización).

## Producción

- Backups automáticos antes de producción.
- Procedimiento de restauración requerido antes del lanzamiento.

## Observabilidad

- Sin registrar comprobantes ni contenido financiero sensible innecesario.

## Despliegue y rollback

- Deberán quedar definidos antes de producción.
