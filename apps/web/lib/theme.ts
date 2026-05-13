export const theme = {
  colors: {
    skyBlue: "#3A8DDE",
    backArrow: "#0C6CC2",
    white: "#FFFFFF",
    white10: "rgba(255,255,255,0.1)",
    white15: "rgba(255,255,255,0.15)",
    white30: "rgba(255,255,255,0.3)",
    white60: "rgba(255,255,255,0.6)",
  },
  gradient: {
    stop1: "rgb(102,178,255)", // top
    stop2: "rgb(89,166,242)",
    stop3: "rgb(77,153,230)",
    stop4: "rgb(64,140,217)", // bottom
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
