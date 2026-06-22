import Link from "next/link";
import type { CSSProperties, ReactNode } from "react";
import { signal } from "@/lib/signal";
import AppShowcase from "./AppShowcase";

/**
 * Rinkler marketing landing — "stark minimal" direction: true black, left-aligned
 * big type, hairline-separated sections, monospace eyebrow labels, a single light
 * button. No glows, no gradients, no colored cards.
 */
export default function Landing({ loggedIn }: { loggedIn: boolean }) {
  const ctaHref = loggedIn ? "/dashboard" : "/login";
  const ctaLabel = loggedIn ? "Open dashboard" : "Get early access";

  return (
    <div style={page}>
      <style dangerouslySetInnerHTML={{ __html: css }} />

      {/* Nav */}
      <header style={nav}>
        <Link href="/" style={wordmark}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/rinkler-mark.png" alt="" width={22} height={22} style={{ display: "block" }} />
          Rinkler
        </Link>
        <nav style={navRight} className="nav-links">
          <a href="#difference" style={navLink}>Why</a>
          <a href="#how" style={navLink}>How</a>
          <Link href="/privacy" style={navLink}>Privacy</Link>
          <Link href="/login" style={navLink}>Log in</Link>
          <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
        </nav>
      </header>

      <main style={main}>
        {/* Hero */}
        <section style={{ ...section, paddingTop: "clamp(96px, 16vh, 200px)", paddingBottom: "clamp(72px, 12vh, 150px)" }}>
          <Eyebrow>Coming to iOS — on-device &amp; private</Eyebrow>
          <h1 style={h1}>
            Your phone isn&apos;t<br className="br-hide" /> the problem.
            <br />
            <span style={{ color: signal.textFaint }}>The infinite scroll is.</span>
          </h1>
          <p style={{ ...lede, marginTop: 28 }}>
            Rinkler interrupts the feeds built to swallow your evenings — Reels,
            TikTok — and leaves everything you actually opened the app for. DMs,
            search, messages: untouched.
          </p>
          <div style={ctaRow}>
            <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
            <a href="#difference" style={textBtn} className="text-btn">Why it&apos;s different →</a>
          </div>
          <p style={micro}>No account needed to try · filters locally, never reads your content</p>
        </section>

        <Rule />

        {/* App showcase */}
        <AppShowcase />

        <Rule />

        {/* The real fight */}
        <section style={section}>
          <Eyebrow>The real fight</Eyebrow>
          <h2 style={h2}>You&apos;re not weak. It&apos;s rigged.</h2>
          <p style={statement}>
            You opened Instagram to answer one message. Forty minutes later
            you&apos;re watching a stranger restore a rusted wrench. That isn&apos;t a
            willpower failure — the feed is tuned by hundreds of engineers and an
            A/B test for every pixel, all pointed at one thing: the next swipe.
          </p>
          <p style={{ ...statement, color: signal.text, marginTop: 20 }}>
            Rinkler evens the odds — at the one layer the feed can&apos;t talk you
            out of.
          </p>
        </section>

        <Rule />

        {/* Scalpel, not a hammer */}
        <section id="difference" style={section}>
          <Eyebrow>Why it&apos;s different</Eyebrow>
          <h2 style={h2}>A scalpel, not a hammer.</h2>
          <p style={{ ...lede, maxWidth: 680, marginTop: 20 }}>
            Most screen-time apps are all-or-nothing. Block Instagram, unblock it
            to send one DM, and you&apos;re back in the feed — so people rage-quit
            blockers within a week. Rinkler cuts only the short-video feed and
            leaves the rest working. Nothing to rage-quit.
          </p>
          <div style={compareGrid} className="compare">
            <div style={{ paddingRight: 32 }}>
              <div style={colLabel}>Blanket blockers</div>
              {compareBad.map((t) => <CompareRow key={t} text={t} good={false} />)}
            </div>
            <div style={{ paddingLeft: 32, borderLeft: `1px solid ${signal.border}` }} className="compare-right">
              <div style={{ ...colLabel, color: signal.text }}>Rinkler</div>
              {compareGood.map((t) => <CompareRow key={t} text={t} good />)}
            </div>
          </div>
        </section>

        <Rule />

        {/* How it works */}
        <section id="how" style={section}>
          <Eyebrow>How it works</Eyebrow>
          <h2 style={h2}>Set it once. It holds the line.</h2>
          <div style={{ marginTop: 40 }}>
            {howSteps.map((s, i) => (
              <div key={s.title} style={stepRow} className="step-row">
                <div style={stepNum}>{String(i + 1).padStart(2, "0")}</div>
                <div style={{ maxWidth: 620 }}>
                  <div style={stepTitle}>{s.title}</div>
                  <div style={stepBody}>{s.body}</div>
                </div>
              </div>
            ))}
          </div>
        </section>

        <Rule />

        {/* Honest by design */}
        <section style={section}>
          <Eyebrow>Honest by design</Eyebrow>
          <h2 style={h2}>No glow, no gimmicks.</h2>
          <div style={featGrid} className="feat-grid">
            {features.map((f) => (
              <div key={f.title}>
                <div style={featTitle}>{f.title}</div>
                <div style={featBody}>{f.body}</div>
              </div>
            ))}
          </div>
        </section>

        <Rule />

        {/* Privacy */}
        <section style={section}>
          <Eyebrow>Privacy by design</Eyebrow>
          <h2 style={{ ...h2, maxWidth: 760 }}>It filters on your device. It never reads your content.</h2>
          <p style={{ ...lede, maxWidth: 640, marginTop: 20 }}>
            The filter runs locally — a private configuration that never routes
            your traffic through a server. It sees where a connection is going and
            how big a stream is, never what&apos;s inside. No messages read,
            nothing stored, nothing sold.
          </p>
          <Link href="/privacy" style={{ ...textBtn, display: "inline-block", marginTop: 24 }} className="text-btn">
            Read the privacy policy →
          </Link>
        </section>

        <Rule />

        {/* Founder note */}
        <section style={section}>
          <Eyebrow>Why I built this</Eyebrow>
          <p style={{ ...quote }}>
            &ldquo;I&apos;d open my phone to answer one text and resurface forty
            minutes later with no idea what I&apos;d even watched. I didn&apos;t
            want to be locked out of Instagram — I just wanted the part that was
            eating me gone, and everything else left alone. Nobody had built that,
            so I did.&rdquo;
          </p>
          <div style={{ ...colLabel, marginTop: 20 }}>— the maker of Rinkler</div>
        </section>

        <Rule />

        {/* Final CTA */}
        <section style={{ ...section, paddingTop: "clamp(80px, 13vh, 160px)", paddingBottom: "clamp(80px, 13vh, 160px)" }}>
          <h2 style={{ ...h2, fontSize: "clamp(34px, 6vw, 64px)" }}>Take back your attention.</h2>
          <p style={{ ...lede, marginTop: 18 }}>Coming to iOS. Get early access and win your first ten quiet minutes.</p>
          <div style={{ ...ctaRow, marginTop: 32 }}>
            <Link href={ctaHref} style={lightBtn} className="light-btn">{ctaLabel}</Link>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer style={footer}>
        <span style={wordmark}>Rinkler</span>
        <div style={footerLinks} className="nav-links">
          <Link href="/privacy" style={navLink}>Privacy</Link>
          <a href="mailto:nihar.manchikalapudi@gmail.com" style={navLink}>Support</a>
          <Link href="/login" style={navLink}>Log in</Link>
        </div>
        <span style={{ color: signal.textFaint, fontFamily: signal.mono, fontSize: 12 }}>© 2026</span>
      </footer>
    </div>
  );
}

