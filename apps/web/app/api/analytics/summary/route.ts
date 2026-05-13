import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { APP_META } from "@/lib/app-meta";

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;
  const range = request.nextUrl.searchParams.get("range") || "today";

  // Determine time window
  let since: string;
  let period: "hourly" | "daily";
  if (range === "today") {
    since = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();
    period = "hourly";
  } else if (range === "7d") {
    since = new Date(Date.now() - 7 * 86400000).toISOString();
    period = "daily";
  } else {
    since = new Date(Date.now() - 30 * 86400000).toISOString();
    period = "daily";
  }

  // Per-app totals from traffic_summaries
  const { data: appTotals, error: appErr } = await supabase
    .from("traffic_summaries")
    .select("app_category, total_requests, blocked_count, allowed_count")
    .eq("user_id", userId)
    .eq("period", period)
    .gte("bucket", since);

  if (appErr) {
    return NextResponse.json({ error: appErr.message }, { status: 500 });
  }

  // Aggregate per app_category
  const appMap: Record<
    string,
    { requests: number; blocked: number; allowed: number }
  > = {};
  for (const row of appTotals || []) {
    const cat = row.app_category || "other";
    if (!appMap[cat]) appMap[cat] = { requests: 0, blocked: 0, allowed: 0 };
    appMap[cat].requests += Number(row.total_requests);
    appMap[cat].blocked += Number(row.blocked_count);
    appMap[cat].allowed += Number(row.allowed_count);
  }

  const apps = Object.entries(appMap)
    .map(([slug, stats]) => ({
      name: APP_META[slug]?.name || slug,
      slug,
      icon: APP_META[slug]?.icon || slug[0]?.toUpperCase() || "?",
      requests: stats.requests,
      blockedPercent:
        stats.requests > 0
          ? Math.round((stats.blocked / stats.requests) * 100)
          : 0,
    }))
    .sort((a, b) => b.requests - a.requests);

  const totalBlocked = Object.values(appMap).reduce(
    (s, v) => s + v.blocked,
    0
  );
  const totalAllowed = Object.values(appMap).reduce(
    (s, v) => s + v.allowed,
    0
  );

  // Time series buckets
  const { data: timeSeries } = await supabase
    .from("traffic_summaries")
    .select("bucket, blocked_count, allowed_count")
    .eq("user_id", userId)
    .eq("period", period)
    .gte("bucket", since)
    .order("bucket", { ascending: true });

  // Group by bucket timestamp
  const bucketMap: Record<string, { allowed: number; blocked: number }> = {};
  for (const row of timeSeries || []) {
    const key = row.bucket;
    if (!bucketMap[key]) bucketMap[key] = { allowed: 0, blocked: 0 };
    bucketMap[key].allowed += Number(row.allowed_count);
    bucketMap[key].blocked += Number(row.blocked_count);
  }

  const usageOverTime = Object.entries(bucketMap).map(([bucket, vals]) => {
    const d = new Date(bucket);
    const label =
      period === "hourly"
        ? `${d.getHours()}:00`
        : d.toLocaleDateString("en-US", { weekday: "short" });
    return { label, allowed: vals.allowed, blocked: vals.blocked };
  });

  // Peak hour from hourly data
  let peakHour = "N/A";
  if (period === "hourly" && usageOverTime.length > 0) {
    const peak = usageOverTime.reduce((max, cur) =>
      cur.allowed + cur.blocked > max.allowed + max.blocked ? cur : max
    );
    peakHour = peak.label;
  }

  // Most active app
  const mostActive = apps.length > 0 ? apps[0].name : "N/A";

  return NextResponse.json({
    apps,
    totalBlocked,
    totalAllowed,
    timeSaved: `~${Math.round(totalBlocked * 0.5)} min`,
    peakHours: peakHour,
    mostActive,
    usageOverTime,
    heatmap: [], // populated when we have enough hourly data
  });
}
