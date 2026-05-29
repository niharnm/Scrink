export const theme = {
  colors: {
    skyBlue: "#4C9DFF",
    backArrow: "#7FB6FF",
    white: "#FFFFFF",
    // On the dark navy surface these read as crisp glass / legible text.
    white10: "rgba(255,255,255,0.05)",
    white15: "rgba(255,255,255,0.07)",
    white30: "rgba(255,255,255,0.14)",
    white60: "rgba(235,242,255,0.62)",
  },
  // Deep navy gradient that matches the iOS app's dark aesthetic.
  gradient: {
    stop1: "#0A1124", // top
    stop2: "#0C1530",
    stop3: "#0B1330",
    stop4: "#070C1C", // bottom
  },
  // Semantic surface tokens for glass cards, borders, accents and glows.
  surface: {
    card: "rgba(255,255,255,0.045)",
    cardStrong: "rgba(255,255,255,0.07)",
    border: "rgba(255,255,255,0.10)",
    borderStrong: "rgba(255,255,255,0.18)",
    accent: "#4C9DFF",
    accentSoft: "rgba(76,157,255,0.16)",
    glowA: "rgba(76,157,255,0.22)", // top-left cool glow
    glowB: "rgba(120,86,255,0.16)", // bottom-right violet glow
    shadow: "0 18px 48px rgba(0,0,0,0.45)",
    danger: "#FF6B6B",
    success: "#4ADE80",
  },
  fonts: {
    display: "'Coolvetica', system-ui, sans-serif",
    body: "'Coolvetica', system-ui, sans-serif",
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
