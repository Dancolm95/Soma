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
- persistencia financiera futura con representación decimal exacta, no
  floating point;
- importes financieros con validación backend/database;
- ningún LLM convierte moneda de forma autoritativa;
- ninguna entrada externa cambia la semántica PEN del gasto.

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
  - `authenticated`: `SELECT` únicamente (Tarea 3.1 retiró `base_currency`
    y con ella el grant `UPDATE`, al no quedar columnas actualizables por
    el cliente).
- Sin columna `base_currency` desde la migración PEN-only (Tarea 3.1).

Garantías verificadas (pgTAP sobre autorización real):

- A lee su perfil, B lee el suyo.
- A no lee ni modifica a B; B no lee ni modifica a A.
- El cliente no puede crear un perfil adjudicándoselo a otro usuario.
- El cliente no puede cambiar el `id` de su propio perfil.
- El acceso anónimo no obtiene perfiles.
- `base_currency` ya no existe en `profiles` (PEN-only).

## Frontera de autorización — categorías (Tarea 3.2)

- Tabla `public.categories` con ownership por `user_id`: `NULL` = sistema,
  `<usuario>` = privada (`user_id` → `auth.users.id` con `on delete cascade`).
- RLS habilitado. Políticas separadas por operación (solo `authenticated`):
  - SELECT: `user_id IS NULL OR user_id = auth.uid()`;
  - INSERT: `WITH CHECK (user_id = auth.uid())` (el `DEFAULT auth.uid()`
    no basta: el cliente puede enviar `user_id` explícito);
  - UPDATE: `USING`/`WITH CHECK (user_id = auth.uid())`;
  - DELETE: `USING (user_id = auth.uid())`.
- Privilegios de mínimo privilegio:
  - `anon`: sin acceso;
  - `authenticated`: `SELECT`, `INSERT`, `DELETE` y `UPDATE(name)`
    únicamente — `user_id`/`created_at`/`updated_at` nunca editables.
- Nombre validado en DB (`btrim` 1–60) y unicidad lógica por ámbito
  mediante índices de expresión (`lower(btrim(name))`, parciales por
  `user_id IS NULL / IS NOT NULL`); sin extensiones nuevas.
- Seed del sistema (8 filas `user_id IS NULL`) controlado por migración.

Garantías verificadas (pgTAP sobre autorización real):

- A lee sistema + propias; B igual; ni A ni B leen privadas ajenas.
- A crea/renombra/elimina solo propias; no crea para B ni con `NULL`;
  no transfiere (`→ B`, `→ NULL`) ni edita `user_id`.
- Authenticated no modifica ni elimina categorías del sistema.
- Anon sin acceso (SELECT/INSERT/UPDATE/DELETE denegados).

## Frontera de autorización — gastos (Tarea 3.3)

- Tabla `public.expenses` con ownership estricto por `user_id`
  (`NOT NULL DEFAULT auth.uid()` → `auth.users` con `on delete cascade`).
- RLS habilitado. Políticas separadas por operación (solo `authenticated`):
  - SELECT: `user_id = auth.uid()`;
  - INSERT: `WITH CHECK (user_id = auth.uid())`;
  - UPDATE: `USING`/`WITH CHECK (user_id = auth.uid())`;
  - DELETE: `USING (user_id = auth.uid())`.
- Invariante de categoría por triggers `SECURITY INVOKER`
  (alternativa B): `expenses_check_category_owner` valida cada escritura
  de gasto (global o privada propia; ajena/inexistente → `23503`);
  corre como invocante bajo RLS verificado (global/propia OK, ajena
  rechazada) con predicado explícito que también rige a roles que eluden
  RLS. `categories_guard_expense_owner` bloquea (`23503`) retargets
  (`A→B`, global→privada con gastos ajenos) y deja pasar renames.
  Serialización por categoría con advisory xact lock (demostrada con
  carrera viva: inserción concurrente vs retarget → espera + rechazo,
  0 pares inválidos).   `EXECUTE` mínimo: las dos funciones validadoras no otorgan `EXECUTE`
  a nadie (`PUBLIC`/`anon`/`authenticated`/`service_role` revocados;
  solo el owner ejecuta vía trigger, que no exige el privilegio).
  Flutter solo envía `category_id`; la sesión determina `user_id`.
- `category_id NOT NULL` → `categories(id)` con `on delete restrict`:
  eliminar una categoría en uso falla (`23503`); el gasto permanece.
- Privilegios de mínimo privilegio:
  - `anon`: sin acceso;
  - `authenticated`: `SELECT`, `DELETE`, `INSERT(amount, expense_date,
    merchant, category_id)` y `UPDATE(amount, expense_date, merchant,
    category_id)` únicamente — `user_id`/`id`/`created_at`/`updated_at`
    nunca editables por cliente.
- Financiero: `amount numeric(12,2) CHECK (> 0)`; `merchant` 1–120 tras
  `btrim`; `expense_date date` (fecha económica, no instante).
- `updated_at` controlado por trigger (`expenses_touch_updated_at`);
  sin grant de escritura para el cliente.

Garantías verificadas (pgTAP sobre autorización real):

- A crea/lee/edita/elimina solo propios (global + privada A);
  B simétrico; ni A ni B leen/modifican/eliminan gastos ajenos.
- Transferencia `A → B` rechazada; `UPDATE(user_id/id/created_at/
  updated_at)` denegado (`42501`); `INSERT` con `user_id` explícito
  denegado (`42501`).
- `A + privada B` y `B + privada A` rechazados (`23514`).
- Categoría en uso no eliminable; al eliminar usuario, sus gastos y
  categorías privadas desaparecen, globales permanecen.
- Anon sin acceso (SELECT/INSERT/UPDATE/DELETE denegados).

## Modelo financiero PEN-only (Tarea 3.1, ADR-005)

- Soma MVP persiste importes exclusivamente bajo semántica PEN.
- Ningún LLM puede convertir moneda de forma autoritativa.
- Ninguna entrada externa puede cambiar la semántica PEN del gasto.
- La persistencia financiera futura debe usar representación decimal
  exacta, no floating point.
- Los importes financieros requieren validación backend/database.
- `user_id` nunca será confiado desde entrada arbitraria del cliente.
