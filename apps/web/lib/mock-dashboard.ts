import type { DashboardData } from "@/lib/analytics";

// Sample data used behind the "coming soon" dashboard blur and the dev preview.
const hours = Array.from({ length: 24 }, (_, h) => {
  const base = h >= 8 ? Math.round(40 + 60 * Math.sin((h - 6) / 4)) : 6;
  const allowed = Math.max(2, base);
  const blocked = Math.max(0, Math.round(base * (h >= 19 ? 1.4 : 0.6)));
  return { label: h === 0 ? "12a" : h < 12 ? `${h}a` : h === 12 ? "12p" : `${h - 12}p`, allowed, blocked };
});

const heatmap = Array.from({ length: 7 }, (_, d) =>
  Array.from({ length: 24 }, (_, h) => {
    const peak = h >= 19 && h <= 23 ? 0.9 : h >= 12 && h <= 14 ? 0.5 : h >= 8 ? 0.3 : 0.05;
    const weekend = d >= 5 ? 1.15 : 1;
    return Math.min(1, peak * weekend * (0.7 + ((d * 7 + h) % 5) / 12));
  })
);

export const MOCK_DASHBOARD: DashboardData = {
  apps: [
    { name: "Instagram", slug: "instagram", icon: "IG", requests: 3120, blockedPercent: 68 },
    { name: "TikTok", slug: "tiktok", icon: "TT", requests: 2240, blockedPercent: 81 },
    { name: "YouTube", slug: "youtube", icon: "YT", requests: 1180, blockedPercent: 24 },
    { name: "Reddit", slug: "reddit", icon: "RD", requests: 640, blockedPercent: 33 },
  ],
  totalBlocked: 4310,
  totalAllowed: 7026,
  timeSaved: "2h 14m",
  peakHours: "9-11 PM",
  mostActive: "Instagram",
  usageOverTime: hours,
  heatmap,
  insight:
    "Your heaviest scroll window is 9-11 PM on weekends. Rinkler cut 81% of TikTok's feed traffic this week, your Night Lock rule is doing the heavy lifting.",
  topDomains: [
    { domain: "scontent.cdninstagram.com", count: 1840, category: "instagram" },
    { domain: "v16-webapp.tiktok.com", count: 1520, category: "tiktok" },
    { domain: "rr5.googlevideo.com", count: 980, category: "youtube" },
    { domain: "i.redd.it", count: 410, category: "reddit" },
    { domain: "graph.instagram.com", count: 360, category: "instagram" },
    { domain: "mon.tiktokv.com", count: 290, category: "tiktok" },
  ],
  totalBytesIn: 1_843_000_000,
  totalBytesOut: 96_000_000,
  methods: [
    { method: "GET", count: 8200 },
    { method: "POST", count: 2400 },
    { method: "OPTIONS", count: 520 },
    { method: "HEAD", count: 180 },
  ],
  contentTypes: [
    { type: "video/mp4", count: 4100 },
    { type: "image/jpeg", count: 2600 },
    { type: "application/json", count: 1900 },
    { type: "text/html", count: 540 },
  ],
};
