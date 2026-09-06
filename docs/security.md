# Seguridad — Soma

> Controles de seguridad aprobados. Fuente de verdad de seguridad.

## BLOQUEANTES

- aislamiento entre usuarios;
- RLS;
- autorización backend;
- `user_id` derivado de sesión/contexto;
- nunca confiar en `user_id` enviado por Flutter;
- claves Gemini solo backend;
- backups automáticos antes de producción;
- OpenCode no puede desactivar/cambiar controles de seguridad unilateralmente.

## IMPORTANTES

- comprobantes efímeros;
- evitar contenido sensible en logs;
- validación real de archivos;
- límites de tamaño/páginas;
- salida IA considerada no confiable;
- validación semántica;
- confirmación humana;
- rate limiting;
- protección frente a abuso/coste;
- persistencia de información FX histórica.

## Principio

Todo archivo/documento externo es entrada no confiable.

## Frontera OAuth — Google (Tarea 2.6)

- El flujo OAuth usa exclusivamente Supabase Auth + `signInWithOAuth`. No se
  integra el SDK nativo de Google ni se manejan tokens manualmente.
- `Google Client Secret` vive únicamente en la configuración del provider de
  Supabase Auth (backend). Nunca en Flutter ni en Git.
- `service_role` nunca llega a Flutter.

### Redirects y deep link autorizados

- Android: `com.soma.expenses://auth-callback/` (deep link declarado en el
  manifest, sin App Links HTTPS todavía).
- Web: una URL explícita y controlada de desarrollo, registrada en la allow
  list de Supabase Auth. No se usan wildcards ni redirects externos no
  controlados.
- Todo `redirectTo` debe estar registrado en la allow list. `redirectTo` nunca
  se acepta desde la entrada del usuario.
- Centralizado en `SupabaseAuthService._authRedirectTo`. Reutilizado por OAuth,
  email confirmation y password recovery.

### Ubicación de secretos

- `Google Client Secret`: configuración del provider en Supabase (backend).
- Publishable (anon) key: única credencial que recibe Flutter (build-time).
- `service_role`, JWT signing secret, contraseña de BD: nunca en el cliente.
- Sin secretos en el repositorio.

## Password recovery (Tarea 2.7)

### Enumeración de cuentas

- `resetPasswordForEmail` devuelve para el usuario una respuesta neutral:
  "Si existe una cuenta asociada, recibirás instrucciones por correo."
- No revela si el email existe o no.
- El resultado aceptado es neutral por diseño (Supabase devuelve el mismo
  resultado exista o no la cuenta).
- Un fallo operativo (red, rate limit, configuración) se distingue internamente
  del resultado neutral y se muestra un mensaje seguro genérico; nunca se
  convierte silenciosamente en éxito ni se muestra `AuthException` al usuario.

### Estado de recuperación

- `AuthController` distingue estados de sesión:
  - `authenticated`: sesión normal.
  - `passwordRecovery`: sesión temporal de recuperación.
  - `unauthenticated`: sin sesión.
- La detección de `passwordRecovery` se basa exclusivamente en el evento
  oficial `AuthChangeEvent.passwordRecovery` emitido por Supabase Auth. No se
  infiere a partir de metadata de sesión (`userMetadata` / `iss`).
- Durante `passwordRecovery`, el usuario NO accede a `SignedInScreen`.
  Se muestra `ResetPasswordScreen` exclusivamente.
- `tokenRefreshed` y `userUpdated` no abandonan el estado de recovery; solo
  `signedOut` o `signedIn` cambian explícitamente el estado.

### Stream de Auth

- La suscripción a `onAuthStateChange` (frontera `AuthService.authStateChanges`)
  proporciona `onError` en `AuthController`, de modo que un error de red del
  stream no provoca una excepción no manejada ni una transición insegura.
- En el log solo se registra el tipo de error, nunca email, sesión, tokens ni
  credenciales.

### Actualización de contraseña

- Solo posible durante una sesión de recovery.
- La contraseña nunca se almacena ni loguea en el cliente.
- Validación de longitud mínima en cliente (primero pase), backend es autoritativo.
- Tras actualización exitosa, se cierra sesión y el usuario debe iniciar sesión
  con la nueva contraseña.
- Tokens de recovery nunca se manipulan manualmente. Supabase Auth los gestiona
  íntegramente.

### Redirects de email

- Email de confirmación: usa `emailRedirectTo` en `signUp`.
- Email de password recovery: usa `redirectTo` en `resetPasswordForEmail`.
- Ambos apuntan a `_authRedirectTo` (mismo redirect que OAuth).
- Supabase Auth valida que el redirect esté en la allow list configurada.

## Frontera de autorización — perfiles (Tarea 2.3)

Primera frontera real de autorización implementada.

- Tabla `public.profiles` en relación 1:1 con `auth.users`
  (`profiles.id` → `auth.users.id` con `on delete cascade`).
- RLS habilitado. Identidad determinada por `auth.uid()`.
- Creación del perfil: trigger `after insert on auth.users` (SECURITY
  DEFINER) que deriva el `id` de `auth.users`; el cliente nunca proporciona
  el propietario.
- Políticas mínimas (solo `authenticated`):
  - SELECT con `auth.uid() = id`;
  - UPDATE con `auth.uid() = id` (`using` y `with check`).
- Sin políticas de INSERT ni DELETE para el cliente.
- Privilegios de mínimo privilegio:
  - `anon`: sin acceso a `profiles`;
  - `authenticated`: `SELECT` y `UPDATE` únicamente sobre `base_currency`.
- `base_currency` restringida por CHECK a PEN/USD/EUR.

Garantías verificadas (pgTAP sobre autorización real):

- A lee su perfil, B lee el suyo.
- A no lee ni modifica a B; B no lee ni modifica a A.
- El cliente no puede crear un perfil adjudicándoselo a otro usuario.
- El cliente no puede cambiar el `id` de su propio perfil.
- El acceso anónimo no obtiene perfiles.
- Moneda fuera de PEN/USD/EUR es rechazada por la base de datos.
