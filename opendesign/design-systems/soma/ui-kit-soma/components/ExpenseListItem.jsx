/** ExpenseListItem — recreates the expenses list row implied by
 *  expenses_page.dart (merchant, category, date, PEN amount). */
export function ExpenseListItem({ merchant, category, date, amountMinor }) {
  const amount = `S/ ${(amountMinor / 100).toFixed(2)}`;
  return (
    <li
      style={{
        display: "flex",
        alignItems: "center",
        gap: "var(--sp-3)",
        background: "var(--surface-primary)",
        border: "1px solid var(--border-subtle)",
        borderRadius: "var(--radius-m)",
        padding: "var(--sp-3) var(--sp-4)",
        boxShadow: "var(--shadow-1)",
      }}
    >
      <span
        aria-hidden
        style={{
          width: 40,
          height: 40,
          borderRadius: "var(--radius-s)",
          background: "var(--accent-soft)",
          color: "var(--accent-ink)",
          display: "grid",
          placeItems: "center",
          font: "var(--body-strong)",
        }}
      >
        {merchant.slice(0, 1).toUpperCase()}
      </span>
      <span style={{ flex: 1, display: "grid" }}>
        <span style={{ font: "var(--body-strong)", color: "var(--fg-1)" }}>
          {merchant}
        </span>
        <span style={{ font: "var(--small)", color: "var(--fg-3)" }}>
          {category} · {date}
        </span>
      </span>
      <span
        style={{
          font: "var(--body-strong)",
          fontVariantNumeric: "tabular-nums",
          color: "var(--fg-1)",
        }}
      >
        {amount}
      </span>
    </li>
  );
}
