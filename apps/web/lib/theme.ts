/**
 * Dashboard theme — now the "Signal" identity (matches the iOS app + the
 * marketing site): a near-black control-panel surface with a single blue→violet
 * signal accent. Token KEYS are unchanged so every dashboard component keeps
 * working; only the values moved from the old blue "Living Sky" palette.
 */
export const theme = {
  colors: {
    skyBlue: "#5B7CFF", // primary signal accent (charts, buttons, links)
    violet: "#8B5CF6", // secondary accent for multi-series charts
    success: "#63D297",
    warning: "#FFB454",
    backArrow: "#5B7CFF",
    white: "#F8FAFC", // primary text on the dark surface
    white10: "rgba(255,255,255,0.05)", // card fill
    white15: "rgba(255,255,255,0.09)", // raised fill / hover
    white30: "rgba(255,255,255,0.14)", // hairline borders
    white60: "rgba(255,255,255,0.60)", // dim/secondary text
  },
  gradient: {
    stop1: "#0E1118", // top
    stop2: "#0B0D13",
    stop3: "#090A0E",
    stop4: "#08090B", // bottom
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
