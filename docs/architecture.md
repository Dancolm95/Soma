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

## CRUD de gastos (Tarea 3.5)

Contrato de aplicación sin tipos Supabase en la frontera:
`Expense` (`id`, `amountMinor` en céntimos, `expenseDate`, `merchant`,
`categoryId`, `createdAt`, `updatedAt`), `ExpenseRepository`
(`list/create/update/delete`) y `ExpenseError` (`invalidAmount`,
`invalidMerchant`, `invalidDate`, `invalidCategory`, `forbidden`,
`notFound`, `unexpected`) con mensajes seguros. Importe exacto sin
`double` ni dependencias: entero de unidades menores en dominio,
cadena `numeric(12,2)` (`1`–`999999999999` céntimos) hacia la DB, con
parseo exacto de vuelta. Solo `amount/expense_date/merchant/category_id`
viajan en escrituras; `user_id` lo deriva la sesión. Implementación
PostgREST (`SupabaseExpenseStore` delgado + `SupabaseExpenseRepository`
que valida, convierte, mapea y verifica 0 filas en update/delete como
`notFound` sin revelar propiedad ajena) con RLS como frontera.

## Presentación del núcleo financiero (Tarea 3.6)

Composición en `main.dart` (sin service locator nuevo): Supabase client
único → stores → `SupabaseExpenseRepository`/`SupabaseCategoryRepository`
→ `ExpensesController`/`CategoriesController` (`ChangeNotifier`, ya usado
por `AuthController`) → `SomaApp`/`AuthGate` → `ExpensesPage`
(`Gastos`, home autenticado) y `CategoriesPage`. Sin dependencias de
state management ni UI nuevas; widgets nunca llaman a Supabase
directamente. Importe exacto sin `double`: `tryParseAmountMinor`
(acepta `19.90`/`19,90`, máximo 2 decimales) y `formatPen` (`S/ 19.90`)
con aritmética entera sobre `amountMinor`.

## Métricas

PostgreSQL/backend, exclusivamente en PEN.

Nunca LLM como calculadora financiera autoritativa.

### Resumen mensual (Tarea 4.1)

Métricas deterministas en PostgreSQL vía RPC `SECURITY INVOKER`
(`public.expenses_monthly_total(p_month date)`): el cliente envía solo el
mes, PostgreSQL lo canonicaliza (`date_trunc('month', p_month)`) y deriva
internamente el rango sobre `expense_date`. Aislamiento por `auth.uid()`
con RLS como segunda defensa; grants mínimos (solo `authenticated`
ejecuta). `MetricsRepository` (Flutter) será consumidor futuro; Tarea 4.1
no implementa UI, modelos Dart de métricas ni repositorio.

### Distribución y Top 5 (Tarea 4.2)

Tres RPC pequeñas bajo el mismo patrón (`SECURITY INVOKER`, mes como
entrada, `expense_date`, `numeric` exacto):
`expenses_spending_by_category` (agrupado por `category_id`, nombre vía
JOIN), `expenses_top_categories` (reutiliza la agrupación anterior +
`LIMIT 5`) y `expenses_top_merchants` (agrupado por el valor exacto de
`merchant`, sin normalización). Orden determinista (`total DESC`,
nombre/`merchant ASC`, `id` como último criterio). Sin vistas,
materialized views, caché ni normalización de merchants en Fase 4.

### Evolución y comparación (Tarea 4.3)

Dos RPC bajo el mismo patrón (`SECURITY INVOKER`, mes como entrada,
`expense_date`, `numeric` exacto):
`expenses_monthly_trend` (serie fija de 6 meses calendario `M-5..M` en
orden `period_start ASC`; los meses sin gastos aparecen con `0`, nunca
`NULL`, para que Flutter dibuje una serie continua) y
`expenses_monthly_comparison` (mes seleccionado vs mes calendario
inmediatamente anterior; `difference = current - previous`;
`percentage_change = ((current - previous) / previous) * 100` solo
cuando `previous > 0`, `NULL` en caso contrario).
PostgreSQL devuelve datos; Flutter decidirá la presentación
(formateo, redondeo visual, representación del `NULL`).

### Capa Flutter de métricas (Tarea 4.4)

PostgreSQL sigue siendo la única autoridad de cálculo. Flutter solo
selecciona un mes, llama las seis RPC aprobadas y mapea la respuesta:

`RPC PostgreSQL → SupabaseMetricsStore → MetricsRepository`
→ futuro controller/UI.

- `SupabaseMetricsStore` (infrastructure, delgado): ejecuta cada RPC con
  el único parámetro `{'p_month': 'YYYY-MM-01'}` (mes canonicalizado a
  día 1, sin `user_id`, sin rangos, sin JWT manual).
- `MetricsRepository` (application, seis operaciones: `monthlyTotal`,
  `spendingByCategory`, `topCategories`, `topMerchants`, `monthlyTrend`,
  `monthlyComparison`): canonicaliza el input, valida/mapa de forma
  estricta (fail-closed) y traduce errores a `MetricsError`
  (`invalidResponse`, `unauthorized`, `unexpected`) con mensajes seguros.
- Dinero: `numeric` exacto → enteros de céntimos (`parseMetricsAmount`,
  duplicado exacto del patrón de expenses; sin `double` financiero).
- `percentage_change` no es dinero: `PercentageChange` textual validado y
  nullable; `NULL` (mes previo en 0) se preserva como ausencia,
  distinguible de 0. Sin paquete decimal.
- El repository nunca recalcula (sin sumas, agrupaciones, Top 5,
  tendencias, `difference` ni porcentajes en Dart), nunca reordena ni
  normaliza (`Metro` ≠ `metro`), nunca rellena meses y nunca cachea
  (sin staleness entre usuarios; futuro controller vivirá en
  `SessionScope`). Validación estricta: total 1 fila, Top ≤ 5, trend
  exactamente 6 meses consecutivos terminando en el mes pedido,
  comparison 1 fila con mes previo calendario.
- Widgets nunca acceden a Supabase; RLS/`auth.uid()` sigue siendo la
  frontera de autorización, sin autorización client-side.

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
