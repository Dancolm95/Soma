# Plan de implementación — Soma

> Estado del plan aprobado.
> Estados: `PENDING`, `IN_PROGRESS`, `APPROVED`, `BLOCKED`.

## Fases

- Fase 1 — Fundación y gobierno
- Fase 2 — Supabase, identidad y aislamiento
- Fase 3 — Núcleo financiero + FX
- Fase 4 — Métricas
- Fase 5 — IA texto
- Fase 6 — Comprobantes/cámara
- Fase 7 — Hardening y producción

## Estado actual

- Fase 1 — COMPLETED
- Tarea 1.1 — APPROVED
- Tarea 1.2 — APPROVED
- Tarea 1.3 — APPROVED
- Fase 2 — IN_PROGRESS
- Tarea 2.1 — APPROVED
- Tarea 2.2 — APPROVED
- Tarea 2.3 — APPROVED
- Tarea 2.4 — APPROVED
- Tarea 2.5 — IN_PROGRESS

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

## Pendientes de decisión

- **Antes de implementar FX**: definir el comportamiento cuando el usuario cambia su moneda base.
