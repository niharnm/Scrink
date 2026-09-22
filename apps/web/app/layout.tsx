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

// This site belongs to the Scrink iOS project. It must not claim the rinkler.app
// domain, which serves a separate referral and loyalty product.
export const metadata: Metadata = {
  title: {
    default: "Scrink — Block distracting apps with Screen Time.",
    template: "%s · Scrink",
  },
  description:
    "Scrink blocks selected whole apps with Screen Time. Optional Instagram and TikTok network filters are experimental and require physical-device testing.",
  applicationName: "Scrink",
  robots: { index: false, follow: false },
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
