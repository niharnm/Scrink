import type { CSSProperties, ReactNode } from "react";
import { signal } from "@/lib/signal";

/**
 * "See it on your phone" — high-fidelity mockups of the iOS app's real screens,
 * rendered in the app's own Signal identity (near-black + a single blue→violet
 * accent). Stand-ins until real device captures land with the Mac build; drop
 * <img> screenshots into the frames to swap them in.
 */

// The app's identity (distinct from the stark website palette on purpose).
const app = {
  bg: "#0A0C10",
  card: "#14161A",
  cardRaised: "#1B1E24",
  border: "#2A2E36",
  text: "#F8FAFC",
  dim: "#9CA3AF",
  blue: "#6E8BFF",
  violet: "#8B5CF6",
  success: "#63D297",
  glow: "linear-gradient(135deg, #6E8BFF, #8B5CF6)",
} as const;

export default function AppShowcase() {
  return (
    <section style={section}>
      <h2 style={h2}>a setup that already gets you.</h2>
      <p style={lede}>
        a quick personalized onboarding asks what pulls you in and when, then
        builds a local Focus System. reliable whole-app shields and experimental
        network filters stay clearly separate.
      </p>

      <div style={row} className="phones">
        <Phone label="Onboarding"><OnboardingScreen /></Phone>
        <Phone label="Today"><TodayScreen /></Phone>
        <Phone label="Apps"><AppsScreen /></Phone>
      </div>
    </section>
  );
}

function Phone({ children, label }: { children: ReactNode; label: string }) {
  return (
    <div style={phoneWrap} className="phone">
      <div style={frame}>
        <div style={island} />
        <div style={screen}>{children}</div>
      </div>
      <div style={phoneLabel}>{label}</div>
    </div>
  );
}

/* ----- App screens (faithful CSS renders) ----- */

function TodayScreen() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <div>
        <div style={kicker}>PROTECTION</div>
        <div style={{ fontSize: 19, fontWeight: 700, color: app.text, letterSpacing: "-0.01em" }}>Active</div>
      </div>

      <div style={card}>
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <ScoreRing value={0.62} center={<><div style={{ fontFamily: signal.mono, fontSize: 20, color: app.text }}>62</div><div style={{ fontSize: 8, color: app.dim, letterSpacing: 1 }}>SIGNAL</div></>} />
          <div>
            <div style={{ fontSize: 13, fontWeight: 600, color: app.text }}>Screen Time connected</div>
            <div style={{ fontSize: 11, color: app.dim, lineHeight: 1.4, marginTop: 3 }}>Whole-app shields are available. Network filters remain experimental.</div>
          </div>
        </div>
      </div>

      <div style={{ ...card, background: "rgba(91,124,255,0.10)", borderColor: "rgba(91,124,255,0.4)" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 10, color: app.dim }}>Next window</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: app.text }}>Homework Mode</div>
            <div style={{ fontFamily: signal.mono, fontSize: 10, color: app.dim, marginTop: 2 }}>7:00 – 10:00 PM</div>
          </div>
          <div style={{ width: 26, height: 26, borderRadius: "50%", background: app.glow, display: "flex", alignItems: "center", justifyContent: "center", color: "#fff", fontSize: 11 }}>▶</div>
        </div>
      </div>

      <div style={kicker}>RULES</div>
      <Rule name="Night Lock" time="10:30 PM – 7:00 AM" tag="Locked" />
      <Rule name="School Mode" time="8:00 AM – 3:30 PM" tag="Focused" />

      <div style={{ ...card, display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ width: 7, height: 7, borderRadius: "50%", background: app.success }} />
          <span style={{ fontSize: 12, color: app.text }}>Protection on</span>
        </div>
        <span style={{ fontSize: 11, fontWeight: 600, color: app.text, background: app.cardRaised, padding: "4px 12px", borderRadius: 999 }}>Stop</span>
      </div>
    </div>
  );
}

function AppsScreen() {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
      <div>
        <div style={{ fontSize: 19, fontWeight: 700, color: app.text }}>Apps</div>
        <div style={{ fontSize: 11, color: app.dim, marginTop: 2 }}>Know what each control can actually enforce.</div>
      </div>
      <AppCard name="Whole apps" blocked="Reliable Screen Time shield" kept={["Blocks the full selected app"]} />
      <AppCard name="Instagram" blocked="Reels network filter · experimental" kept={["May affect other Instagram features"]} />
      <AppCard name="TikTok" blocked="Feed network filter · experimental" kept={["May affect most of TikTok"]} />
    </div>
  );
}

