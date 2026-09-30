# Plan de implementación — Soma

> Estado del plan aprobado.
> Estados: `PENDING`, `IN_PROGRESS`, `APPROVED`, `BLOCKED`.

## Fases

- Fase 1 — Fundación y gobierno
- Fase 2 — Supabase, identidad y aislamiento
- Fase 3 — Núcleo financiero
- Fase 4 — Métricas
- Fase 5 — IA texto
- Fase 6 — Comprobantes/cámara
- Fase 7 — Hardening y producción

## Estado actual

- Fase 1 — COMPLETED
- Tarea 1.1 — APPROVED
- Tarea 1.2 — APPROVED
- Tarea 1.3 — APPROVED
- Fase 2 — COMPLETED
- Tarea 2.1 — APPROVED
- Tarea 2.2 — APPROVED
- Tarea 2.3 — APPROVED
- Tarea 2.4 — APPROVED
- Tarea 2.5 — APPROVED
- Tarea 2.6 — APPROVED
- Tarea 2.7 — APPROVED
- Fase 3 — COMPLETED
- Tarea 3.1 — APPROVED
- Tarea 3.2 — APPROVED + DEPLOYED DEV
- Tarea 3.3 — APPROVED + DEPLOYED DEV
- Tarea 3.4 — APPROVED WITH OBSERVATIONS
- Tarea 3.5 — APPROVED WITH OBSERVATIONS
- Tarea 3.6 — APPROVED
- Tarea 3.7 — APPROVED WITH OBSERVATIONS
- Fase 4 — IN_PROGRESS
- Tarea 4.1 — Contratos SQL y resumen mensual — APPROVED + DEPLOYED DEV
- Tarea 4.2 — Distribución por categorías y Top 5 — APPROVED + DEPLOYED DEV
- Tarea 4.3 — APPROVED + DEPLOYED DEV
- Tarea 4.4 — APPROVED WITH OBSERVATIONS
- Tarea 4.5 — IN_PROGRESS

## Identificador Android

- `applicationId`/package definitivo y aprobado: `com.soma.expenses`

## Dependencias dev

- `integration_test` (SDK Flutter) — añadida durante la validación integrada de
  Tarea 2.4 (registrada antes de su aprobación explícita). Futuras dependencias
  deben escalarse previamente según AGENTS.md.

## Validación Tarea 2.4

- Flujo de autenticación validado contra Supabase local en Web (ChromeDriver) y
  Android (emulador): registro → autenticado → logout → login → restauración de
  sesión. `profiles.id = auth.users.id` verificado.

## Validación Tarea 2.5

- Proyecto remoto `soma-dev` vinculado y migración `profiles` desplegada.
  Verificación remota: `profiles` con FK a `auth.users`, constraint
  PEN/USD/EUR, RLS, policies, grants, `handle_new_user()` y trigger de creación.
- Smoke test remoto: `auth user → trigger → profile` confirmado,
  `profile.id = auth.users.id` y `base_currency = USD`; aislamiento RLS
  verificado (usuario A no lee perfil de B); datos de prueba eliminados.

## Validación Tarea 2.6

- Google OAuth (Web + Android) implementado sobre `signInWithOAuth` de
  supabase_flutter sin SDK nativo ni dependencias nuevas.
- Provider Google configurado y verificado en `soma-dev`; allow list de
  redirects registrada (`http://localhost:8080` y
  `com.soma.expenses://auth-callback/`).
- Smoke test real: Web (2 cuentas Google nuevas) y Android (navegador externo
  → deep link → foreground → logout). `profile.id = auth.users.id` y
  `base_currency = USD` verificados. Datos de prueba eliminados.

## Validación Tarea 2.7

- Email confirmation y password recovery implementados sobre Supabase Auth sin
  dependencias nuevas.
- `emailRedirectTo` en `signUp` y `redirectTo` en `resetPasswordForEmail`
  centralizados en `SupabaseAuthService._authRedirectTo`.
- `AuthController` detecta estado `passwordRecovery` mediante el evento oficial
  `AuthChangeEvent.passwordRecovery` (sin inferir de metadata de sesión).
- `resetPasswordForEmail` distingue resultado neutral de fallo operativo;
  la UI mantiene respuesta neutral (sin enumeración de cuentas).
- La suscripción al stream de auth gestiona `onError` de forma segura.
- UI: `ForgotPasswordScreen` con respuesta neutral, `ResetPasswordScreen` para
  establecer nueva contraseña.
