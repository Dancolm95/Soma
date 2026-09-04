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

## FX

Contrato conceptual: `ExchangeRateProvider`.

Proveedor inicial: Frankfurter v2.

Las conversiones utilizan tipos históricos.

Persistir información suficiente para que las métricas históricas sean reproducibles.

## Métricas

PostgreSQL/backend.

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
- backend → Frankfurter

El cliente nunca es una frontera confiable para autorización.
