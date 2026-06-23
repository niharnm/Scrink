"use client";

import { CSSProperties, ReactNode } from "react";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import HeatmapGrid from "@/components/dashboard/HeatmapGrid";
import Ring from "@/components/dashboard/Ring";
import { theme } from "@/lib/theme";
import { WellbeingData, formatMinutes } from "@/lib/dashboard-v2";

/**
 * Gain-framed dashboard: leads with time reclaimed + wins, in a supportive-friend
 * tone. No raw blocked-request counts, HTTP methods, content types, bandwidth, or
 * CDN domains — those read as a packet sniffer, not "your evenings back".
 */
export default function DashboardViewV2({
  data,
  email,
  onSignOut,
}: {
  data: WellbeingData;
  email?: string;
  onSignOut?: () => void;
}) {
  const goalPct = data.reclaimedGoalMinutes > 0 ? data.reclaimedMinutes / data.reclaimedGoalMinutes : 0;
  const appMax = Math.max(1, ...data.apps.map((a) => a.reclaimedMinutes));
  const weekMax = Math.max(1, ...data.week.map((d) => d.reclaimedMinutes));

  return (
    <SkyBackground>
      <style>{`
        @media (max-width: 860px) {
          .v2-hero { grid-template-columns: 1fr !important; text-align: center; }
          .v2-hero-copy { align-items: center !important; }
          .v2-wins { grid-template-columns: 1fr !important; }
          .v2-2col { grid-template-columns: 1fr !important; }
        }
      `}</style>
      <HeaderBar email={email} onSignOut={onSignOut} />

      <div style={content}>
        <div style={{ marginBottom: theme.spacing.lg }}>
          <div style={greeting}>your time back</div>
          <div style={sub}>what Rinkler quietly handed back to you {data.rangeLabel}.</div>
        </div>

        {/* HERO — minutes reclaimed */}
        <div style={hero} className="v2-hero">
          <div style={heroRingWrap}>
            <Ring percent={goalPct} size={188} stroke={14} gradId="v2hero">
              <div style={{ textAlign: "center" }}>
                <div style={heroNumber}>{formatMinutes(data.reclaimedMinutes)}</div>
                <div style={heroNumberLabel}>reclaimed</div>
              </div>
            </Ring>
          </div>
          <div style={heroCopy} className="v2-hero-copy">
            <div style={heroHeadline}>you got back {formatMinutes(data.reclaimedMinutes)} today.</div>
            <div style={heroRow}>
              {data.reclaimedDeltaPct != null && (
                <Delta value={data.reclaimedDeltaPct} suffix="% vs last week" />
              )}
              <span style={heroGoal}>
                {Math.round(goalPct * 100)}% of your {formatMinutes(data.reclaimedGoalMinutes)} goal
              </span>
            </div>
            <div style={identity}>{data.identityLine}</div>
          </div>
        </div>

        {/* WINS */}
        <div style={wins} className="v2-wins">
          <WinCard
            big={data.feedsClosed.toLocaleString()}
            label="feeds you closed"
            note={
              data.feedsClosedDelta != null && data.feedsClosedDelta > 0
                ? `${data.feedsClosedDelta} more than usual — you stepped away before it pulled you in`
                : "each time, you stepped away before it pulled you in"
            }
          />
          <WinCard
            big={`${data.streakDays}`}
            unit={data.streakDays === 1 ? "day" : "days"}
            label="streak"
            note={
              data.streakFrozen
                ? "frozen — your streak is safe today"
                : `your best is ${data.bestStreak} days. a freeze is ready if you need it.`
            }
          />
          <WinCard
            big={formatMinutes(data.weekReclaimedMinutes)}
            label="back this week"
            note={`your heaviest pull is around ${data.peakWindow.toLowerCase()} — thats where Rinkler works hardest`}
          />
        </div>

        {/* TWO COLUMN: where it tried hardest + your week */}
        <div style={twoCol} className="v2-2col">
          <Card title="where the feed tried hardest" subtitle="time Rinkler gave back, by app">
            <div style={{ display: "flex", flexDirection: "column", gap: 16, marginTop: 6 }}>
              {data.apps.map((a) => (
                <div key={a.slug} style={{ display: "flex", alignItems: "center", gap: 14 }}>
                  <div style={appIcon}>{a.icon}</div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 7 }}>
                      <span style={appName}>{a.name}</span>
                      <span style={appMins}>{formatMinutes(a.reclaimedMinutes)}</span>
                    </div>
                    <div style={barTrack}>
                      <div style={{ ...barFill, width: `${(a.reclaimedMinutes / appMax) * 100}%` }} />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card title="your week" subtitle="minutes you got back each day">
            <div style={weekChart}>
              {data.week.map((d) => (
                <div key={d.label} style={weekCol}>
                  <div style={weekBarVal}>{d.reclaimedMinutes}</div>
                  <div style={weekBarTrack}>
                    <div style={{ ...weekBarFill, height: `${(d.reclaimedMinutes / weekMax) * 100}%` }} />
                  </div>
                  <div style={weekLabel}>{d.label}</div>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* HEATMAP — danger zones, framed gently */}
        <div style={{ marginBottom: theme.spacing.md }}>
          <HeatmapGrid data={data.heatmap} title="when the feed pulls hardest" />
          <div style={heatNote}>your danger zones. Rinkler watches these closest so you dont have to.</div>
        </div>

        {/* ENCOURAGEMENT */}
        <div style={encourageCard}>
          <div style={encourageDot} />
          <div style={{ fontFamily: theme.fonts.body, fontSize: 15.5, lineHeight: 1.6, color: theme.colors.white }}>
            {data.encouragement}
          </div>
        </div>
      </div>
    </SkyBackground>
  );
}

function Delta({ value, suffix }: { value: number; suffix: string }) {
  const up = value >= 0;
  return (
    <span style={{ ...deltaChip, color: up ? theme.colors.white : theme.colors.white60 }}>
      {up ? "↑" : "↓"} {Math.abs(value)}
      {suffix}
    </span>
  );
}

function WinCard({ big, unit, label, note }: { big: string; unit?: string; label: string; note: string }) {
  return (
    <div style={winCard}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
        <span style={winBig}>{big}</span>
        {unit && <span style={winUnit}>{unit}</span>}
      </div>
      <div style={winLabel}>{label}</div>
      <div style={winNote}>{note}</div>
    </div>
  );
}

function Card({ title, subtitle, children }: { title: string; subtitle?: string; children: ReactNode }) {
  return (
    <div style={card}>
      <div style={cardTitle}>{title}</div>
      {subtitle && <div style={cardSub}>{subtitle}</div>}
      {children}
    </div>
  );
}

/* ---------- styles ---------- */
const content: CSSProperties = { maxWidth: 1100, margin: "0 auto", padding: `4px ${theme.spacing.lg}px 140px` };
const greeting: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 30, fontWeight: 700, letterSpacing: "-0.02em", color: theme.colors.white };
const sub: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 15, color: theme.colors.white60, marginTop: 4 };

const hero: CSSProperties = {
  display: "grid",
  gridTemplateColumns: "188px 1fr",
  gap: theme.spacing.xl,
  alignItems: "center",
  padding: `${theme.spacing.xl}px ${theme.spacing.lg}px`,
  background: theme.colors.white10,
  border: `1px solid ${theme.colors.white30}`,
  borderRadius: 20,
  marginBottom: theme.spacing.md,
};
const heroRingWrap: CSSProperties = { display: "flex", justifyContent: "center" };
const heroNumber: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 44, fontWeight: 700, color: theme.colors.white, lineHeight: 1, letterSpacing: "-0.02em" };
const heroNumberLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 11, fontWeight: 600, color: theme.colors.white60, textTransform: "uppercase", letterSpacing: 1.4, marginTop: 6 };
const heroCopy: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 14 };
const heroHeadline: CSSProperties = { fontFamily: theme.fonts.display, fontSize: "clamp(26px, 3.4vw, 38px)", fontWeight: 700, letterSpacing: "-0.025em", color: theme.colors.white, lineHeight: 1.1 };
const heroRow: CSSProperties = { display: "flex", alignItems: "center", gap: 14, flexWrap: "wrap" };
const deltaChip: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 13, fontWeight: 600, padding: "4px 10px", borderRadius: 8, background: theme.colors.white15, border: `1px solid ${theme.colors.white30}` };
const heroGoal: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13.5, color: theme.colors.white60 };
const identity: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 15, color: theme.colors.white60, lineHeight: 1.5 };

