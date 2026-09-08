# ADR-005 — Modelo financiero PEN-only

Status: Accepted

Supersedes ADR-004-historical-fx.md for the MVP.

## Context

Soma MVP está dirigido inicialmente a uso local en Perú.

La complejidad multi-moneda/FX no aporta suficiente valor al MVP.

## Decision

- Todos los gastos persistidos representan PEN.
- No existe moneda base configurable.
- No existe conversión FX.
- No existe proveedor FX.
- La IA no tiene autoridad para convertir monedas.
- Si una entrada contiene otra moneda, Soma no ejecuta conversión.
- El importe finalmente confirmado por el usuario se persiste bajo la
  semántica PEN del producto.

## Consequences

Positivas:

- Modelo financiero más simple.
- Menos dependencias externas.
- Menor superficie de fallo.
- Métricas determinísticas más sencillas.
- Menor coste operativo.

Limitaciones:

- Soma MVP no representa correctamente gastos multimoneda.
- Un número proveniente de USD/EUR no representa su valor económico
  equivalente en PEN si el usuario confirma ese mismo número.
- Soporte multimoneda futuro requerirá una nueva decisión arquitectónica
  y probablemente migración de datos.
