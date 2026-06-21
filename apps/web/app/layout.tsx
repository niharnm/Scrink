import type { Metadata } from "next";

export const metadata: Metadata = {
  metadataBase: new URL("https://rinkler.app"),
  title: "Rinkler — Keep the useful parts.",
  description:
    "Rinkler removes the endless short-video feed without removing the app. Keep your DMs, posts, and search — lose the doomscroll. On-device, private, and honest.",
  openGraph: {
    title: "Rinkler — Keep the useful parts.",
    description:
      "Most blockers lock the whole app, so you turn them off. Rinkler interrupts only the infinite feed — the rest still works.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <style
          dangerouslySetInnerHTML={{
            __html: `
              @font-face {
                font-family: 'Geist';
                src: url('/fonts/Geist-Regular.ttf') format('truetype');
                font-weight: 400; font-style: normal; font-display: swap;
              }
              @font-face {
                font-family: 'Geist';
                src: url('/fonts/Geist-Medium.ttf') format('truetype');
                font-weight: 500; font-style: normal; font-display: swap;
              }
              @font-face {
                font-family: 'Geist';
                src: url('/fonts/Geist-SemiBold.ttf') format('truetype');
                font-weight: 600; font-style: normal; font-display: swap;
              }
              @font-face {
                font-family: 'Geist';
                src: url('/fonts/Geist-Bold.ttf') format('truetype');
                font-weight: 700; font-style: normal; font-display: swap;
              }
              @font-face {
                font-family: 'Geist Mono';
                src: url('/fonts/GeistMono-Regular.ttf') format('truetype');
                font-weight: 400; font-style: normal; font-display: swap;
              }
              @font-face {
                font-family: 'SK Pupok';
                src: url('/fonts/SKPupokSolid.ttf') format('truetype');
                font-weight: 400;
                font-style: normal;
                font-display: swap;
              }
              @font-face {
                font-family: 'Coolvetica';
                src: url('/fonts/CoolveticaRg.otf') format('opentype');
                font-weight: 400;
                font-style: normal;
                font-display: swap;
              }
              @font-face {
                font-family: 'Coolvetica';
                src: url('/fonts/CoolveticaRgIt.otf') format('opentype');
                font-weight: 400;
                font-style: italic;
                font-display: swap;
              }
              *, *::before, *::after {
                box-sizing: border-box;
                margin: 0;
                padding: 0;
              }
              html, body {
                width: 100%;
                height: 100%;
                overflow-x: hidden;
              }
              body {
                font-family: 'Geist', system-ui, -apple-system, sans-serif;
                background: #070B1E;
                color: #fff;
              }
              html { scroll-behavior: smooth; }
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
