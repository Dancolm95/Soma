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
| `SUPABASE_REDIRECT_URL`    | (Solo Web) URL de retorno OAuth registrada en la allow list |

`SUPABASE_REDIRECT_URL` solo aplica a Web (en Android se usa el deep link
`com.soma.expenses://auth-callback/`). Debe coincidir con la URL donde se sirve
la app, p. ej. `http://localhost:8080`, y estar registrada en la allow list de
Supabase Auth.

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

### Google OAuth en soma-dev (configuración DEV)

Configuración necesaria (una sola vez, no versionada):

1. **Google Cloud**: proyecto Soma DEV con OAuth consent screen y un
   `OAuth Client ID` de tipo *Web application*. Como *Authorized redirect URI*
   registrar el callback de Supabase:
   `https://<ref>.supabase.co/auth/v1/callback`.
2. **Supabase Auth (provider Google)**: habilitar el provider en `soma-dev`
   con el `Client ID` y el `Client Secret` de Google. El `Client Secret` queda
   solo en la configuración de Supabase (backend).
3. **Redirect allow list**: registrar en Supabase Auth las URLs de retorno:
   - Web: la URL explícita de desarrollo (p. ej. `http://localhost:8080`).
   - Android: `com.soma.expenses://auth-callback/`.

No se configuran wildcards ni redirects externos no controlados.
No se configura producción.

### Email confirmation y password recovery en soma-dev (Tarea 2.7)

- **Email confirmation**: habilitada por defecto en Supabase Auth.
  `signUp` usa `emailRedirectTo` apuntando a `_authRedirectTo` (mismo redirect
  que OAuth). El usuario recibe un correo con enlace de confirmación.
- **Password recovery**: `resetPasswordForEmail` envía correo de recuperación
  con `redirectTo` apuntando a `_authRedirectTo`. El usuario retorna a Soma
  con una sesión temporal de recovery (evento `AuthChangeEvent.passwordRecovery`).
- **Email delivery**: actualmente usa el proveedor de email por defecto de
  Supabase (GoTrue SMTP interno). Limitaciones conocidas:
  - Rate limiting por defecto de Supabase Auth (no modificado).
  - Puede tener restricciones para producción (pendiente estrategia SMTP propia).
- **CAPTCHA**: no implementado. Rate limiting aplica según configuración
  predeterminada de Supabase. Para producción podría requerirse protección
  adicional (decisión pendiente).
- **Redirect centralizado**: `SupabaseAuthService._authRedirectTo` es la
  fuente única de redirects para OAuth, email confirmation y password recovery.

### Diferencias Web / Android

| Aspecto         | Web                                        | Android                                        |
|-----------------|--------------------------------------------|------------------------------------------------|
| `redirectTo`    | `SUPABASE_REDIRECT_URL` (allow list)       | `com.soma.expenses://auth-callback/` (deep link) |
| Retorno         | Misma pestaña (`_self`) → URL fragment      | Navegador externo → deep link → foreground      |
| Config extra    | Ninguna                                    | intent-filter en `AndroidManifest.xml`          |
| Flujos          | OAuth, email confirmation, password recovery | OAuth, email confirmation, password recovery   |

## Producción

- Backups automáticos antes de producción.
- Procedimiento de restauración requerido antes del lanzamiento.

## Observabilidad

- Sin registrar comprobantes ni contenido financiero sensible innecesario.

## Despliegue y rollback

- Deberán quedar definidos antes de producción.