function Eyebrow({ children }: { children: ReactNode }) {
  return <div style={eyebrow}>{children}</div>;
}
function Rule() {
  return <div style={{ height: 1, background: signal.border, maxWidth: 1080, margin: "0 auto", width: "100%" }} />;
}
function CompareRow({ text, good }: { text: string; good: boolean }) {
  return (
    <div style={compareRow}>
      <span style={{ ...compareMark, color: good ? signal.accent : signal.textFaint }}>{good ? "→" : "×"}</span>
      <span style={{ fontSize: 15.5, lineHeight: 1.5, color: good ? signal.text : signal.textDim }}>{text}</span>
    </div>
  );
}

const compareBad = [
  "Block the whole app — including the DMs you need",
  "Unblock it for a second, fall right back in",
  "Guilt-trips and lockouts you resent",
  "Quietly deleted within a week",
];
const compareGood = [
  "Cut only the short-video feed",
  "Keep messages, search, and posts working",
  "No shame — just real numbers and quiet wins",
  "Sticks, because there's nothing to rage-quit",
];
const howSteps = [
  { title: "Build your Focus System", body: "Answer a few questions about what pulls you in and when. Rinkler turns them into rules tuned to you — Homework Mode, Night Lock, a clean morning start — before you touch a setting." },
  { title: "Start a Control Session", body: "One tap. Pick Gentle, Focused, or a locked Deep session you can't quit early. Rules also run on a schedule, so the line holds even when the app is closed." },
  { title: "Watch your Signal grow", body: "Real focused time and interrupted feeds add up. Build a streak and see exactly how much scroll you cut — measured, never guessed." },
];
const features = [
  { title: "On-device & private", body: "Filtering happens locally on your phone. Traffic never routes through our servers, and we never read what's inside it." },
  { title: "Surgical, not blunt", body: "It targets the infinite short-video feed specifically — not your whole phone — so the useful parts of every app keep working." },
  { title: "Schedules that hold", body: "Your windows run on time without the app open, so protection is already up when you're most likely to slip." },
  { title: "Real numbers, no shame", body: "Every stat is measured on-device, not estimated. Honest time saved, honest streams interrupted — and no lecture when you slip." },
];

