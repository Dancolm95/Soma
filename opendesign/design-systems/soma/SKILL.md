# Skill: soma

Design system for Soma (AI-assisted personal expense app, PEN-only).

## Use

Link `tokens/colors_and_type.css` and scope the page:

```html
<link rel="stylesheet" href="tokens/colors_and_type.css" />
<html data-direction="a" data-theme="light">
```

Use semantic vars only (`--accent`, `--surface-primary`, `--h2`,
`--body`, `--amount`, `--radius-m`, `--sp-4`). Never raw hex or raw
font stacks in components. `data-direction` is `b` (Ágil, canonical), `a` (Sereno, archived), or `c` (Cercano, archived); `data-theme` is `light` or `dark`.

## Rules

- Spanish (Perú), sentence case, no emojis in UI.
- Money: `S/ 1 234,56`, tabular figures, PEN-only — never convert.
- AI proposes, user confirms: extraction screens always end in an
  explicit user action («Guardar gasto»).
- Material 3 mapping: `--accent` = primary, `FilledButton` primary,
  `TextButton` secondary, `error` destructive only.
- Cool-slate neutrals, flat surfaces, no gradients.
- Missing asset? Labeled striped placeholder, never hand-drawn SVG.
