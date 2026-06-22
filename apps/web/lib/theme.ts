/**
 * Dashboard theme — now the "Signal" identity (matches the iOS app + the
 * marketing site): a near-black control-panel surface with a single blue→violet
 * signal accent. Token KEYS are unchanged so every dashboard component keeps
 * working; only the values moved from the old blue "Living Sky" palette.
 */
export const theme = {
  colors: {
    skyBlue: "#D4D4D8", // monochrome "accent" — charts/active states render light grey
    violet: "#9A9AA0", // secondary mono tone for multi-series charts
    success: "#9CA3AF",
    warning: "#B8B8BE",
    backArrow: "#D4D4D8",
    white: "#ECECEE", // primary text (off-white, not pure)
    white10: "rgba(255,255,255,0.035)", // faint fill
    white15: "rgba(255,255,255,0.06)", // raised fill / hover
    white30: "rgba(255,255,255,0.10)", // hairline borders
    white60: "rgba(255,255,255,0.55)", // dim/secondary text
  },
  gradient: {
    stop1: "#0A0A0B", // top
    stop2: "#090909",
    stop3: "#08080A",
    stop4: "#08080A", // bottom
  },
  fonts: {
    display: "var(--font-geist), system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    body: "var(--font-geist), system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif",
    mono: "var(--font-geist-mono), ui-monospace, 'SF Mono', Menlo, Consolas, monospace",
  },
  fontSizes: {
    titleLarge: 64,
    titleMedium: 36,
    titleSmall: 24,
    subtitle: 28,
    headerTitle: 32,
    buttonText: 36,
    body: 18,
    optionLabel: 16,
    appLabel: 18,
    small: 14,
  },
  spacing: {
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
  },
  iconSizes: {
    appSmall: 56,
    appMedium: 64,
    appLarge: 72,
    clusterCenter: 96,
    clusterMedium: 76,
    clusterPlus: 64,
  },
  button: {
    height: 56,
    cornerRadius: 28,
    horizontalPadding: 100,
  },
  animation: {
    cloudDuration: 10,
    springResponse: 0.5,
    springDamping: 0.7,
    transitionDuration: 0.3,
  },
} as const;
