import type { Metadata, Viewport } from "next";
import localFont from "next/font/local";

// The exact Geist font files the iOS app bundles, so the site matches the app.
const geist = localFont({
  variable: "--font-geist",
  display: "swap",
  src: [
    { path: "./fonts/Geist-Regular.ttf", weight: "400", style: "normal" },
    { path: "./fonts/Geist-Medium.ttf", weight: "500", style: "normal" },
    { path: "./fonts/Geist-SemiBold.ttf", weight: "600", style: "normal" },
    { path: "./fonts/Geist-Bold.ttf", weight: "700", style: "normal" },
  ],
});
const geistMono = localFont({
  variable: "--font-geist-mono",
  display: "swap",
  src: [
    { path: "./fonts/GeistMono-Regular.ttf", weight: "400", style: "normal" },
    { path: "./fonts/GeistMono-Medium.ttf", weight: "500", style: "normal" },
  ],
});

export const metadata: Metadata = {
  // Required so OG/Twitter image + canonical URLs resolve to absolute paths.
  metadataBase: new URL("https://rinkler.app"),
  title: {
    default: "Rinkler — Block distracting apps with Screen Time.",
    template: "%s · Rinkler",
  },
  description:
    "Rinkler reliably blocks selected whole apps with Screen Time. Optional Instagram and TikTok network filters are experimental and require physical-device testing.",
  applicationName: "Rinkler",
  keywords: [
    "screen time app",
    "block reels",
    "block tiktok",
    "stop doomscrolling",
    "feed blocker",
    "focus app",
    "digital wellbeing",
    "Rinkler",
  ],
  alternates: { canonical: "/" },
  openGraph: {
    type: "website",
    url: "https://rinkler.app",
    siteName: "Rinkler",
    title: "Rinkler — whole-app blocking, with experimental feed filters",
    description:
      "reliable whole-app Screen Time blocking, plus experimental Instagram and TikTok network filters.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Rinkler — whole-app blocking, with experimental feed filters",
    description: "reliable whole-app Screen Time blocking, plus experimental Instagram and TikTok network filters.",
  },
  robots: { index: true, follow: true },
};

export const viewport: Viewport = {
  themeColor: "#08080A",
  colorScheme: "dark",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${geist.variable} ${geistMono.variable}`}>
      <head>
        <style
          dangerouslySetInnerHTML={{
            __html: `
              *, *::before, *::after {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
              }
              html, body {
                width: 100%;
                min-height: 100%;
                overflow-x: hidden;
              }
              body {
                background: #08090B;
                color: #F8FAFC;
                font-family: var(--font-geist), system-ui, -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                -webkit-font-smoothing: antialiased;
                text-rendering: optimizeLegibility;
              }
              ::selection { background: rgba(91,124,255,0.35); }
              * { scrollbar-color: #2A2E36 transparent; }
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
