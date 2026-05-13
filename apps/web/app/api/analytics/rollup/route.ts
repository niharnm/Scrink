import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { createClient as createServiceClient } from "@supabase/supabase-js";

export async function POST() {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const admin = createServiceClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );

  const results: Record<string, string> = {};

  // Run hourly rollup
  const { error: hourlyErr } = await admin.rpc("rollup_traffic_hourly");
  results.hourly = hourlyErr ? `error: ${hourlyErr.message}` : "ok";

  // Run daily rollup
  const { error: dailyErr } = await admin.rpc("rollup_traffic_daily");
  results.daily = dailyErr ? `error: ${dailyErr.message}` : "ok";

  // Run cleanup
  const { error: cleanupErr } = await admin.rpc("cleanup_old_traffic");
  results.cleanup = cleanupErr ? `error: ${cleanupErr.message}` : "ok";

  const hasError = Object.values(results).some((v) => v.startsWith("error"));

  return NextResponse.json(
    { results },
    { status: hasError ? 207 : 200 }
  );
}
