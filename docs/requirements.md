# Requisitos — Soma

> Fuente de verdad de requisitos aprobados (Gate 1–3).
> Solo se registran requisitos aprobados. No añadir supuestos.

## Objetivo

Aplicación personal de gestión de gastos asistida por IA.

## Usuarios

- Múltiples usuarios individuales.
- Aislamiento estricto entre usuarios.
- Sin espacios compartidos ni equipos en el MVP.
- Objetivo inicial aproximado: 100–10 000 usuarios.

## Plataformas

MVP:
- Web
- Android

Posterior:
- iOS

Entornos de desarrollo actualmente utilizados:
- Windows/WSL
- macOS

Los entornos de desarrollo NO son targets del producto.

## Autenticación

- Google.
- email/password.
- Recuperación/verificación correspondiente.
- Autorización basada en propiedad.

## Registro de gastos

Entradas MVP:
- texto natural;
- cámara/fotografía;
- PDF;
- JPG/JPEG;
- PNG.

Flujo obligatorio:

`input → extracción → preview → corrección/revisión del usuario → confirmación → persistencia`

La IA nunca confirma ni persiste automáticamente un gasto.

## Datos extraídos

- monto;
- moneda detectada (informativa, sin conversión);
- fecha;
- comercio/concepto;
- categoría.

## CRUD

El usuario puede consultar, editar y eliminar únicamente sus propios gastos.

## Categorías

- Predefinidas.
- Personalizadas por usuario.
- La IA puede sugerir.
- La IA no crea categorías automáticamente.

## Moneda

Soma MVP usa exclusivamente PEN como semántica monetaria persistida.

No hay moneda base configurable.
No hay conversión automática.

Si texto/recibo/documento contiene otra moneda, el pipeline puede
detectarla durante extracción/revisión, pero no debe realizar conversión
FX.

El importe confirmado por el usuario es el importe que se persiste
como PEN.

## Métricas MVP

- total por período;
- gasto por categoría;
- evolución mensual;
- comparación con período anterior;
- principales categorías/comercios.

Las métricas son determinísticas y se calculan exclusivamente en PEN.

Las métricas son determinísticas.

## Fuera del MVP

- iOS;
- integración bancaria;
- presupuestos/límites;
- explicaciones financieras generadas por IA;
- Android Share Target, salvo decisión posterior.
