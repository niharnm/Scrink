import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createClient as createServiceClient } from "@supabase/supabase-js";

export async function POST() {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;

  // Service role client for inserting into llm_insights
  const admin = createServiceClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  // Query last 24h traffic summaries
  const since = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { data: summaries } = await admin
    .from("traffic_summaries")
    .select("app_category, total_requests, blocked_count, allowed_count")
    .eq("user_id", userId)
    .gte("bucket", since);

  // Aggregate per-app stats
  const appStats: Record<string, { requests: number; blocked: number }> = {};
  let totalReqs = 0;
  let totalBlocked = 0;
  for (const row of summaries || []) {
    const cat = row.app_category || "other";
    if (!appStats[cat]) appStats[cat] = { requests: 0, blocked: 0 };
    appStats[cat].requests += Number(row.total_requests);
    appStats[cat].blocked += Number(row.blocked_count);
    totalReqs += Number(row.total_requests);
    totalBlocked += Number(row.blocked_count);
  }

  // Generate insight
  let insightText: string;
  const openaiKey = process.env.OPENAI_API_KEY;

  if (openaiKey && totalReqs > 0) {
    const statsDesc = Object.entries(appStats)
      .map(([app, s]) => `${app}: ${s.requests} requests (${s.blocked} blocked)`)
      .join(", ");

    try {
      const llmRes = await fetch("https://api.openai.com/v1/chat/completions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${openaiKey}`,
        },
        body: JSON.stringify({
          model: "gpt-5-mini",
          max_tokens: 200,
          messages: [
            {
              role: "system",
              content:
                "You are a digital wellness assistant for Bubble, an app that helps users manage screen time by blocking distracting content. Write a 1-2 sentence friendly, specific insight based on the user's traffic stats. Be encouraging.",
            },
            {
              role: "user",
              content: `My last 24h stats: ${statsDesc}. Total: ${totalReqs} requests, ${totalBlocked} blocked.`,
            },
          ],
        }),
      });

      if (llmRes.ok) {
        const llmData = await llmRes.json();
        insightText = llmData.choices?.[0]?.message?.content || "";
      } else {
        insightText = fallbackInsight(appStats, totalReqs, totalBlocked);
      }
    } catch {
      insightText = fallbackInsight(appStats, totalReqs, totalBlocked);
    }
  } else {
    insightText = fallbackInsight(appStats, totalReqs, totalBlocked);
  }

  // Insert into llm_insights
  const { data: insight, error: insertErr } = await admin
    .from("llm_insights")
    .insert({
      user_id: userId,
      job_type: "daily_summary",
      content: insightText,
      metadata: { total_requests: totalReqs, total_blocked: totalBlocked, app_stats: appStats },
    })
    .select()
    .single();

  if (insertErr) {
    return NextResponse.json({ error: insertErr.message }, { status: 500 });
  }

  // Log the run
  await admin.from("cron_runs").insert({
    job_type: "daily_summary",
    status: "success",
    finished_at: new Date().toISOString(),
    result: { insight_id: insight.id },
  });

  return NextResponse.json({ insight });
}

function fallbackInsight(
  appStats: Record<string, { requests: number; blocked: number }>,
  totalReqs: number,
  totalBlocked: number
): string {
  if (totalReqs === 0) {
    return "No traffic recorded yet. Once Bubble starts filtering your traffic, you'll see personalized insights here.";
  }
  const topApp = Object.entries(appStats).sort(
    (a, b) => b[1].requests - a[1].requests
  )[0];
  const blockedPct = Math.round((totalBlocked / totalReqs) * 100);
  const timeSaved = Math.round(totalBlocked * 0.5);
  return `Bubble blocked ${blockedPct}% of distracting content today (~${timeSaved} min saved). ${topApp ? `Your most active app was ${topApp[0]} with ${topApp[1].requests} requests.` : ""} Keep it up!`;
}
