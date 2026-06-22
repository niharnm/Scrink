import Link from "next/link";
import type { CSSProperties } from "react";
import { signal } from "@/lib/signal";

/**
 * Public marketing landing page for Rinkler, in the app's "Signal" identity.
 * Server component — no client JS needed; hover/entrance effects are CSS only.
 */
export default function Landing({ loggedIn }: { loggedIn: boolean }) {
  const ctaHref = loggedIn ? "/dashboard" : "/login";
  const ctaLabel = loggedIn ? "Open dashboard" : "Get started";

  return (
    <div style={page}>
      <style dangerouslySetInnerHTML={{ __html: css }} />

      {/* Nav */}
      <header style={nav}>
        <Link href="/" style={wordmark}>
          <span style={dot} />
          Rinkler
        </Link>
        <nav style={navRight} className="nav-links">
          <a href="#how" style={navLink}>How it works</a>
          <a href="#privacy" style={navLink}>Privacy</a>
          <Link href={ctaHref} style={navBtn} className="btn-primary">{ctaLabel}</Link>
        </nav>
      </header>

      {/* Hero */}
      <section style={hero}>
        <div style={glowOrb} aria-hidden />
        <span style={pill} className="fade" data-d="0">Coming to iOS</span>
        <h1 style={h1} className="fade hero-h1" data-d="1">
          Your phone isn&apos;t the problem.
          <br />
          <span style={{ color: signal.textDim }}>The infinite scroll is.</span>
        </h1>
        <p style={lede} className="fade" data-d="2">
          Rinkler quietly interrupts Reels and TikTok — so you keep the useful
          parts of your apps and lose the trap designed to pull you in.
        </p>
        <div style={ctaRow} className="fade" data-d="3">
          <Link href={ctaHref} style={primaryBtn} className="btn-primary">{ctaLabel}</Link>
          <a href="#how" style={ghostBtn} className="btn-ghost">See how it works</a>
        </div>
      </section>

      {/* How it works */}
      <section id="how" style={section}>
        <SectionHeading kicker="HOW IT WORKS" title="Built around you in three steps" />
        <div style={steps} className="grid-3">
          {howSteps.map((s, i) => (
            <div key={s.title} style={card} className="card">
              <div style={stepNum}>{String(i + 1).padStart(2, "0")}</div>
              <h3 style={cardTitle}>{s.title}</h3>
              <p style={cardBody}>{s.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section style={section}>
        <SectionHeading kicker="WHY IT WORKS" title="Sharp, not heavy-handed" />
        <div style={featGrid} className="grid-2">
          {features.map((f) => (
            <div key={f.title} style={card} className="card">
              <div style={featIcon} aria-hidden>{f.icon}</div>
              <h3 style={cardTitle}>{f.title}</h3>
              <p style={cardBody}>{f.body}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Privacy band */}
      <section id="privacy" style={privacyBand}>
        <SectionHeading kicker="PRIVACY BY DESIGN" title="It filters on your device. It never reads your content." center />
        <p style={{ ...lede, textAlign: "center", margin: "0 auto", maxWidth: 640 }}>
          Rinkler uses an on-device filter — a private VPN configuration that
          never routes your traffic to a server. It only looks at where a
          connection is going and how big a stream is, not what&apos;s inside.
          No messages read, no content stored, nothing sold.
        </p>
        <div style={{ textAlign: "center", marginTop: 28 }}>
          <Link href="/privacy" style={ghostBtn} className="btn-ghost">Read the privacy policy</Link>
        </div>
      </section>

      {/* Final CTA */}
      <section style={finalCta}>
        <h2 style={ctaTitle}>Take back your attention.</h2>
        <p style={{ ...lede, textAlign: "center", maxWidth: 520 }}>
          Start with ten minutes and win your first Signal Ring.
        </p>
        <Link href={ctaHref} style={primaryBtn} className="btn-primary">{ctaLabel}</Link>
      </section>

      {/* Footer */}
      <footer style={footer}>
        <div style={{ ...wordmark, fontSize: 18 }}>
          <span style={dot} />
          Rinkler
        </div>
        <div style={footerLinks} className="nav-links">
          <Link href="/privacy" style={navLink}>Privacy</Link>
          <a href="mailto:hello@rinkler.app" style={navLink}>Support</a>
          <Link href="/login" style={navLink}>Log in</Link>
        </div>
        <span style={{ color: signal.textDim, fontSize: 13 }}>© 2026 Rinkler</span>
      </footer>
    </div>
  );
}

function SectionHeading({ kicker, title, center }: { kicker: string; title: string; center?: boolean }) {
  return (
    <div style={{ textAlign: center ? "center" : "left", marginBottom: 36 }}>
      <div style={{ ...kickerStyle, justifyContent: center ? "center" : "flex-start" }}>
        <span style={dot} />
        {kicker}
      </div>
      <h2 style={{ ...h2, maxWidth: center ? 680 : undefined, marginInline: center ? "auto" : undefined }}>{title}</h2>
    </div>
  );
}

const howSteps = [
  {
    title: "Build your Focus System",
    body: "Answer a few questions about what pulls you in and when. Rinkler generates rules tuned to you — Homework Mode, Night Lock, a clean morning start.",
  },
  {
    title: "Start a Control Session",
    body: "One tap. Choose how strict: Gentle, Focused, or a locked Deep session you can't quit early. Your rules also run on a schedule, even when the app is closed.",
  },
  {
    title: "Watch your Signal grow",
    body: "Real focused time and blocked pulls add up. Earn Signal Rings, build streaks, and see exactly how much scroll you cut — no fabricated numbers.",
  },
];

const features = [
  { icon: "◓", title: "On-device & private", body: "Filtering happens locally on your phone. Traffic never routes through our servers and we don't read what's inside it." },
  { icon: "✓", title: "Keep the useful parts", body: "Rinkler cuts the infinite short-video feeds while keeping DMs, search, and messages working. It's not an all-or-nothing block." },
  { icon: "◷", title: "Schedules that hold", body: "Your windows run on time without the app being open, so the line holds when you're most likely to slip." },
  { icon: "◎", title: "Honest numbers", body: "Every stat is measured, not estimated. Real time saved, real streams interrupted — and no shame when you slip." },
];

/* ---------- styles ---------- */

const page: CSSProperties = {
  background: signal.bg,
  color: signal.text,
  fontFamily: signal.sans,
  minHeight: "100vh",
  WebkitFontSmoothing: "antialiased",
};

const nav: CSSProperties = {
  position: "sticky",
  top: 0,
  zIndex: 10,
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "18px clamp(20px, 5vw, 64px)",
  background: "rgba(8,9,11,0.72)",
  backdropFilter: "blur(12px)",
  borderBottom: `1px solid ${signal.border}`,
};

const wordmark: CSSProperties = {
  display: "inline-flex",
  alignItems: "center",
  gap: 10,
  fontSize: 21,
  fontWeight: 700,
  color: signal.text,
  textDecoration: "none",
  letterSpacing: "-0.01em",
};

const dot: CSSProperties = {
  width: 9,
  height: 9,
  borderRadius: "50%",
  background: signal.glow,
  boxShadow: `0 0 12px ${signal.blue}`,
  display: "inline-block",
};

const navRight: CSSProperties = { display: "flex", alignItems: "center", gap: 28 };
const navLink: CSSProperties = { color: signal.textDim, textDecoration: "none", fontSize: 15 };
const navBtn: CSSProperties = {
  padding: "9px 18px",
  borderRadius: 12,
  background: signal.glow,
  color: "#fff",
  textDecoration: "none",
  fontSize: 15,
  fontWeight: 600,
};

const hero: CSSProperties = {
  position: "relative",
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  textAlign: "center",
  padding: "clamp(72px, 13vw, 150px) clamp(20px, 5vw, 64px) clamp(60px, 9vw, 110px)",
  overflow: "hidden",
};

const glowOrb: CSSProperties = {
  position: "absolute",
  top: "-22%",
  left: "50%",
  transform: "translateX(-50%)",
  width: "min(760px, 95vw)",
  height: 520,
  background: "radial-gradient(closest-side, rgba(91,124,255,0.30), rgba(139,92,246,0.10) 55%, transparent 75%)",
  filter: "blur(20px)",
  pointerEvents: "none",
};

const pill: CSSProperties = {
  position: "relative",
  display: "inline-block",
  padding: "6px 14px",
  borderRadius: 999,
  border: `1px solid ${signal.border}`,
  background: signal.card,
  color: signal.textDim,
  fontSize: 13,
  letterSpacing: "0.06em",
  marginBottom: 26,
};

const h1: CSSProperties = {
  position: "relative",
  fontSize: "clamp(38px, 7vw, 76px)",
  lineHeight: 1.04,
  fontWeight: 700,
  letterSpacing: "-0.03em",
  margin: 0,
  maxWidth: 920,
};

const lede: CSSProperties = {
  position: "relative",
  fontSize: "clamp(16px, 2.2vw, 20px)",
  lineHeight: 1.55,
  color: signal.textDim,
  marginTop: 24,
  maxWidth: 620,
};

const ctaRow: CSSProperties = { position: "relative", display: "flex", flexWrap: "wrap", gap: 14, justifyContent: "center", marginTop: 38 };

const primaryBtn: CSSProperties = {
  padding: "15px 30px",
  borderRadius: 14,
  background: signal.glow,
  color: "#fff",
  textDecoration: "none",
  fontSize: 17,
  fontWeight: 600,
  boxShadow: "0 8px 30px rgba(91,124,255,0.35)",
};

const ghostBtn: CSSProperties = {
  padding: "15px 30px",
  borderRadius: 14,
  background: signal.card,
  border: `1px solid ${signal.border}`,
  color: signal.text,
  textDecoration: "none",
  fontSize: 17,
  fontWeight: 600,
};

const section: CSSProperties = { padding: "clamp(56px, 9vw, 110px) clamp(20px, 5vw, 64px)", maxWidth: 1120, margin: "0 auto" };

const kickerStyle: CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 9,
  fontSize: 13,
  fontWeight: 600,
  letterSpacing: "0.1em",
  color: signal.textDim,
  marginBottom: 14,
};

const h2: CSSProperties = { fontSize: "clamp(28px, 4.5vw, 44px)", fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1.1, margin: 0 };

const steps: CSSProperties = { display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 20 };
const featGrid: CSSProperties = { display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 20 };

const card: CSSProperties = {
  background: signal.card,
  border: `1px solid ${signal.border}`,
  borderRadius: 20,
  padding: 28,
};

const stepNum: CSSProperties = { fontFamily: signal.mono, fontSize: 15, color: signal.blue, marginBottom: 16 };
const featIcon: CSSProperties = {
  width: 44,
  height: 44,
  borderRadius: 12,
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  fontSize: 22,
  color: signal.blue,
  background: "rgba(91,124,255,0.12)",
  border: `1px solid ${signal.border}`,
  marginBottom: 18,
};

const cardTitle: CSSProperties = { fontSize: 19, fontWeight: 600, margin: "0 0 8px" };
const cardBody: CSSProperties = { fontSize: 15, lineHeight: 1.6, color: signal.textDim, margin: 0 };

const privacyBand: CSSProperties = {
  padding: "clamp(64px, 10vw, 120px) clamp(20px, 5vw, 64px)",
  background: "radial-gradient(120% 100% at 50% 0%, rgba(91,124,255,0.08), transparent 60%)",
  borderTop: `1px solid ${signal.border}`,
  borderBottom: `1px solid ${signal.border}`,
};

const finalCta: CSSProperties = {
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  gap: 22,
  textAlign: "center",
  padding: "clamp(72px, 11vw, 130px) clamp(20px, 5vw, 64px)",
};

const ctaTitle: CSSProperties = { fontSize: "clamp(30px, 5vw, 52px)", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 };

const footer: CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  flexWrap: "wrap",
  gap: 16,
  padding: "32px clamp(20px, 5vw, 64px)",
  borderTop: `1px solid ${signal.border}`,
};

const footerLinks: CSSProperties = { display: "flex", gap: 24 };

const css = `
  .fade { opacity: 0; transform: translateY(14px); animation: fadeUp 0.6s cubic-bezier(0.22,1,0.36,1) forwards; }
  .fade[data-d="0"] { animation-delay: 0.02s; }
  .fade[data-d="1"] { animation-delay: 0.10s; }
  .fade[data-d="2"] { animation-delay: 0.18s; }
  .fade[data-d="3"] { animation-delay: 0.26s; }
  @keyframes fadeUp { to { opacity: 1; transform: translateY(0); } }
  .card { transition: transform 0.2s ease, border-color 0.2s ease; }
  .card:hover { transform: translateY(-3px); border-color: rgba(91,124,255,0.5); }
  .btn-primary { transition: transform 0.15s ease, box-shadow 0.2s ease, opacity 0.2s ease; }
  .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 10px 36px rgba(91,124,255,0.5); }
  .btn-ghost { transition: border-color 0.2s ease, background 0.2s ease; }
  .btn-ghost:hover { border-color: rgba(91,124,255,0.5); background: #1B1E24; }
  a[href]:hover { color: #F8FAFC; }
  @media (max-width: 860px) { .grid-3 { grid-template-columns: 1fr !important; } }
  @media (max-width: 720px) { .grid-2 { grid-template-columns: 1fr !important; } .nav-links a:not(:last-child) { display: none; } }
  @media (prefers-reduced-motion: reduce) { .fade { animation: none; opacity: 1; transform: none; } }
  html { scroll-behavior: smooth; }
`;
