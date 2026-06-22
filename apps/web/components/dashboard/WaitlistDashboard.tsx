"use client";

import { CSSProperties } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import DashboardView from "@/components/dashboard/DashboardView";
import { MOCK_DASHBOARD } from "@/lib/mock-dashboard";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

/**
 * Waitlist phase: the user is signed in, but the app/dashboard aren't live yet.
 * Show a blurred teaser of the dashboard behind a "coming soon" overlay.
 */
export default function WaitlistDashboard({ email }: { email: string }) {
  const router = useRouter();

  const signOut = async () => {
    await createClient().auth.signOut();
    router.push("/login");
  };

  return (
    <div style={shell}>
      <div style={blurLayer} aria-hidden>
        <DashboardView data={MOCK_DASHBOARD} range="today" onRangeChange={() => {}} email={email} />
      </div>

      <div style={topBar}>
        <Link href="/" style={topLink} className="wl-link">← back</Link>
        <button onClick={signOut} style={topLink} className="wl-link">sign out</button>
      </div>

      <div style={overlay}>
        <h1 style={h1}>your dashboard is coming soon</h1>
        <p style={body}>
          this is a peek at what lands when Rinkler drops. once the app is live,
          real numbers from your phone show up right here. we&apos;ll email{" "}
          <span style={{ color: signal.text }}>{email}</span> the moment it&apos;s ready.
        </p>
      </div>

      <style>{`.wl-link:hover { color: #ECECEE; }`}</style>
    </div>
  );
}

const shell: CSSProperties = {
  position: "fixed",
  inset: 0,
  overflow: "hidden",
  background: signal.bg,
};
const blurLayer: CSSProperties = {
  filter: "blur(7px) saturate(0.85)",
  opacity: 0.5,
  pointerEvents: "none",
  userSelect: "none",
  transform: "scale(1.03)",
};
const topBar: CSSProperties = {
  position: "absolute",
  top: 0,
  left: 0,
  right: 0,
  zIndex: 2,
  display: "flex",
  alignItems: "center",
  justifyContent: "space-between",
  padding: "18px clamp(18px, 5vw, 40px)",
};
const topLink: CSSProperties = {
  background: "none",
  border: "none",
  cursor: "pointer",
  color: signal.textDim,
  textDecoration: "none",
  fontFamily: signal.sans,
  fontSize: 14,
  padding: 0,
  transition: "color 0.15s ease",
};
const overlay: CSSProperties = {
  position: "absolute",
  inset: 0,
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  textAlign: "center",
  padding: "24px clamp(20px, 6vw, 40px)",
  background: "radial-gradient(120% 90% at 50% 45%, rgba(8,8,10,0.72), rgba(8,8,10,0.94))",
  fontFamily: signal.sans,
};
const h1: CSSProperties = { fontSize: "clamp(28px, 7vw, 52px)", fontWeight: 600, letterSpacing: "-0.03em", margin: 0, color: signal.text, lineHeight: 1.05 };
const body: CSSProperties = { fontSize: "clamp(14px, 4vw, 18px)", lineHeight: 1.6, color: signal.textDim, maxWidth: 520, marginTop: 18 };
