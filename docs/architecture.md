# Arquitectura — Soma

> Arquitectura aprobada (Gate 2). Fuente de verdad arquitectónica.

## Cliente

Flutter + Dart.

Targets MVP:
- Web
- Android

iOS posterior.

## Estilo

Monolito modular.

NO microservicios.

## Backend

Supabase administrado:

- PostgreSQL;
- Auth;
- RLS;
- funciones/API backend cuando una operación requiera secretos, privilegios o consumo de servicios externos.

## Región

São Paulo / sa-east-1.

## IA

Contrato conceptual: `ExpenseExtractor`.

Proveedor inicial aprobado: Gemini 2.5 Flash paid tier.

La lógica de negocio no debe depender directamente de Gemini.

Las llamadas IA son backend-only.

## Modelo financiero

Soma MVP es PEN-only (ADR-005). Todos los gastos persistidos representan
importes en PEN. No existe moneda base configurable, conversión FX,
proveedor FX ni almacenamiento de tipos de cambio.

Referencia histórica: ADR-004 definió `ExchangeRateProvider`/Frankfurter v2
antes de ser sustituido por ADR-005 para el MVP.

## CRUD de categorías (Tarea 3.4)

Contrato de aplicación sin tipos Supabase en la frontera:
`Category` (`id`, `name`, `userId?`, `isSystem = userId == null`),
`CategoryRepository` (`list/create/rename/delete`) y `CategoryError`
(`invalidName`, `duplicateName`, `categoryInUse`, `forbidden`,
`unexpected`) con mensajes seguros. Solo `name` viaja en escrituras;
`user_id` lo deriva la sesión. Implementación PostgREST
(`SupabaseCategoryStore` + `SupabaseCategoryRepository`) con RLS como
frontera y guardas de sistema en aplicación.

## Núcleo financiero (Tareas 3.2–3.3, PEN-only)

- `public.categories`: `id uuid PK default gen_random_uuid()`; `user_id`
  nullable (`NULL` = sistema, `<usuario>` → `auth.users` con
  `on delete cascade`); `name` con unicidad lógica por ámbito; seed del
  sistema (8 filas globales).
- `public.expenses`: `id uuid PK default gen_random_uuid()`;
  `user_id uuid NOT NULL default auth.uid()` → `auth.users`
  con `on delete cascade`; `amount numeric(12,2) CHECK (> 0)`;
  `expense_date date NOT NULL`; `merchant text` 1–120 tras `btrim`;
  `category_id uuid NOT NULL` → `categories(id)` con `on delete restrict`;
  `created_at/updated_at timestamptz`.
- Invariante de categoría procedural en DB (alternativa B aprobada):
  triggers `SECURITY INVOKER` sin privilegios elevados, UUID opacos.
  `expenses_check_category_owner` (`BEFORE INSERT OR UPDATE OF
  category_id, user_id` en `expenses`): acepta solo categoría global o
  privada del mismo `user_id`, rechaza (`23503`); serializa por categoría
  con advisory xact lock (`FOR SHARE` es inviable: `authenticated` no
  tiene `UPDATE` en `categories` y bajo RLS no devuelve filas).
  `categories_guard_expense_owner` (`BEFORE UPDATE OF user_id` en
  `categories`): rechaza (`23503`) cualquier cambio que deje un gasto
  existente inválido. `category_id → categories(id)` con
  `on delete restrict` cubre existencia y borrado.
- Sin columnas `currency`, FX ni recibos en el MVP.

## Métricas

PostgreSQL/backend, exclusivamente en PEN.

Nunca LLM como calculadora financiera autoritativa.

## Comprobantes

Procesamiento efímero.

No forman parte del almacenamiento permanente del negocio.

Flujo:

`archivo → validación → procesamiento → candidato → revisión → confirmación → eliminación del original temporal`

## Fronteras de confianza

- Flutter → backend
- backend → PostgreSQL
- backend → Gemini

El cliente nunca es una frontera confiable para autorización.