- Tests unitarios: 43 tests pasando (sin regresión).
- Análisis estático: sin issues.
- Build Web: exitoso.
- Build Android: exitoso (APK debug instalado y validado en Galaxy S25 Ultra).
- Navegación de recovery derivada del estado de auth (sin pulsar "atrás"):
  - `AuthController.updatePassword` cierra la sesión tras éxito, de modo que
    `ResetPasswordScreen` se desmonta y AuthGate muestra el login.
  - `ForgotPasswordScreen` se desapila automáticamente al llegar la sesión de
    recovery (`passwordRecovery`), revelando `ResetPasswordScreen` sin "atrás".
- Pruebas integradas manuales contra `soma-dev` (todas aprobadas):
  - Web email confirmation: registro → confirmación → email → redirección
    `http://localhost:8080` → "Sesión iniciada".
  - Web password recovery: mensaje neutral → `ResetPasswordScreen` →
    actualización → logout automático → login con nueva contraseña.
  - Android password recovery: deep link `com.soma.expenses://auth-callback/`
    → foreground → `ResetPasswordScreen` directo → actualización → login
    automático sin pulsar "atrás".
  - Regresión: login email/password, Google OAuth, logout y restauración de
    sesión (Web y Android).
- Verificación SQL remota: `1 fila coincidente`, `profile_id = auth.users.id`
  (`a8441cd8-8db4-48bd-aeac-d3bd21bc04ba`) y `base_currency = USD`.
- Datos de prueba eliminados.

## Fase 3 — Núcleo financiero (PEN-only, ADR-005)

- Tarea 3.1 — Alineación PEN-only y retirada de base_currency — APPROVED
- Tarea 3.2 — Modelo de categorías + RLS — APPROVED
- Tarea 3.3 — Modelo de gastos + RLS — APPROVED + DEPLOYED DEV
- Tarea 3.4 — CRUD de categorías — APPROVED WITH OBSERVATIONS
- Tarea 3.5 — CRUD de gastos — APPROVED WITH OBSERVATIONS
- Tarea 3.6 — Integración Flutter del núcleo financiero — APPROVED
- Tarea 3.7 — Pruebas adversariales y cierre — APPROVED WITH OBSERVATIONS

## Fase 4 — Métricas (PEN-only)

- Tarea 4.1 — Contratos SQL y resumen mensual — APPROVED + DEPLOYED DEV
  (RPC `public.expenses_monthly_total(p_month date)`; sin UI ni
  MetricsRepository Flutter)
- Tarea 4.2 — Distribución por categorías y Top 5 — APPROVED + DEPLOYED DEV
  (RPC `expenses_spending_by_category` / `expenses_top_categories` /
  `expenses_top_merchants`; sin UI ni MetricsRepository Flutter)
- Tarea 4.3 — Evolución de 6 meses y comparación con período anterior —
  APPROVED + DEPLOYED DEV
  (RPC `expenses_monthly_trend` / `expenses_monthly_comparison`;
  sin UI ni MetricsRepository Flutter)
- Tarea 4.4 — Capa Flutter de métricas — APPROVED WITH OBSERVATIONS
  (`MetricsRepository` + `SupabaseMetricsStore` consumiendo las seis RPC
  aprobadas; sin UI ni dashboard)
- Tarea 4.5 — Dashboard de métricas e integración de presentación —
  IN_PROGRESS
  (`MetricsController` + dashboard `Resumen` sobre `MetricsRepository`;
  sin cálculos nuevos en Flutter, sin dependencias nuevas)

## Observación registrada (Tarea 4.4, pendiente de tarea explícita)

- `parseExpenseAmount('')` devuelve `0` en lugar de fallar cerrado.
  NO corregido en Tarea 4.5 por alcance (la tarea lo prohíbe
  explícitamente). Su corrección queda para una tarea explícita posterior.

## Pendientes de decisión

- ~~Antes de implementar FX~~ — eliminado por ADR-005 (PEN-only): no hay
  FX, proveedor FX ni moneda base configurable en el MVP.
- **Comportamiento "mismo email" en OAuth (Tarea 2.6)**: Supabase Auth
  enlaza automáticamente identidades con el mismo email (automatic linking,
  habilitado por defecto). Decidir si este comportamiento es aceptable o si
  requiere una política explícita antes de dar por cerrada la tarea.
