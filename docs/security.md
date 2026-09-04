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