/* ---------- styles ---------- */
const page: CSSProperties = { background: signal.bg, color: signal.text, fontFamily: signal.sans, minHeight: "100vh" };
const main: CSSProperties = { maxWidth: 1080, margin: "0 auto", padding: "0 clamp(20px, 5vw, 40px)" };

const nav: CSSProperties = {
  position: "sticky",
  top: 0,
  zIndex: 10,
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "16px clamp(20px, 5vw, 40px)",
  maxWidth: 1080 + 80,
  margin: "0 auto",
  background: "rgba(8,8,10,0.8)",
  backdropFilter: "blur(10px)",
  borderBottom: `1px solid ${signal.border}`,
};
const wordmark: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 8, fontSize: 17, fontWeight: 600, color: signal.text, textDecoration: "none", letterSpacing: "-0.01em" };
const navRight: CSSProperties = { display: "flex", alignItems: "center", gap: 26 };
const navLink: CSSProperties = { color: signal.textDim, textDecoration: "none", fontSize: 14 };
const lightBtn: CSSProperties = {
  padding: "9px 18px",
  borderRadius: 8,
  background: signal.text,
  color: "#08080A",
  textDecoration: "none",
  fontSize: 14,
  fontWeight: 600,
};

const section: CSSProperties = { padding: "clamp(64px, 10vh, 120px) 0" };
const eyebrow: CSSProperties = {
  fontFamily: signal.mono,
  fontSize: 12,
  letterSpacing: "0.16em",
  textTransform: "uppercase",
  color: signal.textFaint,
  marginBottom: 22,
};
const h1: CSSProperties = {
  fontSize: "clamp(42px, 8vw, 88px)",
  lineHeight: 1.0,
  fontWeight: 600,
  letterSpacing: "-0.04em",
  margin: 0,
  maxWidth: 980,
};
const h2: CSSProperties = {
  fontSize: "clamp(28px, 4.6vw, 48px)",
  lineHeight: 1.04,
  fontWeight: 600,
  letterSpacing: "-0.03em",
  margin: 0,
};
const lede: CSSProperties = { fontSize: "clamp(16px, 1.8vw, 19px)", lineHeight: 1.6, color: signal.textDim, maxWidth: 540, margin: 0 };
const statement: CSSProperties = { fontSize: "clamp(19px, 2.6vw, 26px)", lineHeight: 1.45, color: signal.textDim, maxWidth: 820, margin: "26px 0 0", letterSpacing: "-0.01em" };
const micro: CSSProperties = { fontFamily: signal.mono, fontSize: 12, color: signal.textFaint, marginTop: 22 };

