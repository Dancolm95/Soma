# Voz y tono — Soma (es-PE)

Producto en español peruano. Tuteo no usado en UI; trato de usted
implícito y neutro («Ingresa», «Revisa», «Guarda» — imperativo neutro,
como el código actual: «Gasto guardado.»).

## Principios

1. **La IA propone, la persona dispone.** Nunca «Guardé tu gasto».
   Siempre «Revisa y confirma».
2. **Claro antes que listo.** Un gasto ambiguo se pregunta, no se adivina.
3. **PEN siempre visible.** Todo importe lleva `S/` y formato
   `S/ 1 234,56` (espacio fino como separador de miles, coma decimal).
   Nunca mostrar otra moneda sin la etiqueta «informativo, sin conversión».

## Reglas

- Caja oración en títulos y botones («Nuevo gasto», «Eliminar», no
  «Nuevo Gasto»).
- Sin emojis en UI. Sin jerga financiera inglesa (no «cashback», «split»).
- Números: fechas `12 oct 2026`, meses del Resumen como en el código
  («Octubre 2026», selector `10/2026`).
- Errores: dicen qué pasó y qué hacer («Ingresa un importe válido.»).
  Nunca culpan («Te equivocaste»).
- Éxito: una línea, pasado simple («Gasto guardado.», «Gasto actualizado.»).
- IA: estados honestos («Extrayendo datos del comprobante…»),
  confianza visible solo si el backend la provee, y corrección siempre
  a un toque.

## Microcopias del flujo IA (input → extracción → preview → revisión → confirmación)

| Paso | Copia |
|---|---|
| Entrada | «Describe el gasto o toma una foto del comprobante.» |
| Extracción | «Extrayendo datos…» (progreso, cancelable) |
| Preview | «Revisa los datos extraídos» + aviso «La IA puede equivocarse.» |
| Moneda no-PEN | «Detectamos USD 12,40 (informativo). El importe a guardar es en PEN.» |
| Confirmación | «Guardar gasto» — solo el usuario pulsa |
| Guardado | «Gasto guardado.» |
| Eliminar | «¿Eliminar este gasto?» / «Se eliminará el registro de “X”. Esta acción no se puede deshacer.» |
