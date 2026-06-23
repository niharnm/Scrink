import type { DashboardData } from "@/lib/analytics";

/**
 * Gain-framed dashboard model ("wellbeing", not "network traffic").
 *
 * Leads with time reclaimed + wins, derived from the SAME backend data the phone
 * already syncs (no new tables). The heuristics below are intentionally simple and
 * should be calibrated server-side once we have real sessions.
 */
export interface WellbeingApp {
  name: string;
  slug: string;
  icon: string;
  reclaimedMinutes: number;
  feedsClosed: number;
}

export interface WellbeingDay {
  label: string;
  reclaimedMinutes: number;
}

export interface TimeOfDaySlice {
  label: string;
  minutes: number;
}

export interface WellbeingData {
  rangeLabel: string;
  reclaimedMinutes: number;
  reclaimedGoalMinutes: number;
  reclaimedDeltaPct: number | null;
  weekReclaimedMinutes: number;
  dailyAvgMinutes: number;
  bestDay: { label: string; minutes: number };
  monthReclaimedMinutes: number;
  feedsClosed: number;
  feedsClosedDelta: number | null;
  streakDays: number;
  streakFrozen: boolean;
  bestStreak: number;
  peakWindow: string;
  apps: WellbeingApp[];
  week: WellbeingDay[];
  lastWeek: number[]; // reclaimed minutes/day, aligned to `week` for the compare line
  timeOfDay: TimeOfDaySlice[]; // morning / afternoon / evening / night
  heatmap: number[][];
  headline: string;
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
  // one feed-load burst per ~60 blocked requests (calibrate against real sessions).
  const feedsClosed = Math.max(0, Math.round((data.totalBlocked ?? 0) / 60));

  const weights = (data.apps ?? []).map((a) => ({ a, w: Math.max(0, a.requests * (a.blockedPercent / 100)) }));
  const wTotal = weights.reduce((s, x) => s + x.w, 0) || 1;
  const apps: WellbeingApp[] = weights
    .map(({ a, w }) => ({
      name: a.name,
      slug: a.slug,
      icon: a.icon,
      reclaimedMinutes: Math.round((w / wTotal) * reclaimedMinutes),
      feedsClosed: Math.round((w / wTotal) * feedsClosed),
    }))
    .filter((a) => a.reclaimedMinutes > 0)
    .sort((x, y) => y.reclaimedMinutes - x.reclaimedMinutes);

  const week: WellbeingDay[] = (data.usageOverTime ?? [])
    .slice(-7)
    .map((p) => ({ label: p.label, reclaimedMinutes: Math.round(p.blocked * 0.5) }));
  const weekReclaimedMinutes = week.reduce((s, d) => s + d.reclaimedMinutes, 0);
  const best = week.reduce((b, d) => (d.reclaimedMinutes > b.minutes ? { label: d.label, minutes: d.reclaimedMinutes } : b), { label: "-", minutes: 0 });

  // Split reclaimed time across parts of the day using the heatmap shape.
  const hourSum = Array(24).fill(0);
  for (const day of data.heatmap ?? []) for (let h = 0; h < 24; h++) hourSum[h] += day[h] ?? 0;
  const inRange = (h: number, a: number, b: number) => (a < b ? h >= a && h < b : h >= a || h < b);
  const slices: [string, number, number][] = [["morning", 6, 12], ["afternoon", 12, 17], ["evening", 17, 21], ["night", 21, 6]];
  const sliceTotals = slices.map(([label, a, b]) => ({ label, v: hourSum.reduce((s, x, h) => s + (inRange(h, a, b) ? x : 0), 0) }));
  const sliceSum = sliceTotals.reduce((s, x) => s + x.v, 0) || 1;
  const timeOfDay: TimeOfDaySlice[] = sliceTotals.map((s) => ({ label: s.label, minutes: Math.round((s.v / sliceSum) * reclaimedMinutes) }));

  return {
    rangeLabel,
    reclaimedMinutes,
    reclaimedGoalMinutes: Math.max(30, Math.ceil((reclaimedMinutes || 30) / 15) * 15),
    reclaimedDeltaPct: null,
    weekReclaimedMinutes,
    dailyAvgMinutes: week.length ? Math.round(weekReclaimedMinutes / week.length) : 0,
    bestDay: best,
    monthReclaimedMinutes: weekReclaimedMinutes, // until we query a full month server-side
    feedsClosed,
    feedsClosedDelta: null,
    streakDays: 0,
    streakFrozen: false,
    bestStreak: 0,
    peakWindow: data.peakHours,
    apps,
    week,
    lastWeek: week.map(() => 0),
    timeOfDay,
    heatmap: data.heatmap ?? [],
    headline: "heres what rinkler kept off your feed.",
    encouragement: data.insight,
  };
}

// Demo data for the preview — believable "today" numbers.
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
  dailyAvgMinutes: 39,
  bestDay: { label: "Sun", minutes: 52 },
  monthReclaimedMinutes: 1102,
  feedsClosed: 23,
  feedsClosedDelta: 6,
  streakDays: 9,
  streakFrozen: false,
  bestStreak: 14,
  peakWindow: "9-11 PM",
  apps: [
    { name: "Instagram", slug: "instagram", icon: "IG", reclaimedMinutes: 24, feedsClosed: 11 },
    { name: "TikTok", slug: "tiktok", icon: "TT", reclaimedMinutes: 18, feedsClosed: 8 },
    { name: "YouTube", slug: "youtube", icon: "YT", reclaimedMinutes: 7, feedsClosed: 3 },
    { name: "Reddit", slug: "reddit", icon: "RD", reclaimedMinutes: 3, feedsClosed: 1 },
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
  lastWeek: [22, 26, 30, 24, 35, 28, 31],
  timeOfDay: [
    { label: "morning", minutes: 6 },
    { label: "afternoon", minutes: 11 },
    { label: "evening", minutes: 14 },
    { label: "night", minutes: 21 },
  ],
  heatmap,
  headline: "heres what rinkler kept off your feed.",
  encouragement:
    "you usually lose 9 to 11pm to the scroll. tonight rinkler caught most of it, so thats a real evening back. same time tomorrow.",
};
