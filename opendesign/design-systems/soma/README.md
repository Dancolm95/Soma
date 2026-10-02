# Soma — design system

Sistema de diseño de **Soma**, app personal de gestión de gastos con IA
(Flutter Web + Android, PEN-only según ADR-005).

## Fuentes consultadas

- `docs/requirements.md` — flujos, CRUD, métricas, PEN-only
- `docs/architecture.md` — M3, monolito modular, Gemini backend-only
- `lib/application/app.dart` — `ThemeData(useMaterial3: true)` sin
  personalizar (M3 baseline morado = punto de partida, no marca)
- `lib/presentation/expenses/expenses_page.dart` — lista, crear/editar,
  diálogo de eliminar, SnackBar «Gasto guardado.»
- `lib/presentation/expenses/expense_form_page.dart` — monto, comercio,
  fecha, categoría, validación ES
- `lib/presentation/metrics/metrics_page.dart` — «Resumen», selector de
  mes, max-width 800
- `lib/features/auth/*` — login Google + email/password, recuperación

## Decisiones de intake (2026-10-01)

Crear desde cero · es-PE · neutros fríos · light + dark · fidelidad
producción · 3 direcciones · ejes color+tipo / layout+densidad /
componentes · postura Material by-the-book.

## Índice

- `tokens/colors_and_type.css` — tokens canónicos (raw + semánticos,
  `data-direction=a|b|c`, `data-theme=light|dark`). **Dirección B
  («Ágil») = canónica desde 2026-10-01.** A y C quedan archivadas.
- `brand/voice-and-tone.md` — voz es-PE, formato PEN, microcopias del
  flujo IA.
- `brand/style-notes.md` — fundaciones visuales + mapeo Flutter M3.
- `ui-kit-soma/foundations.html` — tokens, tipo, espaciado, radios,
  sombras, movimiento.
- `ui-kit-soma/components.html` — botones, campos, chips, cards, diálogo,
  snackbar, navegación.
- `ui-kit-soma/screens.html` — auth, gastos, formulario con preview IA,
  Resumen. Con toggles dirección + tema.
- `ui-kit-soma/components/*.jsx` — recreaciones token-driven de los
  componentes que ya existen en el código.

## Estado

Dirección B («Ágil»: cobalt, IBM Plex Sans, radios compactos) canonizada
el 2026-10-01 e implementada en Flutter (`lib/presentation/theme/`).
Variante Decidida aprobada el 2026-10-01: paleta de 8 categorías
(`--cat-h-0…7`, espejo en `category_colors.dart`) + home con balance hero
y captura rápida con numpad (`lib/presentation/home/`,
`lib/presentation/capture/`).
Falta copiar assets reales (logos/iconos) a `assets/` — sin assets
reales, no se inventan.