// The app's story-mode onboarding: a question chapter whose answers generate
// the user's whole Focus System (matches Onboarding.swift's trapsChapter).
function OnboardingScreen() {
  const traps = [
    { t: "Instagram Reels", on: true },
    { t: "TikTok For You", on: true },
  ];
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 12, height: "100%" }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <ScoreRing size={22} stroke={3} value={0.2} center={null} />
          <span style={{ fontSize: 11, color: app.dim }}>Step 2 of 11</span>
        </div>
        <span style={{ fontSize: 11, color: app.dim }}>Skip</span>
      </div>
      <div style={{ fontSize: 18, fontWeight: 700, color: app.text, lineHeight: 1.15, marginTop: 2 }}>Which parts pull you in the most?</div>
      <div style={{ fontSize: 11.5, color: app.dim, lineHeight: 1.4 }}>These are experimental and require physical-device testing.</div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginTop: 2 }}>
        {traps.map((c) => (
          <div
            key={c.t}
            style={{
              fontSize: 10.5,
              fontWeight: 500,
              textAlign: "center",
              padding: "10px 4px",
              borderRadius: 12,
              color: c.on ? app.text : app.dim,
              background: c.on ? app.cardRaised : app.card,
              border: `1px solid ${c.on ? app.blue : app.border}`,
            }}
          >
            {c.t}
          </div>
        ))}
      </div>
      <div style={{ marginTop: "auto", fontSize: 12, fontWeight: 600, color: "#08090B", background: app.glow, padding: "11px 0", borderRadius: 12, textAlign: "center" }}>Continue</div>
    </div>
  );
}

/* ----- shared bits ----- */

function ScoreRing({ value, size = 60, stroke = 6, center }: { value: number; size?: number; stroke?: number; center: ReactNode }) {
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size}>
        <defs>
          <linearGradient id={`ar${size}`} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={app.blue} />
            <stop offset="100%" stopColor={app.violet} />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} />
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke={`url(#ar${size})`} strokeWidth={stroke} strokeLinecap="round" strokeDasharray={`${value * c} ${c}`} transform={`rotate(-90 ${size / 2} ${size / 2})`} />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>{center}</div>
    </div>
  );
}

function Rule({ name, time, tag }: { name: string; time: string; tag: string }) {
  return (
    <div style={{ ...card, padding: "11px 13px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
        <span style={{ fontSize: 13, fontWeight: 600, color: app.text }}>{name}</span>
        <span style={{ fontSize: 9, fontWeight: 600, color: app.blue, background: "rgba(91,124,255,0.12)", padding: "3px 8px", borderRadius: 999 }}>{tag}</span>
      </div>
      <div style={{ fontFamily: signal.mono, fontSize: 10, color: app.dim, marginTop: 4 }}>{time}</div>
    </div>
  );
}

function AppCard({ name, blocked, kept }: { name: string; blocked: string; kept: string[] }) {
  return (
    <div style={card}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 10 }}>
        <div style={{ width: 22, height: 22, borderRadius: 6, background: app.cardRaised, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 10, fontWeight: 700, color: app.text }}>{name[0]}</div>
        <span style={{ fontSize: 14, fontWeight: 600, color: app.text }}>{name}</span>
      </div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "8px 0", borderTop: `1px solid ${app.border}` }}>
        <span style={{ fontSize: 11.5, color: app.text }}>{blocked}</span>
        <span style={{ width: 30, height: 18, borderRadius: 999, background: app.blue, position: "relative" }}><span style={{ position: "absolute", top: 2, right: 2, width: 14, height: 14, borderRadius: "50%", background: "#fff" }} /></span>
      </div>
      <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginTop: 8 }}>
        {kept.map((k) => (
          <span key={k} style={{ fontSize: 9.5, color: app.dim, border: `1px solid ${app.border}`, padding: "3px 8px", borderRadius: 999 }}>{k}</span>
        ))}
      </div>
    </div>
  );
}

/* ----- styles ----- */
const section: CSSProperties = { padding: "clamp(64px, 10vh, 120px) 0" };
const h2: CSSProperties = { fontSize: "clamp(28px, 4.6vw, 48px)", lineHeight: 1.04, fontWeight: 600, letterSpacing: "-0.03em", margin: 0, maxWidth: 740 };
const lede: CSSProperties = { fontSize: "clamp(16px, 1.8vw, 19px)", lineHeight: 1.6, color: signal.textDim, maxWidth: 560, margin: "20px 0 0" };
const row: CSSProperties = { display: "flex", gap: 28, marginTop: 52, justifyContent: "center", flexWrap: "wrap" };

const phoneWrap: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center", gap: 14 };
const frame: CSSProperties = {
  position: "relative",
  width: 256,
  padding: 9,
  background: "#0A0A0C",
  borderRadius: 42,
  border: "1px solid #25252A",
  boxShadow: "0 30px 70px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.04)",
};
const island: CSSProperties = { position: "absolute", top: 18, left: "50%", transform: "translateX(-50%)", width: 78, height: 20, background: "#000", borderRadius: 999, zIndex: 2 };
const screen: CSSProperties = { background: app.bg, borderRadius: 34, padding: "40px 14px 18px", height: 520, overflow: "hidden" };
const phoneLabel: CSSProperties = { fontFamily: signal.mono, fontSize: 11, letterSpacing: "0.12em", textTransform: "uppercase", color: signal.textFaint };

const card: CSSProperties = { background: app.card, border: `1px solid ${app.border}`, borderRadius: 14, padding: 13 };
const kicker: CSSProperties = { fontFamily: signal.mono, fontSize: 9, letterSpacing: "0.14em", color: app.dim };
