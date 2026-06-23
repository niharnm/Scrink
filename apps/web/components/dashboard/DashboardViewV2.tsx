"use client";

import { CSSProperties, ReactNode } from "react";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import { theme } from "@/lib/theme";
import { WellbeingData, formatMinutes } from "@/lib/dashboard-v2";

/* color — the dashboard is dark but no longer black-and-white. */
const C = {
  text: "#F2F2F4",
  dim: "rgba(255,255,255,0.56)",
  faint: "rgba(255,255,255,0.34)",
  card: "rgba(255,255,255,0.025)",
  cardBorder: "rgba(255,255,255,0.08)",
  track: "rgba(255,255,255,0.07)",
  blue: "#6E8BFF",
  violet: "#A77BFF",
  cyan: "#3FD6C2",
  green: "#54D27E",
  amber: "#FFB259",
};
const APP_COLOR: Record<string, string> = {
  instagram: "#E1559B",
  tiktok: "#3FD6C2",
  youtube: "#FF6B6B",
  reddit: "#FF8A4C",
  snapchat: "#FFC83D",
  x: "#8AA0FF",
};
const TOD_COLOR = [C.cyan, C.blue, C.violet, "#7B6BFF"];

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
  const todMax = Math.max(1, ...data.timeOfDay.map((t) => t.minutes));

  return (
    <SkyBackground>
      <style>{`
        @media (max-width: 880px) {
          .v2-hero { grid-template-columns: 1fr !important; justify-items: center; text-align: center; }
          .v2-hero-copy { align-items: center !important; }
          .v2-strip { grid-template-columns: 1fr 1fr !important; }
          .v2-2col { grid-template-columns: 1fr !important; }
        }
      `}</style>
      <HeaderBar email={email} onSignOut={onSignOut} />

      <div style={content}>
        <div style={{ marginBottom: theme.spacing.lg }}>
          <div style={greeting}>your time back</div>
          <div style={sub}>{data.headline}</div>
        </div>

        {/* HERO */}
        <div style={hero} className="v2-hero">
          <ColorRing percent={goalPct} size={184} stroke={14}>
            <div style={{ textAlign: "center" }}>
              <div style={heroNumber}>{formatMinutes(data.reclaimedMinutes)}</div>
              <div style={heroNumberLabel}>reclaimed</div>
            </div>
          </ColorRing>
          <div style={heroCopy} className="v2-hero-copy">
            <div style={heroHeadline}>you got back {formatMinutes(data.reclaimedMinutes)} today.</div>
            <div style={heroRow}>
              {data.reclaimedDeltaPct != null && <Delta value={data.reclaimedDeltaPct} suffix="% vs last week" />}
              <span style={heroGoal}>
                {data.reclaimedMinutes} of {data.reclaimedGoalMinutes} min goal
              </span>
            </div>
            <div style={heroSub}>
              {data.bestDay.minutes > 0
                ? `best day this week was ${data.bestDay.label} with ${formatMinutes(data.bestDay.minutes)} back.`
                : "first day of the count. lets see where it goes."}
            </div>
          </div>
        </div>

        {/* HIGHLIGHT STRIP */}
        <div style={strip} className="v2-strip">
          <Stat
            color={C.blue}
            big={data.feedsClosed.toLocaleString()}
            label="feeds closed"
            note={
              data.feedsClosedDelta && data.feedsClosedDelta > 0
                ? `you backed out before it pulled you in, ${data.feedsClosedDelta} more than usual.`
                : "you backed out before it pulled you in."
            }
          />
          <Stat
            color={C.amber}
            big={`${data.streakDays}`}
            unit={data.streakDays === 1 ? "day" : "days"}
            label="streak"
            note={data.streakFrozen ? "frozen, your streak is safe today." : `your best is ${data.bestStreak}. miss a day? you can freeze it.`}
          />
          <Stat color={C.green} big={formatMinutes(data.weekReclaimedMinutes)} label="back this week" note={`about ${formatMinutes(data.dailyAvgMinutes)} a day.`} />
          <Stat color={C.violet} big={formatMinutes(data.monthReclaimedMinutes)} label="back this month" note="adds up faster than you'd think." />
        </div>

        {/* WEEK CHART */}
        <div style={{ ...card, marginBottom: theme.spacing.md }}>
          <div style={cardTitle}>your week</div>
          <div style={cardSub}>minutes back each day. faded line is last week.</div>
          <AreaChart week={data.week} lastWeek={data.lastWeek} />
        </div>

        {/* TWO COLUMN */}
        <div style={twoCol} className="v2-2col">
          <div style={card}>
            <div style={cardTitle}>when you got it back</div>
            <div style={cardSub}>the times rinkler did the most work</div>
            <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", gap: 10, height: 150, marginTop: 14 }}>
              {data.timeOfDay.map((t, i) => (
                <div key={t.label} style={todCol}>
                  <div style={{ ...todVal, color: TOD_COLOR[i % TOD_COLOR.length] }}>{formatMinutes(t.minutes)}</div>
                  <div style={todTrack}>
                    <div
                      style={{
                        width: "100%",
                        height: `${(t.minutes / todMax) * 100}%`,
                        minHeight: 5,
                        borderRadius: "7px 7px 3px 3px",
                        background: `linear-gradient(180deg, ${TOD_COLOR[i % TOD_COLOR.length]}, ${TOD_COLOR[i % TOD_COLOR.length]}44)`,
                      }}
                    />
                  </div>
                  <div style={todLabel}>{t.label}</div>
                </div>
              ))}
            </div>
          </div>

          <div style={card}>
            <div style={cardTitle}>what tried hardest to keep you scrolling</div>
            <div style={cardSub}>time back, by app</div>
            <div style={{ display: "flex", flexDirection: "column", gap: 15, marginTop: 14 }}>
              {data.apps.map((a) => {
                const col = APP_COLOR[a.slug] ?? C.blue;
                return (
                  <div key={a.slug} style={{ display: "flex", alignItems: "center", gap: 13 }}>
                    <div style={{ ...appIcon, color: col, borderColor: `${col}66`, background: `${col}1a` }}>{a.icon}</div>
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 7, alignItems: "baseline" }}>
                        <span style={appName}>{a.name}</span>
                        <span style={appMins}>
                          {formatMinutes(a.reclaimedMinutes)} <span style={{ color: C.faint }}>· {a.feedsClosed} closes</span>
                        </span>
                      </div>
                      <div style={barTrack}>
                        <div style={{ height: "100%", borderRadius: 6, width: `${(a.reclaimedMinutes / appMax) * 100}%`, background: `linear-gradient(90deg, ${col}99, ${col})` }} />
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </div>

        {/* HEATMAP */}
        <div style={{ ...card, marginBottom: theme.spacing.md }}>
          <div style={cardTitle}>when the feed usually gets you</div>
          <div style={cardSub}>the bright cells are when the feed pulls hardest, so rinkler leans in</div>
          <Heatmap data={data.heatmap} />
        </div>

        {/* ENCOURAGEMENT */}
        <div style={encourage}>
          <div style={{ ...encourageBar }} />
          <div style={{ fontFamily: theme.fonts.body, fontSize: 15.5, lineHeight: 1.6, color: C.text }}>{data.encouragement}</div>
        </div>
      </div>
    </SkyBackground>
  );
}

/* ---------- subcomponents ---------- */

function ColorRing({ percent, size, stroke, children }: { percent: number; size: number; stroke: number; children: ReactNode }) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = Math.max(0.0001, Math.min(1, percent)) * circ;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size}>
        <defs>
          <linearGradient id="v2ring" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={C.cyan} />
            <stop offset="55%" stopColor={C.blue} />
            <stop offset="100%" stopColor={C.violet} />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.08)" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="url(#v2ring)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${dash} ${circ}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>{children}</div>
    </div>
  );
}

