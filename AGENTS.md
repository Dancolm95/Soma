# AGENTS.md — Soma

Proyecto: Soma — aplicación personal de gestión de gastos asistida por IA.

Stack aprobado: Flutter/Dart (Web + Android), Supabase (PostgreSQL + Auth + RLS),
Gemini 2.5 Flash.

Soma MVP is PEN-only (ADR-005, supersedes ADR-004 for the MVP).

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

## Modelo financiero

Soma MVP is PEN-only.

OpenCode MUST STOP and escalate before:

- introducing another persisted currency;
- implementing currency conversion;
- adding an FX provider;
- changing the PEN-only financial semantics.

## Código y comentarios

- Priorizar código claro y autoexplicativo.
- No añadir comentarios que simplemente describan lo que el código ya expresa.
- No comentar rutinariamente cada función, clase, variable o bloque.
- Usar comentarios cuando expliquen decisiones no obvias, restricciones de
  seguridad, invariantes, workarounds o razones importantes.
- Evitar DartDoc/documentación rutinaria que no aporte información.
- Los controles de seguridad no deben eliminarse simplemente para reducir
  comentarios.

## Validación

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```
