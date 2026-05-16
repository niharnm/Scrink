import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  areDashboardAdminToolsEnabled,
  createAdminClient,
} from "@/lib/supabase/admin";
import { APP_META } from "@/lib/app-meta";

const validCategories = new Set(Object.keys(APP_META));

export async function POST() {
  if (!areDashboardAdminToolsEnabled()) {
    return NextResponse.json({ error: "disabled" }, { status: 404 });
  }

  const supabase = await createClient();
  const { data: claimsData, error: authError } =
    await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;

  const admin = createAdminClient();
  if (!admin) {
    return NextResponse.json(
      { error: "admin client is not configured" },
      { status: 500 }
    );
  }

  const { data: hostRows, error: hostErr } = await admin
    .from("traffic_events")
    .select("host")
    .eq("user_id", userId)
    .eq("app_category", "other")
    .limit(5000);

  if (hostErr) {
    return NextResponse.json({ error: hostErr.message }, { status: 500 });
  }

  const countMap: Record<string, number> = {};
  for (const row of hostRows || []) {
    const host = normalizeHost(row.host);
    if (!host) continue;
    countMap[host] = (countMap[host] || 0) + 1;
  }
  const hosts = Object.entries(countMap)
    .map(([host, cnt]) => ({ host, cnt }))
    .sort((a, b) => b.cnt - a.cnt);

  if (hosts.length === 0) {
    return NextResponse.json({ classified: {}, updated: 0 });
  }

  const classificationMap: Record<string, string> = {};
  for (const { host } of hosts) {
    const category = classifyHost(host);
    if (category !== "other" && validCategories.has(category)) {
      classificationMap[host] = category;
    }
  }

  // Update traffic_events in-place
  let updated = 0;
  for (const [host, category] of Object.entries(classificationMap)) {
    const { count } = await admin
      .from("traffic_events")
      .update({ app_category: category }, { count: "exact" })
      .eq("user_id", userId)
      .eq("host", host)
      .eq("app_category", "other");

    updated += count || 0;
  }

  // Recompute all rollups
  const { error: recomputeErr } = await admin.rpc("recompute_all_rollups");

  return NextResponse.json({
    classified: classificationMap,
    updated,
    hostsProcessed: hosts.length,
    recomputeError: recomputeErr?.message || null,
  });
}

function normalizeHost(host: string | null | undefined): string {
  return (host || "")
    .trim()
    .toLowerCase()
    .replace(/^www\./, "");
}

function classifyHost(host: string): string {
  if (
    matches(host, [
      "instagram.com",
      "cdninstagram.com",
      "instagram.net",
      "fbcdn.net",
      "facebook.com",
      "edge-mqtt.facebook.com",
    ])
  ) {
    return "instagram";
  }
  if (
    matches(host, [
      "tiktok.com",
      "tiktokcdn.com",
      "tiktokcdn-us.com",
      "tiktokcdn-eu.com",
      "tiktokcdn-in.com",
      "tiktokv.com",
      "byteoversea.com",
      "byteoversea.net",
      "byteimg.com",
      "ibyteimg.com",
      "ibytedtos.com",
      "muscdn.com",
      "musical.ly",
      "snssdk.com",
      "ttwstatic.com",
    ])
  ) {
    return "tiktok";
  }
  if (
    matches(host, [
      "youtube.com",
      "youtube-nocookie.com",
      "youtubei.googleapis.com",
      "googlevideo.com",
      "ytimg.com",
      "yt3.ggpht.com",
      "youtu.be",
    ])
  ) {
    return "youtube";
  }
  if (matches(host, ["twitter.com", "x.com", "twimg.com", "t.co"])) {
    return "twitter";
  }
  if (
    matches(host, ["reddit.com", "redd.it", "redditmedia.com", "redditstatic.com"])
  ) {
    return "reddit";
  }
  if (matches(host, ["snapchat.com", "sc-cdn.net"])) return "snapchat";
  if (matches(host, ["openai.com", "anthropic.com", "claude.ai", "perplexity.ai"])) {
    return "ai";
  }
  if (
    matches(host, [
      "google.com",
      "googleapis.com",
      "gstatic.com",
      "googleusercontent.com",
    ])
  ) {
    return "google";
  }
  if (
    host.endsWith(".edu") ||
    matches(host, ["canvaslms.com", "instructure.com", "khanacademy.org"])
  ) {
    return "education";
  }
  if (
    matches(host, [
      "apple.com",
      "icloud.com",
      "cloudflare.com",
      "akamai",
      "fastly",
      "amazonaws.com",
      "firebaseio.com",
    ])
  ) {
    return "infrastructure";
  }
  return "other";
}

function matches(host: string, needles: string[]): boolean {
  return needles.some(
    (needle) =>
      host === needle || host.endsWith(`.${needle}`) || host.includes(needle)
  );
}