function Delta({ value, suffix }: { value: number; suffix: string }) {
  const up = value >= 0;
  const col = up ? C.green : "#FF8080";
  return (
    <span style={{ fontFamily: theme.fonts.mono, fontSize: 13, fontWeight: 600, color: col, padding: "4px 10px", borderRadius: 8, background: `${col}1f`, border: `1px solid ${col}33` }}>
      {up ? "↑" : "↓"} {Math.abs(value)}
      {suffix}
    </span>
  );
}

function Stat({ color, big, unit, label, note }: { color: string; big: string; unit?: string; label: string; note: string }) {
  return (
    <div style={{ ...card, padding: theme.spacing.lg }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 5 }}>
        <span style={{ ...statBig, color }}>{big}</span>
        {unit && <span style={statUnit}>{unit}</span>}
      </div>
      <div style={statLabel}>{label}</div>
      <div style={statNote}>{note}</div>
    </div>
  );
}

function AreaChart({ week, lastWeek }: { week: { label: string; reclaimedMinutes: number }[]; lastWeek: number[] }) {
  const W = 720, H = 240, padX = 16, padT = 30, padB = 26;
  const innerW = W - padX * 2;
  const innerH = H - padT - padB;
  const n = week.length;
  const showCompare = lastWeek.some((v) => v > 0);
  const max = Math.max(1, ...week.map((d) => d.reclaimedMinutes), ...(showCompare ? lastWeek : []));
  const baseY = padT + innerH;
  const px = (i: number) => padX + (n <= 1 ? innerW / 2 : (i / (n - 1)) * innerW);
  const py = (v: number) => padT + innerH - (v / max) * innerH;
  const pts = week.map((d, i) => ({ x: px(i), y: py(d.reclaimedMinutes), v: d.reclaimedMinutes }));
  const cmp = lastWeek.map((v, i) => ({ x: px(i), y: py(v) }));

  const smooth = (p: { x: number; y: number }[]) => {
    if (!p.length) return "";
    let d = `M ${p[0].x.toFixed(1)},${p[0].y.toFixed(1)}`;
    for (let i = 1; i < p.length; i++) {
      const cx = ((p[i - 1].x + p[i].x) / 2).toFixed(1);
      d += ` C ${cx},${p[i - 1].y.toFixed(1)} ${cx},${p[i].y.toFixed(1)} ${p[i].x.toFixed(1)},${p[i].y.toFixed(1)}`;
    }
    return d;
  };

  const line = smooth(pts);
  const area = `${line} L ${pts[n - 1].x.toFixed(1)},${baseY} L ${pts[0].x.toFixed(1)},${baseY} Z`;
  const peakIdx = pts.reduce((m, p, i) => (p.v > pts[m].v ? i : m), 0);

  return (
    <svg viewBox={`0 0 ${W} ${H}`} style={{ width: "100%", height: "auto", display: "block", marginTop: 6 }}>
      <defs>
        <linearGradient id="v2area" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={C.blue} stopOpacity="0.42" />
          <stop offset="100%" stopColor={C.blue} stopOpacity="0" />
        </linearGradient>
        <linearGradient id="v2line" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor={C.cyan} />
          <stop offset="100%" stopColor={C.violet} />
        </linearGradient>
      </defs>
      {[0.25, 0.5, 0.75].map((g) => (
        <line key={g} x1={padX} x2={W - padX} y1={padT + innerH * g} y2={padT + innerH * g} stroke="rgba(255,255,255,0.06)" strokeWidth={1} />
      ))}
      <line x1={padX} x2={W - padX} y1={baseY} y2={baseY} stroke="rgba(255,255,255,0.12)" strokeWidth={1} />
      <path d={area} fill="url(#v2area)" />
      {showCompare && <path d={smooth(cmp)} fill="none" stroke="rgba(255,255,255,0.28)" strokeWidth={2} strokeDasharray="3 5" />}
      <path d={line} fill="none" stroke="url(#v2line)" strokeWidth={3} strokeLinecap="round" />
      {pts.map((p, i) => (
        <circle key={i} cx={p.x} cy={p.y} r={i === peakIdx ? 5 : 3.2} fill={i === peakIdx ? C.violet : C.blue} stroke="#0A0A0B" strokeWidth={1.5} />
      ))}
      <text x={pts[peakIdx].x} y={pts[peakIdx].y - 12} textAnchor="middle" fill={C.text} fontSize="13" fontFamily={theme.fonts.mono} fontWeight={600}>
        {pts[peakIdx].v}m
      </text>
      {week.map((d, i) => (
        <text key={d.label} x={px(i)} y={H - 7} textAnchor="middle" fill={C.dim} fontSize="12" fontFamily={theme.fonts.body}>
          {d.label}
        </text>
      ))}
    </svg>
  );
}

