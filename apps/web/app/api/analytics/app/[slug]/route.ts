import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { APP_META } from "@/lib/app-meta";

interface RouteContext {
  params: Promise<{ slug: string }>;
}

export async function GET(request: NextRequest, context: RouteContext) {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;
  const { slug } = await context.params;
  const meta = APP_META[slug];
  if (!meta) {
    return NextResponse.json({ error: "unknown app" }, { status: 404 });
  }

  const todayStart = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();
  const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString();

  // Hourly data for today
  const { data: hourly } = await supabase
    .from("traffic_summaries")
    .select("bucket, total_requests, blocked_count, allowed_count")
    .eq("user_id", userId)
    .eq("period", "hourly")
    .eq("app_category", slug)
    .gte("bucket", todayStart)
    .order("bucket", { ascending: true });

  // Daily data for 30-day trend
  const { data: daily } = await supabase
    .from("traffic_summaries")
    .select("bucket, total_requests, blocked_count, allowed_count")
    .eq("user_id", userId)
    .eq("period", "daily")
    .eq("app_category", slug)
    .gte("bucket", thirtyDaysAgo)
    .order("bucket", { ascending: true });

  const hourlyUsage = (hourly || []).map((r) => ({
    label: `${new Date(r.bucket).getHours()}:00`,
    allowed: Number(r.allowed_count),
    blocked: Number(r.blocked_count),
  }));

  const dailyTrend = (daily || []).map((r) => ({
    label: new Date(r.bucket).toLocaleDateString("en-US", {
      month: "short",
      day: "numeric",
    }),
    allowed: Number(r.allowed_count),
    blocked: Number(r.blocked_count),
  }));

  const totalRequests = (hourly || []).reduce(
    (s, r) => s + Number(r.total_requests),
    0
  );
  const totalBlocked = (hourly || []).reduce(
    (s, r) => s + Number(r.blocked_count),
    0
  );

  // Content type breakdown from raw events (today only)
  const { data: contentRows } = await supabase
    .from("traffic_events")
    .select("content_type")
    .eq("user_id", userId)
    .eq("app_category", slug)
    .gte("ts", todayStart);

  const ctMap: Record<string, number> = {};
  for (const row of contentRows || []) {
    const ct = row.content_type?.split(";")[0]?.trim() || "unknown";
    ctMap[ct] = (ctMap[ct] || 0) + 1;
  }
  const contentTypes = Object.entries(ctMap)
    .map(([type, count]) => ({ type, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 8);

  return NextResponse.json({
    name: meta.name,
    slug,
    icon: meta.icon,
    totalRequests,
    blockedPercent:
      totalRequests > 0 ? Math.round((totalBlocked / totalRequests) * 100) : 0,
    hourlyUsage,
    dailyTrend,
    contentTypes,
  });
}
