import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import {
  areDashboardAdminToolsEnabled,
  createAdminClient,
  isAdminUser,
} from "@/lib/supabase/admin";

export async function POST() {
  if (!areDashboardAdminToolsEnabled()) {
    return NextResponse.json({ error: "disabled" }, { status: 404 });
  }

  const supabase = await createClient();
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser();

  if (authError || !user) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  if (!isAdminUser(user.id)) {
    return NextResponse.json({ error: "forbidden" }, { status: 403 });
  }

  const admin = createAdminClient();
  if (!admin) {
    return NextResponse.json(
      { error: "admin client is not configured" },
      { status: 500 }
    );
  }

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