function Heatmap({ data }: { data: number[][] }) {
  const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const HOURS = Array.from({ length: 24 }, (_, i) => (i === 0 ? "12a" : i < 12 ? `${i}a` : i === 12 ? "12p" : `${i - 12}p`));
  const stops = [[18, 20, 28], [56, 78, 180], [132, 92, 210], [233, 96, 152]];
  const heatColor = (v: number) => {
    const t = Math.max(0, Math.min(1, v)) * (stops.length - 1);
    const i = Math.floor(t), f = t - i;
    const a = stops[i], b = stops[Math.min(stops.length - 1, i + 1)];
    const c = a.map((x, k) => Math.round(x + (b[k] - x) * f));
    return `rgb(${c[0]},${c[1]},${c[2]})`;
  };
  return (
    <div style={{ overflowX: "auto", marginTop: 12 }}>
      <div style={{ display: "grid", gridTemplateColumns: `38px repeat(24, 1fr)`, gap: 3, minWidth: 540 }}>
        <div />
        {HOURS.map((h, i) => (
          <div key={i} style={{ fontFamily: theme.fonts.body, fontSize: 10, color: C.faint, textAlign: "center", paddingBottom: 3 }}>
            {i % 3 === 0 ? h : ""}
          </div>
        ))}
        {DAYS.map((day, di) => (
          <div key={day} style={{ display: "contents" }}>
            <div style={{ fontFamily: theme.fonts.body, fontSize: 12, color: C.dim, display: "flex", alignItems: "center", paddingRight: 6 }}>{day}</div>
            {Array.from({ length: 24 }).map((_, hi) => (
              <div
                key={hi}
                title={`${day} ${HOURS[hi]}`}
                style={{ aspectRatio: "1", borderRadius: 4, minWidth: 15, background: heatColor(data[di]?.[hi] ?? 0), border: "1px solid rgba(255,255,255,0.05)" }}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}

/* ---------- styles ---------- */
const content: CSSProperties = { maxWidth: 1100, margin: "0 auto", padding: `4px ${theme.spacing.lg}px 140px` };
const greeting: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 30, fontWeight: 700, letterSpacing: "-0.02em", color: C.text };
const sub: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 15, color: C.dim, marginTop: 4 };

const card: CSSProperties = { padding: theme.spacing.lg, background: C.card, border: `1px solid ${C.cardBorder}`, borderRadius: 18 };
const cardTitle: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 19, fontWeight: 600, color: C.text, letterSpacing: "-0.01em" };
const cardSub: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13, color: C.dim, marginTop: 4 };

const hero: CSSProperties = {
  display: "grid",
  gridTemplateColumns: "184px 1fr",
  gap: theme.spacing.xl,
  alignItems: "center",
  padding: `${theme.spacing.xl}px ${theme.spacing.lg}px`,
  background: "linear-gradient(135deg, rgba(110,139,255,0.06), rgba(167,123,255,0.04))",
  border: `1px solid ${C.cardBorder}`,
  borderRadius: 20,
  marginBottom: theme.spacing.md,
};
const heroNumber: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 44, fontWeight: 700, color: C.text, lineHeight: 1, letterSpacing: "-0.02em" };
const heroNumberLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 11, fontWeight: 600, color: C.dim, textTransform: "uppercase", letterSpacing: 1.4, marginTop: 6 };
const heroCopy: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "flex-start", gap: 13 };
const heroHeadline: CSSProperties = { fontFamily: theme.fonts.display, fontSize: "clamp(26px, 3.4vw, 38px)", fontWeight: 700, letterSpacing: "-0.025em", color: C.text, lineHeight: 1.1 };
const heroRow: CSSProperties = { display: "flex", alignItems: "center", gap: 13, flexWrap: "wrap" };
const heroGoal: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13.5, color: C.dim };
const heroSub: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 14.5, color: C.dim, lineHeight: 1.5 };

