import Link from "next/link";
import type { CSSProperties } from "react";
import type { Metadata } from "next";
import { signal } from "@/lib/signal";

export const metadata: Metadata = {
  title: "Terms of Service — Rinkler",
  description: "The terms for using Rinkler.",
};

const CONTACT = "nihar.manchikalapudi@gmail.com";
const EFFECTIVE = "June 2026";

export default function TermsPage() {
  return (
    <div style={page}>
      <header style={nav}>
        <Link href="/" style={wordmark}>
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img src="/rinkler-mark.png" alt="" width={22} height={22} style={{ display: "block" }} />
          Rinkler
        </Link>
        <Link href="/" style={navLink}>← home</Link>
      </header>

      <main style={main}>
        <h1 style={h1}>Terms of Service</h1>
        <p style={meta}>Effective {EFFECTIVE}</p>

        <p style={lead}>
          These terms cover your use of Rinkler. By using the app or this site
          you agree to them. If you don&apos;t agree, please don&apos;t use Rinkler.
          Questions? Email <a href={`mailto:${CONTACT}`} style={inlineLink}>{CONTACT}</a>.
        </p>

        {sections.map((s) => (
          <section key={s.title} style={{ marginTop: 36 }}>
            <h2 style={h2}>{s.title}</h2>
            {s.body.map((b, i) =>
              typeof b === "string" ? (
                <p key={i} style={para}>{b}</p>
              ) : (
                <ul key={i} style={list}>
                  {b.map((item) => (
                    <li key={item} style={li}>{item}</li>
                  ))}
                </ul>
              )
            )}
          </section>
        ))}

        <p style={{ ...para, marginTop: 40, color: signal.textDim }}>
          Questions about these terms? Email{" "}
          <a href={`mailto:${CONTACT}`} style={inlineLink}>{CONTACT}</a>.
        </p>
      </main>

      <footer style={footer}>
        <span style={{ color: signal.textFaint, fontSize: 13 }}>© 2026 Rinkler</span>
        <div style={{ display: "flex", gap: 20 }}>
          <Link href="/privacy" style={navLink}>privacy</Link>
          <Link href="/" style={navLink}>home</Link>
        </div>
      </footer>
    </div>
  );
}

type Block = string | string[];
const sections: { title: string; body: Block[] }[] = [
  {
    title: "The short version",
    body: [
      [
        "Rinkler is a personal focus tool with reliable whole-app Screen Time shields and optional experimental network filters.",
        "Instagram Reels and TikTok filtering are best-effort, require a physical-device test, and may affect more than the intended feed.",
        "Use it for yourself, don't abuse it, and you're responsible for your own device and choices.",
        "We provide it as-is, and we're not liable for indirect damages. These terms can change.",
      ],
    ],
  },
  {
    title: "What Rinkler is",
    body: [
      "Rinkler can shield selected whole apps through Apple's Screen Time controls. Its separate Instagram and TikTok network filters inspect connection metadata on device and are experimental. Rinkler is not antivirus, parental-control certification, or a content-security guarantee.",
    ],
  },
  {
    title: "Who can use it",
    body: [
      "You need to be at least 13 (or the minimum age in your country). If you're under 18, you should have a parent or guardian's permission to use Rinkler.",
    ],
  },
  {
    title: "Your account",
    body: [
      "You can sign in with email, Apple, or Google. You're responsible for keeping access to your account secure and for activity under it. Tell us if you think someone else is using it.",
    ],
  },
  {
    title: "Acceptable use",
    body: [
      "Please don't:",
      [
        "use Rinkler to break the law or harm others",
        "reverse engineer, resell, or rent the app, or try to bypass its limits in bad faith",
        "interfere with the service or other people's use of it",
        "use it to filter or monitor someone else's device without their knowledge and consent",
      ],
    ],
  },
  {
    title: "The filter is best-effort",
    body: [
      "Rinkler's network filters can reduce or interrupt Instagram and TikTok traffic, but they can't guarantee feed-only blocking. Platforms change, some traffic may slip through, and shared hosts can cause useful features to be interrupted. Whole-app Screen Time shields are the reliable option when Screen Time access is approved.",
    ],
  },
  {
    title: "Early access, changes, and pricing",
    body: [
      "Rinkler is in early access. Features may change, break, or go away while we build it. If paid plans are introduced, the price and terms will be shown before you buy, and any purchases made through the App Store are handled and billed by Apple under their terms.",
    ],
  },
  {
    title: "Our content",
    body: [
      "Rinkler, its name, design, and software are owned by us. You get a personal, limited, non-transferable license to use the app for its intended purpose. You don't get any rights beyond that.",
    ],
  },
  {
    title: "No warranty",
    body: [
      "Rinkler is provided \"as is\" and \"as available,\" without warranties of any kind, to the extent allowed by law. We don't promise it will be uninterrupted, error-free, or that it will block any specific content.",
    ],
  },
  {
    title: "Limitation of liability",
    body: [
      "To the extent allowed by law, Rinkler and its maker are not liable for any indirect, incidental, or consequential damages, or for time spent, content seen, or habits formed while using (or not using) the app. Our total liability is limited to what you paid us in the last 12 months, which during early access is likely nothing.",
    ],
  },
  {
    title: "Termination",
    body: [
      "You can stop using Rinkler and delete your account at any time. We may suspend or end access if these terms are broken, or if we need to stop offering the service.",
    ],
  },
  {
    title: "Changes to these terms",
    body: [
      "We may update these terms as Rinkler evolves. If the changes are material, we'll update the effective date and, where appropriate, let you know in the app. Continuing to use Rinkler after changes means you accept them.",
    ],
  },
  {
    title: "Contact",
    body: [
      `Reach out any time at ${CONTACT}.`,
    ],
  },
];

/* ---------- styles ---------- */
const page: CSSProperties = { background: signal.bg, color: signal.text, fontFamily: signal.sans, minHeight: "100vh", WebkitFontSmoothing: "antialiased" };
const nav: CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "18px clamp(20px, 5vw, 64px)",
  borderBottom: `1px solid ${signal.border}`,
};
const wordmark: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 8, fontSize: 18, fontWeight: 600, color: signal.text, textDecoration: "none", letterSpacing: "-0.01em" };
const navLink: CSSProperties = { color: signal.textDim, textDecoration: "none", fontSize: 15 };
const main: CSSProperties = { maxWidth: 760, margin: "0 auto", padding: "clamp(40px, 7vw, 72px) clamp(20px, 5vw, 40px)" };
const h1: CSSProperties = { fontSize: "clamp(32px, 5vw, 48px)", fontWeight: 700, letterSpacing: "-0.02em", margin: 0 };
const meta: CSSProperties = { color: signal.textDim, fontSize: 14, marginTop: 8 };
const lead: CSSProperties = { fontSize: 17, lineHeight: 1.6, color: signal.textDim, marginTop: 28 };
const h2: CSSProperties = { fontSize: 22, fontWeight: 600, letterSpacing: "-0.01em", margin: "0 0 12px" };
const para: CSSProperties = { fontSize: 15.5, lineHeight: 1.65, color: signal.textDim, margin: "0 0 12px" };
const list: CSSProperties = { margin: "0 0 12px", paddingLeft: 22 };
const li: CSSProperties = { fontSize: 15.5, lineHeight: 1.6, color: signal.textDim, marginBottom: 6 };
const inlineLink: CSSProperties = { color: signal.blue, textDecoration: "none" };
const footer: CSSProperties = {
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "28px clamp(20px, 5vw, 64px)",
  borderTop: `1px solid ${signal.border}`,
};
