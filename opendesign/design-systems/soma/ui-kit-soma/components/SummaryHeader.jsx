/** SummaryHeader — recreates the metrics "Resumen" header with the
 *  month selector from metrics_page.dart ("Octubre 2026" / 10/2026). */
export function SummaryHeader({ monthLabel, total }) {
  return (
    <header
      style={{
        background: "var(--surface-primary)",
        border: "1px solid var(--border-subtle)",
        borderRadius: "var(--radius-l)",
        padding: "var(--sp-6)",
        boxShadow: "var(--shadow-1)",
      }}
    >
      <p style={{ font: "var(--caption)", color: "var(--fg-3)" }}>
        Resumen · {monthLabel}
      </p>
      <p
        style={{
          font: "var(--display)",
          fontVariantNumeric: "tabular-nums",
          color: "var(--fg-1)",
          margin: "var(--sp-2) 0 0",
        }}
      >
        {total}
      </p>
      <p style={{ font: "var(--small)", color: "var(--fg-2)" }}>
        Total del período, en PEN
      </p>
    </header>
  );
}