const strip: CSSProperties = { display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: theme.spacing.md, marginBottom: theme.spacing.md };
const statBig: CSSProperties = { fontFamily: theme.fonts.display, fontSize: 34, fontWeight: 700, letterSpacing: "-0.02em", lineHeight: 1 };
const statUnit: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 15, color: C.dim };
const statLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13.5, fontWeight: 600, color: C.text, marginTop: 9 };
const statNote: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 12.5, color: C.dim, lineHeight: 1.45, marginTop: 5 };

const twoCol: CSSProperties = { display: "grid", gridTemplateColumns: "1fr 1fr", gap: theme.spacing.md, marginBottom: theme.spacing.md, alignItems: "start" };

const todCol: CSSProperties = { flex: 1, display: "flex", flexDirection: "column", alignItems: "center", height: "100%" };
const todVal: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 12, marginBottom: 6, fontWeight: 600 };
const todTrack: CSSProperties = { flex: 1, width: "100%", maxWidth: 46, display: "flex", alignItems: "flex-end", justifyContent: "center" };
const todLabel: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 12, color: C.dim, marginTop: 8 };

const appIcon: CSSProperties = { width: 38, height: 38, borderRadius: 10, border: "1px solid", display: "flex", alignItems: "center", justifyContent: "center", fontFamily: theme.fonts.mono, fontSize: 12, fontWeight: 700, flexShrink: 0 };
const appName: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 14.5, color: C.text };
const appMins: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 13, color: C.dim };
const barTrack: CSSProperties = { height: 8, borderRadius: 6, background: C.track, overflow: "hidden" };

const encourage: CSSProperties = { display: "flex", gap: 14, alignItems: "stretch", padding: theme.spacing.lg, background: "linear-gradient(135deg, rgba(63,214,194,0.06), rgba(110,139,255,0.05))", border: `1px solid ${C.cardBorder}`, borderRadius: 16 };
const encourageBar: CSSProperties = { width: 3, borderRadius: 3, background: `linear-gradient(180deg, ${C.cyan}, ${C.violet})`, flexShrink: 0 };