const wins: CSSProperties = { display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: theme.spacing.md, marginBottom: theme.spacing.md };
const winCard: CSSProperties = { padding: theme.spacing.lg, background: theme.colors.white10, border: `1px solid ${theme.colors.white30}`, borderRadius: 16 };
const winBig: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 38, fontWeight: 700, color: theme.colors.white, letterSpacing: "-0.02em", lineHeight: 1 };
const winUnit: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 16, color: theme.colors.white60 };
const winLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 14, fontWeight: 600, color: theme.colors.white, marginTop: 10 };
const winNote: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13, color: theme.colors.white60, lineHeight: 1.5, marginTop: 6 };

const twoCol: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: theme.spacing.md, marginBottom: theme.spacing.md, alignItems: "start" };
const card: CSSProperties = { padding: theme.spacing.lg, background: theme.colors.white10, border: `1px solid ${theme.colors.white30}`, borderRadius: 20 };
const cardTitle: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 20, fontWeight: 600, color: theme.colors.white, letterSpacing: "-0.01em" };
const cardSub: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13.5, color: theme.colors.white60, marginTop: 4, marginBottom: 8 };

const appIcon: CSSProperties = { width: 38, height: 38, borderRadius: 10, background: theme.colors.white15, border: `1px solid ${theme.colors.white30}`, display: "flex", alignItems: "center", justifyContent: "center", fontFamily: theme.fonts.mono, fontSize: 12, fontWeight: 600, color: theme.colors.white, flexShrink: 0 };
const appName: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 14.5, color: theme.colors.white };
const appMins: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 13.5, color: theme.colors.white60 };
const barTrack: CSSProperties = { height: 8, borderRadius: 6, background: theme.colors.white10, overflow: "hidden" };
const barFill: CSSProperties = { height: "100%", borderRadius: 6, background: "linear-gradient(90deg, #A8A8AE, #F2F2F4)" };

const weekChart: CSSProperties = { display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 8, height: 168, marginTop: 10 };
const weekCol: CSSProperties = { flex: 1, display: "flex", flexDirection: "column", alignItems: "center", height: "100%" };
const weekBarVal: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 11, color: theme.colors.white60, marginBottom: 6 };
const weekBarTrack: CSSProperties = { flex: 1, width: "100%", maxWidth: 30, display: "flex", alignItems: "flex-end", justifyContent: "center" };
const weekBarFill: CSSProperties = { width: "100%", borderRadius: "6px 6px 2px 2px", background: "linear-gradient(180deg, #F2F2F4, #6f6f74)", minHeight: 4 };
const weekLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 12, color: theme.colors.white60, marginTop: 8 };

const heatNote: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13, color: theme.colors.white60, marginTop: 10, paddingLeft: 4 };

const encourageCard: CSSProperties = { display: "flex", gap: 14, alignItems: "flex-start", padding: theme.spacing.lg, background: theme.colors.white10, border: `1px solid ${theme.colors.white30}`, borderRadius: 16 };
const encourageDot: CSSProperties = { width: 8, height: 8, borderRadius: "50%", background: theme.colors.white, marginTop: 7, flexShrink: 0 };
