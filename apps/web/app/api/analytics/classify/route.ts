import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createClient as createServiceClient } from "@supabase/supabase-js";
import { APP_META } from "@/lib/app-meta";

const BATCH_SIZE = 50;

const validCategories = Object.keys(APP_META).filter((k) => k !== "other");

export async function POST() {
  const supabase = await createClient();
  const { data: claimsData, error: authError } =
    await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const admin = createServiceClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  // Get distinct "other" hosts with counts
  const { data: hostRows, error: hostErr } = await admin.rpc("execute_sql", {
    query: `SELECT host, count(*)::int as cnt FROM traffic_events WHERE app_category = 'other' GROUP BY host ORDER BY cnt DESC`,
  });

  if (hostErr) {
    // Fallback: query via regular select
    const { data: fallbackRows, error: fallbackErr } = await admin
      .from("traffic_events")
      .select("host")
      .eq("app_category", "other");

    if (fallbackErr) {
      return NextResponse.json(
        { error: fallbackErr.message },
        { status: 500 }
      );
    }

    // Aggregate manually
    const countMap: Record<string, number> = {};
    for (const row of fallbackRows || []) {
      countMap[row.host] = (countMap[row.host] || 0) + 1;
    }
    var hosts = Object.entries(countMap)
      .map(([host, cnt]) => ({ host, cnt }))
      .sort((a, b) => b.cnt - a.cnt);
  } else {
    var hosts = (hostRows as { host: string; cnt: number }[]) || [];
  }

  if (hosts.length === 0) {
    return NextResponse.json({ classified: {}, updated: 0 });
  }

  const openaiKey = process.env.OPENAI_API_KEY;
  if (!openaiKey) {
    return NextResponse.json(
      { error: "OPENAI_API_KEY not configured" },
      { status: 500 }
    );
  }

  // Batch hosts and classify with LLM
  const classificationMap: Record<string, string> = {};
  const hostnames = hosts.map((h) => h.host);

  for (let i = 0; i < hostnames.length; i += BATCH_SIZE) {
    const batch = hostnames.slice(i, i + BATCH_SIZE);
    const prompt = `Classify each hostname into exactly one category. Valid categories: ${validCategories.join(", ")}.

Return a JSON object mapping each hostname to its category. If unsure, use "other".

Hostnames:
${batch.join("\n")}`;

    try {
      const llmRes = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${openaiKey}`,
          },
          body: JSON.stringify({
            model: "gpt-5-mini",
            max_tokens: 1000,
            response_format: { type: "json_object" },
            messages: [
              {
                role: "system",
                content:
                  "You classify internet hostnames into app categories. Respond with only a JSON object mapping hostname to category.",
              },
              { role: "user", content: prompt },
            ],
          }),
        }
      );

      if (llmRes.ok) {
        const llmData = await llmRes.json();
        const content = llmData.choices?.[0]?.message?.content || "{}";
        const parsed = JSON.parse(content) as Record<string, string>;
        for (const [host, category] of Object.entries(parsed)) {
          if (validCategories.includes(category)) {
            classificationMap[host] = category;
          }
        }
      }
    } catch {
      // Continue with next batch on failure
    }
  }

  // Update traffic_events in-place
  let updated = 0;
  for (const [host, category] of Object.entries(classificationMap)) {
    const { count } = await admin
      .from("traffic_events")
      .update({ app_category: category }, { count: "exact" })
      .eq("host", host)
      .eq("app_category", "other");

    updated += count || 0;
  }

  // Recompute all rollups
  const { error: recomputeErr } = await admin.rpc("recompute_all_rollups");

  return NextResponse.json({
    classified: classificationMap,
    updated,
    hostsProcessed: hostnames.length,
    recomputeError: recomputeErr?.message || null,
  });
}