const ctaRow: CSSProperties = { display: "flex", flexWrap: "wrap", alignItems: "center", gap: 22, marginTop: 36 };
const textBtn: CSSProperties = { color: signal.text, textDecoration: "none", fontSize: 15, fontWeight: 500 };

const compareGrid: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 0, marginTop: 44 };
const colLabel: CSSProperties = { fontFamily: signal.mono, fontSize: 12, letterSpacing: "0.12em", textTransform: "uppercase", color: signal.textFaint, marginBottom: 20 };
const compareRow: CSSProperties = { display: "flex", gap: 14, alignItems: "flex-start", padding: "11px 0", borderTop: `1px solid ${signal.border}` };
const compareMark: CSSProperties = { fontFamily: signal.mono, fontSize: 14, lineHeight: 1.55, flexShrink: 0, width: 14 };

const stepRow: CSSProperties = { display: "flex", gap: 32, padding: "26px 0", borderTop: `1px solid ${signal.border}` };
const stepNum: CSSProperties = { fontFamily: signal.mono, fontSize: 14, color: signal.textFaint, paddingTop: 4, width: 36, flexShrink: 0 };
const stepTitle: CSSProperties = { fontSize: 19, fontWeight: 600, color: signal.text, letterSpacing: "-0.01em" };
const stepBody: CSSProperties = { fontSize: 15, lineHeight: 1.6, color: signal.textDim, marginTop: 8 };

const featGrid: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: "40px 56px", marginTop: 44 };
const featTitle: CSSProperties = { fontSize: 17, fontWeight: 600, color: signal.text, marginBottom: 8, letterSpacing: "-0.01em" };
const featBody: CSSProperties = { fontSize: 14.5, lineHeight: 1.6, color: signal.textDim };

const quote: CSSProperties = { fontSize: "clamp(20px, 2.8vw, 28px)", lineHeight: 1.45, color: signal.text, maxWidth: 820, fontWeight: 400, letterSpacing: "-0.01em", margin: "20px 0 0" };

const footer: CSSProperties = {
  maxWidth: 1080,
  margin: "0 auto",
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  flexWrap: "wrap",
  gap: 16,
  padding: "28px clamp(20px, 5vw, 40px)",
  borderTop: `1px solid ${signal.border}`,
};
const footerLinks: CSSProperties = { display: "flex", gap: 24 };

const css = `
  html { scroll-behavior: smooth; }
  .light-btn { transition: opacity 0.15s ease; }
  .light-btn:hover { opacity: 0.85; }
  .text-btn:hover { color: ${signal.textDim}; }
  .nav-links a:hover { color: ${signal.text}; }
  @media (max-width: 720px) {
    .compare { grid-template-columns: 1fr !important; }
    .compare-right { padding-left: 0 !important; border-left: 0 !important; border-top: 1px solid ${signal.border}; padding-top: 28px; margin-top: 8px; }
    .feat-grid { grid-template-columns: 1fr !important; }
    .nav-links a:not(:last-child) { display: none; }
    .br-hide { display: none; }
  }
`;
