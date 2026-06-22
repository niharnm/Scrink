import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";

const geist = Geist({ subsets: ["latin"], variable: "--font-geist", display: "swap" });
const geistMono = Geist_Mono({ subsets: ["latin"], variable: "--font-geist-mono", display: "swap" });

export const metadata: Metadata = {
  title: "Rinkler — Scroll less, keep the useful parts",
  description:
    "Rinkler quietly interrupts Reels and TikTok on your device so you keep the useful parts of your apps and lose the infinite scroll. Private by design.",
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
