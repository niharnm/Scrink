"use client";

import { CSSProperties, useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import DashboardView from "@/components/dashboard/DashboardView";
import { MOCK_DASHBOARD } from "@/lib/mock-dashboard";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

/**
 * Waitlist phase: the user is signed in, but the app/dashboard aren't live yet.
 * Show a blurred teaser of the dashboard behind a "coming soon" overlay, plus
 * the live waitlist count.
 */
export default function WaitlistDashboard({ email }: { email: string }) {
  const router = useRouter();
  const [count, setCount] = useState<number | null>(null);

  useEffect(() => {
    let active = true;
    createClient()
      .rpc("waitlist_count")
      .then(({ data, error }) => {
        if (active && !error && typeof data === "number") setCount(data);
      });
    return () => {
      active = false;
    };
  }, []);

  const signOut = async () => {
    await createClient().auth.signOut();
    router.push("/login");
  };

  return (
    <div style={shell}>
      <div style={blurLayer} aria-hidden>
        <DashboardView data={MOCK_DASHBOARD} range="today" onRangeChange={() => {}} email={email} />
      </div>

      <div style={overlay}>
        <div style={pill}>
          <span style={dot} /> you&apos;re on the list
        </div>
        <h1 style={h1}>your dashboard is coming soon</h1>
        <p style={body}>
          this is a peek at what lands when rinkler drops. once the app is live,
          real numbers from your phone show up right here. we&apos;ll email
          {" "}
          <span style={{ color: signal.text }}>{email}</span> the moment it&apos;s ready.
        </p>

        {count != null && (
          <div style={countWrap}>
            <span style={countNum}>{count.toLocaleString()}</span>
            <span style={countLbl}>{count === 1 ? "person on the waitlist" : "people on the waitlist"}</span>
          </div>
        )}

        <button onClick={signOut} style={signOutBtn} className="wl-signout">sign out</button>
      </div>

      <style>{`.wl-signout:hover { border-color: rgba(255,255,255,0.28); color: #ECECEE; }`}</style>
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
const overlay: CSSProperties = {
  position: "absolute",
  inset: 0,
  display: "flex",
  flexDirection: "column",
  alignItems: "center",
  justifyContent: "center",
  textAlign: "center",
  padding: 24,
  background: "radial-gradient(120% 90% at 50% 45%, rgba(8,8,10,0.72), rgba(8,8,10,0.94))",
  fontFamily: signal.sans,
};
const pill: CSSProperties = {
  display: "inline-flex",
  alignItems: "center",
  gap: 8,
  padding: "7px 14px",
  borderRadius: 999,
  border: `1px solid ${signal.border}`,
  fontFamily: signal.mono,
  fontSize: 12,
  letterSpacing: "0.04em",
  color: signal.textDim,
  marginBottom: 26,
};
const dot: CSSProperties = { width: 7, height: 7, borderRadius: "50%", background: signal.success, boxShadow: `0 0 8px ${signal.success}` };
const h1: CSSProperties = { fontSize: "clamp(30px, 5vw, 52px)", fontWeight: 600, letterSpacing: "-0.03em", margin: 0, color: signal.text };
const body: CSSProperties = { fontSize: "clamp(15px, 1.9vw, 18px)", lineHeight: 1.6, color: signal.textDim, maxWidth: 520, marginTop: 18 };
const countWrap: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center", gap: 6, marginTop: 40 };
const countNum: CSSProperties = { fontFamily: signal.mono, fontSize: "clamp(40px, 7vw, 64px)", fontWeight: 500, color: signal.text, letterSpacing: "-0.02em", lineHeight: 1 };
const countLbl: CSSProperties = { fontFamily: signal.mono, fontSize: 12, letterSpacing: "0.14em", textTransform: "uppercase", color: signal.textFaint };
const signOutBtn: CSSProperties = {
  marginTop: 44,
  padding: "10px 22px",
  borderRadius: 10,
  border: `1px solid ${signal.border}`,
  background: "transparent",
  color: signal.textDim,
  fontFamily: signal.sans,
  fontSize: 14,
  cursor: "pointer",
  transition: "all 0.15s ease",
};
