export const theme = {
  colors: {
    // Living Sky accent — matches the iOS app + marketing site.
    skyBlue: "#7F85FF", // periwinkle accent (legacy token name kept)
    backArrow: "#5BE1C6", // aurora cyan
    auroraCyan: "#5BE1C6",
    auroraViolet: "#8A7CFF",
    dawnGlow: "#F5C9A8",
    white: "#FFFFFF",
    white10: "rgba(255,255,255,0.1)",
    white15: "rgba(255,255,255,0.15)",
    white30: "rgba(255,255,255,0.3)",
    white60: "rgba(255,255,255,0.62)",
  },
  // Aurora gradient for primary actions.
  auroraGradient: "linear-gradient(120deg, #5BE1C6, #8A7CFF)",
  gradient: {
    stop1: "rgb(7,11,30)", // night top  #070B1E
    stop2: "rgb(18,26,58)", // night mid  #121A3A
    stop3: "rgb(18,26,58)",
    stop4: "rgb(30,42,87)", // horizon    #1E2A57
  },
  fonts: {
    display: "'Geist', system-ui, sans-serif",
    body: "'Geist', system-ui, sans-serif",
    mono: "'Geist Mono', ui-monospace, monospace",
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
