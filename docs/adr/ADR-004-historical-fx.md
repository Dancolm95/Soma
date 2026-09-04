# ADR-004 — FX histórico (ExchangeRateProvider)

Status: Accepted

## Context

Se necesitan conversiones de moneda con tipos históricos reproducibles.

## Decision

Definir `ExchangeRateProvider` como abstracción, con Frankfurter v2 como proveedor inicial. FX histórico por fecha y persistencia de la información de conversión para reproducibilidad.

## Consequences

- Las conversiones usan la fecha del gasto.
- Las métricas históricas son reproducibles.
