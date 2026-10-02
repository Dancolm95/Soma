/** AmountField — recreates amount_input.dart: PEN-only amount entry.
 *  Prefix "S/ " is fixed chrome, never editable (ADR-005). */
export function AmountField({ value, error, onChange }) {
  return (
    <label style={{ display: "grid", gap: "var(--sp-1)" }}>
      <span style={{ font: "var(--caption)", color: "var(--fg-2)" }}>Monto</span>
      <span
        style={{
          display: "flex",
          alignItems: "center",
          gap: "var(--sp-2)",
          background: "var(--surface-sunken)",
          borderRadius: "var(--radius-s)",
          border: `1px solid ${error ? "var(--danger)" : "var(--border-subtle)"}`,
          padding: "12px var(--sp-4)",
        }}
      >
        <span style={{ font: "var(--body-strong)", color: "var(--fg-3)" }}>S/</span>
        <input
          inputMode="decimal"
          value={value}
          onChange={onChange}
          placeholder="0,00"
          style={{
            font: "var(--amount)",
            fontVariantNumeric: "tabular-nums",
            background: "transparent",
            border: "none",
            outline: "none",
            width: "100%",
            color: "var(--fg-1)",
          }}
        />
      </span>
      {error ? (
        <span style={{ font: "var(--small)", color: "var(--danger)" }}>{error}</span>
      ) : null}
    </label>
  );
}
