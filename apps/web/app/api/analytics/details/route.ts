import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: claimsData, error: authError } =
    await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;
  const range = request.nextUrl.searchParams.get("range") || "today";

  let since: string;
  if (range === "today") {
    since = new Date(new Date().setHours(0, 0, 0, 0)).toISOString();
  } else if (range === "7d") {
    since = new Date(Date.now() - 7 * 86400000).toISOString();
  } else {
    since = new Date(Date.now() - 30 * 86400000).toISOString();
  }

  // Top domains: host + count + category
  const { data: eventRows } = await supabase
    .from("traffic_events")
    .select("host, app_category, method, content_type, bytes_in, bytes_out")
    .eq("user_id", userId)
    .gte("ts", since);

  const rows = eventRows || [];

  // Aggregate top domains
  const domainMap: Record<string, { count: number; category: string }> = {};
  for (const row of rows) {
    const host = row.host || "unknown";
    if (!domainMap[host]) {
      domainMap[host] = { count: 0, category: row.app_category || "other" };
    }
    domainMap[host].count++;
  }
  const topDomains = Object.entries(domainMap)
    .map(([domain, { count, category }]) => ({ domain, count, category }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 20);

  // Bandwidth per category
  const bandwidthMap: Record<
    string,
    { bytesIn: number; bytesOut: number }
  > = {};
  for (const row of rows) {
    const cat = row.app_category || "other";
    if (!bandwidthMap[cat]) bandwidthMap[cat] = { bytesIn: 0, bytesOut: 0 };
    bandwidthMap[cat].bytesIn += Number(row.bytes_in) || 0;
    bandwidthMap[cat].bytesOut += Number(row.bytes_out) || 0;
  }
  const bandwidth = Object.entries(bandwidthMap)
    .map(([category, { bytesIn, bytesOut }]) => ({
      category,
      bytesIn,
      bytesOut,
    }))
    .sort((a, b) => b.bytesIn + b.bytesOut - (a.bytesIn + a.bytesOut));

  // Total bandwidth
  let totalBytesIn = 0;
  let totalBytesOut = 0;
  for (const b of bandwidth) {
    totalBytesIn += b.bytesIn;
    totalBytesOut += b.bytesOut;
  }

  // Method breakdown
  const methodMap: Record<string, number> = {};
  for (const row of rows) {
    const m = row.method || "UNKNOWN";
    methodMap[m] = (methodMap[m] || 0) + 1;
  }
  const methods = Object.entries(methodMap)
    .map(([method, count]) => ({ method, count }))
    .sort((a, b) => b.count - a.count);

  // Content types
  const ctMap: Record<string, number> = {};
  for (const row of rows) {
    const ct = row.content_type?.split(";")[0]?.trim() || "unknown";
    ctMap[ct] = (ctMap[ct] || 0) + 1;
  }
  const contentTypes = Object.entries(ctMap)
    .map(([type, count]) => ({ type, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, 10);

  return NextResponse.json({
    topDomains,
    bandwidth,
    totalBytesIn,
    totalBytesOut,
    methods,
    contentTypes,
  });
}
