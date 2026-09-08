# ADR-004 — FX histórico (ExchangeRateProvider)

Status: Superseded by ADR-005-pen-only-financial-model.md for the MVP.

## Context

Se necesitan conversiones de moneda con tipos históricos reproducibles.

## Decision

Definir `ExchangeRateProvider` como abstracción, con Frankfurter v2 como proveedor inicial. FX histórico por fecha y persistencia de la información de conversión para reproducibilidad.

## Supersession

Superseded by ADR-005-pen-only-financial-model.md for the MVP. This file is
kept unchanged as the historical record of the originally approved FX
decision; do not reinterpret it as if FX had never been approved.

## Consequences

- Las conversiones usan la fecha del gasto.
- Las métricas históricas son reproducibles.
