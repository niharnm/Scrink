/**
 * Rinkler web design tokens — "stark minimal" direction: true-black canvas,
 * near-monochrome, one restrained accent used sparingly, hairline rules, big
 * confident Geist type. Deliberately no gradient glows or gradient buttons
 * (those read as generic). Token keys are kept stable for existing imports.
 */
export const signal = {
  bg: "#08080A", // near true black
  bgElev: "#0D0D0F",
  card: "#0D0D0F",
  cardRaised: "#141416",
  border: "rgba(255,255,255,0.08)", // hairline
  borderStrong: "rgba(255,255,255,0.16)",
  text: "#ECECEE", // off-white, not pure
  textDim: "#8A8A90",
  textFaint: "#56565C",
  accent: "#6E8BFF", // used rarely (a dot, a focus ring, a single underline)
  blue: "#6E8BFF",
  violet: "#8B5CF6",
  success: "#5FB98E",
  warning: "#D8A24A",
  // Kept for backwards-compat; the stark UI uses solid white/black buttons, not this.
  glow: "#ECECEE",
  sans:
    "var(--font-geist), system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
  mono: "var(--font-geist-mono), ui-monospace, 'SF Mono', Menlo, Consolas, monospace",
} as const;
