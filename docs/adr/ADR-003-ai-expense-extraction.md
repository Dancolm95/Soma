# ADR-003 — Extracción de gastos con IA (ExpenseExtractor)

Status: Accepted

## Context

El registro de gastos requiere extracción de datos a partir de texto natural, cámara y documentos.

## Decision

Definir `ExpenseExtractor` como abstracción, con Gemini 2.5 Flash (paid tier) como implementación inicial. Validación backend + confirmación humana.

## Consequences

- La lógica de negocio no depende directamente de Gemini.
- Las llamadas IA son backend-only.
- La IA nunca confirma ni persiste automáticamente un gasto.
