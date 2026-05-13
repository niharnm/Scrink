import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Bubble",
  description: "Bubble",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <style
          dangerouslySetInnerHTML={{
            __html: `
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
            `,
          }}
        />
      </head>
      <body>{children}</body>
    </html>
  );
}
