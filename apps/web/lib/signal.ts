/**
 * Rinkler "Signal" identity for the web — mirrors the iOS app's redesign:
 * a near-black control-panel surface with a single blue→violet signal glow.
 * Kept as a plain token object so it can drive inline styles (this app has no
 * Tailwind), matching the existing pattern in lib/theme.ts.
 */
export const signal = {
  bg: "#08090B",
  card: "#14161A",
  cardRaised: "#1B1E24",
  border: "#2A2E36",
  text: "#F8FAFC",
  textDim: "#9CA3AF",
  blue: "#5B7CFF",
  violet: "#8B5CF6",
  success: "#63D297",
  warning: "#FFB454",
  glow: "linear-gradient(135deg, #5B7CFF 0%, #8B5CF6 100%)",
  sans:
    "'Geist', system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
  mono: "'Geist Mono', ui-monospace, 'SF Mono', Menlo, Consolas, monospace",
} as const;
