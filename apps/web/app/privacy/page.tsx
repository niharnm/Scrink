import Link from "next/link";
import type { CSSProperties } from "react";
import type { Metadata } from "next";
import { signal } from "@/lib/signal";

export const metadata: Metadata = {
  title: "Privacy Policy — Rinkler",
  description: "How Rinkler handles your data: on-device filtering, minimal metadata, no content, no selling.",
};

const CONTACT = "nihar.manchikalapudi@gmail.com";
const EFFECTIVE = "June 2026";

export default function PrivacyPage() {
  return (
    <div style={page}>
      <header style={nav}>
        <Link href="/" style={wordmark}>
          <span style={dot} />
          Rinkler
        </Link>
        <Link href="/" style={navLink}>← Home</Link>
      </header>

      <main style={main}>
        <h1 style={h1}>Privacy Policy</h1>
        <p style={meta}>Effective {EFFECTIVE}</p>

        <p style={lead}>
          This explains what Rinkler collects, why, and what we don&apos;t do.
          Rinkler is a personal focus tool that filters short-video traffic on
          your device to help you scroll less. We wrote this to be readable, not
          to hide things — if anything is unclear, email{" "}
          <a href={`mailto:${CONTACT}`} style={inlineLink}>{CONTACT}</a>.
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
          Questions or data requests:{" "}
          <a href={`mailto:${CONTACT}`} style={inlineLink}>{CONTACT}</a>.
        </p>
      </main>

      <footer style={footer}>
        <span style={{ color: signal.textDim, fontSize: 13 }}>© 2026 Rinkler</span>
        <Link href="/" style={navLink}>Home</Link>
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
        "Rinkler filters traffic locally on your device using a private VPN configuration. Your traffic is not routed through our servers.",
        "We do not read the contents of your messages, posts, photos, or the pages you visit.",
        "To show your dashboard and sync settings, we store a small amount of metadata about blocked connections (destination hostnames, byte counts, timestamps, block status), tied to your account.",
        "We use Supabase (database + auth) and Apple / Google sign-in. We do not sell your data or use it for ads.",
        "If you turn on Automatic Mode, Rinkler reads a few Apple Health metrics on your device only — they're never sent to us or anyone else.",
      ],
    ],
  },
  {
    title: "How the on-device filter works",
    body: [
      "Rinkler installs a local VPN configuration (an Apple Network Extension). iOS requires your explicit permission to add it. Although it uses the VPN permission, Rinkler is not a traditional VPN — it does not send your traffic to a remote server or hide your IP address.",
      "The filter only inspects connection metadata (such as the destination hostname and the size of a stream) to decide whether to interrupt short-video traffic. It does not decrypt, read, or store the contents of your connections.",
    ],
  },
  {
    title: "What we collect",
    body: [
      "Account information — your email address and a user ID when you sign in (email code, Apple, or Google). If you use Apple's Hide My Email, we only ever see the relay address.",
      "Usage metadata — when protection is on, tied to your account:",
      [
        "Destination hostnames and a coarse category (e.g. \"short-video\")",
        "Block/allow status and byte counts",
        "Timestamps of blocked/allowed connections",
        "Aggregate summaries (counts and time saved)",
      ],
      "Focus settings — your rules, schedules, strictness, streaks, and session history (stored on your device and, if signed in, synced to your account).",
      "Health data (only if you turn on Automatic Mode) — with your permission, Rinkler reads Apple Health metrics like heart-rate variability, resting heart rate, and activity (steps, exercise, Move) to spot stressed or low-movement moments and tighten your limits on their own. This is processed entirely on your device; raw health data is never uploaded, never sent to our servers, and never leaves your phone. Only a derived baseline is kept locally. You can turn it off any time in Settings or revoke access in the Health app.",
      "We do NOT collect the contents of your traffic, messages, posts, photos, browsing, full URLs, request bodies, packet contents, your location, contacts, microphone, or camera.",
    ],
  },
  {
    title: "Who we share it with",
    body: [
      "Supabase — hosts our database and handles authentication. Apple — Sign in with Apple and the App Store. Google — only if you choose \"Continue with Google\". We do not share data with advertisers or data brokers, and we do not sell it.",
      "Optional AI insights (off by default): Rinkler can generate written insights from your aggregate dashboard stats using a third-party AI provider. This is disabled by default and only runs if you explicitly opt in; only aggregate numbers, never raw events or content, are sent.",
    ],
  },
  {
    title: "Retention & deletion",
    body: [
      "Usage metadata is retained to show your history and is bounded over time. You can permanently delete your account and all its data right in the app — Settings → Account → Request account deletion (we email you a code to confirm) — or by emailing us. Deleting the app removes on-device data (rules, history, the VPN configuration).",
    ],
  },
  {
    title: "Security",
    body: [
      "Auth tokens are stored in the iOS Keychain. Connections to our backend use HTTPS/TLS. Database access is restricted per-user with row-level security, so you can only read your own data.",
    ],
  },
  {
    title: "Children",
    body: [
      "Rinkler is not directed to children under 13 (or the minimum age in your country). If you believe a child under that age has provided us personal information, contact us and we will delete it.",
    ],
  },
  {
    title: "Your rights",
    body: [
      "Depending on where you live, you may have rights to access, correct, export, or delete your personal data, and to object to certain processing. Email us to exercise any of these. We don't discriminate against you for doing so.",
    ],
  },
  {
    title: "Changes",
    body: [
      "If we make material changes, we'll update the effective date and, where appropriate, notify you in the app. Continued use after changes means you accept the updated policy.",
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
const wordmark: CSSProperties = { display: "inline-flex", alignItems: "center", gap: 10, fontSize: 21, fontWeight: 700, color: signal.text, textDecoration: "none", letterSpacing: "-0.01em" };
const dot: CSSProperties = { width: 9, height: 9, borderRadius: "50%", background: signal.glow, boxShadow: `0 0 12px ${signal.blue}`, display: "inline-block" };
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
