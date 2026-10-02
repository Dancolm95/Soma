# Notas de estilo — Soma

Sistema Material 3 by-the-book con personalidad Soma. Frío-neutro
(slate azulado, chroma ≤ 0.02 en superficies), 1–2 acentos por dirección,
una sola familia tipográfica por dirección.

## Direcciones (toggle `data-direction`)

**B · Ágil es canónica.** A y C son exploraciones archivadas.

|  | B · Ágil (canónica) | A · Sereno | C · Cercano |
|---|---|---|---|
| Audiencia/tono | Peruano, calma y confianza | Amplio, nítido y eficiente | Amable, cercano |
| Acento | Teal `#0B6E6D` | Cobalt `#3B63D8` | Emerald `#0E7F56` |
| Fuente | Public Sans | IBM Plex Sans | Nunito Sans |
| Radios | 12 / 16 / 20 / 28 | 8 / 10 / 12 / 16 | 14 / 18 / 24 / pill |
| Densidad | Cómoda | Compacta | Generosa |

## Fundaciones

- **Color:** roles, no muestras. `surface-page` (fondo app),
  `surface-primary` (cards/sheets), `surface-sunken` (inputs, gráficos),
  `accent` solo para acción principal y foco; `accent-soft` para
  resaltados (preview IA, mes seleccionado). Peligro solo en eliminar.
- **Tipo:** escala display–caption en tokens. Importes siempre
  semibold/tabular (`font-variant-numeric: tabular-nums`), nunca mono
  salvo IDs/debug. En Flutter: `TextStyle(fontFeatures: [FontFeature.tabularFigures()])`.
- **Espaciado:** escala 4pt; página móvil 16, desktop max-width 800
  (como `metrics_page.dart`).
- **Fondos:** planos, sin gradientes. `surface-sunken` para zonas de
  extracción/preview IA.
- **Movimiento:** `150/250/350ms`, easing M3 `cubic-bezier(0.2,0,0,1)`.
  Entrada IA: shimmer en `surface-sunken`, cancelable.
- **Estados:** hover +8% overlay negro (light) / blanco (dark);
  pressed +12%; foco = outline 2px `accent` offset 2px; deshabilitado =
  38% opacidad, sin eventos. Error = borde + mensaje `danger`, nunca
  solo color.
- **Bordes/sombras:** 1px `border-subtle`; cards elevadas `shadow-1/2`,
  sheets `shadow-3`. En Flutter: `Card(elevation: 1)`, dialogs M3.

## Mapeo Flutter (Material 3)

`accent` → `ColorScheme.primary`; `bg-2` → `surface`;
`bg-1` → `surfaceContainerLowest`; `radius-m/l` → `Corner.*`;
botón principal → `FilledButton`, secundario → `TextButton`,
destructivo → `FilledButton` con `error` (como el diálogo de eliminar
actual). Importes: `NumberFormat('#,##0.00', 'es_PE')` con prefijo `S/ `.

## Iconografía

Material Symbols (outlined) exclusivamente, 24px, peso 400.
Comprobante sin asset = placeholder rayado con etiqueta mono
(«foto del comprobante»), nunca dibujar recibos a mano.
