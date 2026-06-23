import type { DashboardData } from "@/lib/analytics";

/**
 * Gain-framed dashboard model ("wellbeing", not "network traffic").
 *
 * Research takeaway: people return to a screen-time dashboard only if it makes
 * them feel good, and "time reclaimed" framing beats raw "blocked" counts. So we
 * lead with minutes reclaimed + wins (feeds you closed, streak), and derive
 * everything from the SAME backend data the phone already syncs — no new tables.
 *
 * `toWellbeing()` maps the existing DashboardData onto this shape so the redesign
 * drops onto real data; the heuristics below are intentionally simple and should
 * be refined server-side once we calibrate against real sessions.
 */
export interface WellbeingApp {
  name: string;
  slug: string;
  icon: string;
  reclaimedMinutes: number;
}

export interface WellbeingDay {
  label: string;
  reclaimedMinutes: number;
}

export interface WellbeingData {
  rangeLabel: string;
  reclaimedMinutes: number;
  reclaimedGoalMinutes: number;
  reclaimedDeltaPct: number | null; // vs the previous comparable period
  weekReclaimedMinutes: number;
  feedsClosed: number;
  feedsClosedDelta: number | null;
  streakDays: number;
  streakFrozen: boolean;
  bestStreak: number;
  peakWindow: string;
  apps: WellbeingApp[];
  week: WellbeingDay[];
  heatmap: number[][];
  identityLine: string;
  encouragement: string;
}

export function formatMinutes(min: number): string {
  const m = Math.max(0, Math.round(min));
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  const rem = m % 60;
  return rem === 0 ? `${h}h` : `${h}h ${rem}m`;
}

function parseDurationToMinutes(s: string): number {
  if (!s) return 0;
  let m = 0;
  const h = s.match(/(\d+)\s*h/);
  if (h) m += parseInt(h[1], 10) * 60;
  const mm = s.match(/(\d+)\s*m/);
  if (mm) m += parseInt(mm[1], 10);
  if (!h && !mm) {
    const n = s.match(/(\d+)/);
    if (n) m += parseInt(n[1], 10);
  }
  return m;
}

/** Derive the gain-framed model from the existing analytics payload. */
export function toWellbeing(data: DashboardData, rangeLabel = "today"): WellbeingData {
  const reclaimedMinutes = parseDurationToMinutes(data.timeSaved);
  // A "feed close" is a human-scale win, not a raw blocked-request count. Roughly
  // one feed-load burst per ~60 blocked requests (refine against real sessions).
  const feedsClosed = Math.max(0, Math.round((data.totalBlocked ?? 0) / 60));

  // Distribute reclaimed minutes across apps by how much feed each one tried to push.
  const weights = (data.apps ?? []).map((a) => ({
    a,
    w: Math.max(0, a.requests * (a.blockedPercent / 100)),
  }));
  const wTotal = weights.reduce((s, x) => s + x.w, 0) || 1;
  const apps: WellbeingApp[] = weights
    .map(({ a, w }) => ({
      name: a.name,
      slug: a.slug,
      icon: a.icon,
      reclaimedMinutes: Math.round((w / wTotal) * reclaimedMinutes),
    }))
    .filter((a) => a.reclaimedMinutes > 0)
    .sort((x, y) => y.reclaimedMinutes - x.reclaimedMinutes);

  const week: WellbeingDay[] = (data.usageOverTime ?? [])
    .slice(-7)
    .map((p) => ({ label: p.label, reclaimedMinutes: Math.round(p.blocked * 0.5) }));

  return {
    rangeLabel,
    reclaimedMinutes,
    reclaimedGoalMinutes: Math.max(30, Math.ceil((reclaimedMinutes || 30) / 15) * 15),
    reclaimedDeltaPct: null,
    weekReclaimedMinutes: week.reduce((s, d) => s + d.reclaimedMinutes, 0),
    feedsClosed,
    feedsClosedDelta: null,
    streakDays: 0,
    streakFrozen: false,
    bestStreak: 0,
    peakWindow: data.peakHours,
    apps,
    week,
    heatmap: data.heatmap ?? [],
    identityLine: "youre becoming someone who decides when the feed ends.",
    encouragement: data.insight,
  };
}

// Demo data for the preview — believable "today" numbers, gain-framed.
const heatmap = Array.from({ length: 7 }, (_, d) =>
  Array.from({ length: 24 }, (_, h) => {
    const peak = h >= 19 && h <= 23 ? 0.9 : h >= 12 && h <= 14 ? 0.5 : h >= 8 ? 0.3 : 0.05;
    const weekend = d >= 5 ? 1.15 : 1;
    return Math.min(1, peak * weekend * (0.7 + ((d * 7 + h) % 5) / 12));
  })
);

export const MOCK_WELLBEING: WellbeingData = {
  rangeLabel: "today",
  reclaimedMinutes: 52,
  reclaimedGoalMinutes: 60,
  reclaimedDeltaPct: 18,
  weekReclaimedMinutes: 271,
  feedsClosed: 23,
  feedsClosedDelta: 6,
  streakDays: 9,
  streakFrozen: false,
  bestStreak: 14,
  peakWindow: "9-11 PM",
  apps: [
    { name: "Instagram", slug: "instagram", icon: "IG", reclaimedMinutes: 24 },
    { name: "TikTok", slug: "tiktok", icon: "TT", reclaimedMinutes: 18 },
    { name: "YouTube", slug: "youtube", icon: "YT", reclaimedMinutes: 7 },
    { name: "Reddit", slug: "reddit", icon: "RD", reclaimedMinutes: 3 },
  ],
  week: [
    { label: "Mon", reclaimedMinutes: 31 },
    { label: "Tue", reclaimedMinutes: 44 },
    { label: "Wed", reclaimedMinutes: 28 },
    { label: "Thu", reclaimedMinutes: 39 },
    { label: "Fri", reclaimedMinutes: 33 },
    { label: "Sat", reclaimedMinutes: 44 },
    { label: "Sun", reclaimedMinutes: 52 },
  ],
  heatmap,
  identityLine: "youre becoming someone who decides when the feed ends.",
  encouragement:
    "nice run. 9-11pm used to be your deepest scroll hole and Rinkler caught most of it tonight. thats a real evening back.",
};
