/** SomaButton — recreates the FilledButton/TextButton usage in
 *  expenses_page.dart (Guardar / Eliminar / Cancelar).
 *  Token-driven: no raw values. */
export function SomaButton({ kind = "filled", tone = "accent", label, onPress }) {
  return (
    <button
      type="button"
      data-kind={kind}
      data-tone={tone}
      onClick={onPress}
      style={{
        font: "600 14px/1.4 var(--font)",
        padding: "10px 24px",
        borderRadius: "var(--radius-xl)",
        border: "1px solid transparent",
        background: kind === "filled" ? "var(--accent)" : "transparent",
        color: kind === "filled" ? "var(--on-accent)" : "var(--accent)",
      }}
    >
      {label}
    </button>
  );
}
