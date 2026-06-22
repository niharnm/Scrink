import type { ReactNode } from "react";
import Link from "next/link";

/** Shared frame for legal pages — readable column over the Living Sky. */
export default function LegalShell({
  title,
  updated,
  children,
}: {
  title: string;
  updated: string;
  children: ReactNode;
}) {
  return (
    <div
      style={{
        maxWidth: 760,
        margin: "0 auto",
        padding: "48px 24px 96px",
        fontFamily: "'Geist', system-ui, sans-serif",
        lineHeight: 1.6,
      }}
    >
      <Link
        href="/"
        style={{ color: "rgba(255,255,255,0.6)", textDecoration: "none", fontSize: 15 }}
      >
        ← Back to Rinkler
      </Link>
      <h1 style={{ fontSize: 40, fontWeight: 700, letterSpacing: "-0.5px", margin: "24px 0 6px" }}>
        {title}
      </h1>
      <div style={{ color: "rgba(255,255,255,0.45)", fontSize: 14, marginBottom: 32 }}>
        Last updated: {updated}
      </div>
      <div className="legalBody" style={{ color: "rgba(255,255,255,0.75)", fontSize: 16 }}>
        {children}
      </div>
      <style
        dangerouslySetInnerHTML={{
          __html: `
            .legalBody h2 { color:#fff; font-size:20px; font-weight:600; margin:28px 0 10px; }
            .legalBody p { margin-bottom:14px; }
            .legalBody ul { margin:0 0 14px 20px; }
            .legalBody li { margin-bottom:8px; }
          `,
        }}
      />
    </div>
  );
}
