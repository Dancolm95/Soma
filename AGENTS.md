# AGENTS.md — Soma

Proyecto: Soma — aplicación personal de gestión de gastos asistida por IA.

Stack aprobado: Flutter/Dart (Web + Android), Supabase (PostgreSQL + Auth + RLS),
Gemini 2.5 Flash, Frankfurter v2.

## Fuente de verdad

La fuente de verdad del proyecto vive en `/docs`. Antes de implementar, leer los
archivos relevantes según la tarea:

- `docs/requirements.md`
- `docs/architecture.md`
- `docs/security.md`
- `docs/operations.md`
- `docs/implementation-plan.md`
- `docs/adr/*.md`

## Rol y autoridad de OpenCode

OpenCode IMPLEMENTA, PRUEBA y REPORTA EVIDENCIA.

No posee autoridad arquitectónica.

Puede modificar únicamente lo autorizado por la tarea actual.

## Detenerse y escalar

DETENERSE Y ESCALAR antes de cambiar:

- Flutter/Dart;
- Supabase;
- PostgreSQL;
- Auth;
- RLS/autorización;
- región;
- modelo/semántica financiera;
- Gemini;
- ExpenseExtractor;
- Frankfurter;
- ExchangeRateProvider;
- estrategia de comprobantes;
- infraestructura;
- dependencias significativas;
- manejo de secretos.

## Prohibido (nunca)

- desactivar RLS para resolver un problema;
- colocar secretos en el repositorio;
- exponer secretos backend en Flutter;
- almacenar permanentemente comprobantes;
- ampliar silenciosamente el alcance;
- cambiar una ADR Accepted unilateralmente.

## Contradicciones

Si la documentación y la tarea parecen contradecirse: DETENERSE Y ESCALAR.

## Validación

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```
