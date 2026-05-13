/** Fetch helpers for /api/analytics routes. */

export interface AppUsage {
  name: string;
  slug: string;
  icon: string;
  requests: number;
  blockedPercent: number;
}

export interface UsageDataPoint {
  label: string;
  allowed: number;
  blocked: number;
}

export interface TopDomain {
  domain: string;
  count: number;
  category: string;
}

export interface BandwidthEntry {
  category: string;
  bytesIn: number;
  bytesOut: number;
}

export interface MethodEntry {
  method: string;
  count: number;
}

export interface ContentTypeEntry {
  type: string;
  count: number;
}

export interface DashboardData {
  apps: AppUsage[];
  totalBlocked: number;
  totalAllowed: number;
  timeSaved: string;
  peakHours: string;
  mostActive: string;
  usageOverTime: UsageDataPoint[];
  heatmap: number[][];
  insight: string;
  topDomains: TopDomain[];
  totalBytesIn: number;
  totalBytesOut: number;
  methods: MethodEntry[];
  contentTypes: ContentTypeEntry[];
}

export interface AppDetailData {
  name: string;
  slug: string;
  icon: string;
  totalRequests: number;
  blockedPercent: number;
  hourlyUsage: UsageDataPoint[];
  dailyTrend: UsageDataPoint[];
  contentTypes: { type: string; count: number }[];
}

const EMPTY_DASHBOARD: DashboardData = {
  apps: [],
  totalBlocked: 0,
  totalAllowed: 0,
  timeSaved: "~0 min",
  peakHours: "N/A",
  mostActive: "N/A",
  usageOverTime: [],
  heatmap: [],
  insight: "No data yet. Once your VPN traffic flows through Bubble, insights will appear here.",
  topDomains: [],
  totalBytesIn: 0,
  totalBytesOut: 0,
  methods: [],
  contentTypes: [],
};

export async function fetchDashboardData(
  range: "today" | "7d" | "30d"
): Promise<DashboardData> {
  try {
    const [summaryRes, detailsRes] = await Promise.all([
      fetch(`/api/analytics/summary?range=${range}`),
      fetch(`/api/analytics/details?range=${range}`),
    ]);

    if (!summaryRes.ok) throw new Error(`HTTP ${summaryRes.status}`);
    const json = await summaryRes.json();

    let details = {
      topDomains: [] as TopDomain[],
      totalBytesIn: 0,
      totalBytesOut: 0,
      methods: [] as MethodEntry[],
      contentTypes: [] as ContentTypeEntry[],
    };
    if (detailsRes.ok) {
      const d = await detailsRes.json();
      details = {
        topDomains: d.topDomains || [],
        totalBytesIn: d.totalBytesIn || 0,
        totalBytesOut: d.totalBytesOut || 0,
        methods: d.methods || [],
        contentTypes: d.contentTypes || [],
      };
    }

    let insight = EMPTY_DASHBOARD.insight;
    try {
      const insightRes = await fetch("/api/analytics/insights?limit=1");
      if (insightRes.ok) {
        const insightJson = await insightRes.json();
        if (insightJson.insights?.length > 0) {
          insight = insightJson.insights[0].content;
        }
      }
    } catch {
      // keep default
    }

    return {
      apps: json.apps || [],
      totalBlocked: json.totalBlocked || 0,
      totalAllowed: json.totalAllowed || 0,
      timeSaved: json.timeSaved || "~0 min",
      peakHours: json.peakHours || "N/A",
      mostActive: json.mostActive || "N/A",
      usageOverTime: json.usageOverTime || [],
      heatmap: json.heatmap || [],
      insight,
      ...details,
    };
  } catch {
    return EMPTY_DASHBOARD;
  }
}

export async function fetchAppDetail(
  slug: string
): Promise<AppDetailData | null> {
  try {
    const res = await fetch(`/api/analytics/app/${slug}`);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    return await res.json();
  } catch {
    return null;
  }
}
