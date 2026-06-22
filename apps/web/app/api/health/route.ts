import { NextResponse } from "next/server";
import { getSupabasePublicConfig } from "@/lib/supabase/config";

// Public, unauthenticated liveness/readiness probe for load balancers and
// uptime monitors. Returns no user data — only whether the deployment is up
// and whether Supabase is configured. Allowlisted in middleware.
export const dynamic = "force-dynamic";

export async function GET() {
  const supabaseConfigured = getSupabasePublicConfig() !== null;

  return NextResponse.json(
    {
      status: "ok",
      service: "rinkler-web",
      supabase: supabaseConfigured ? "configured" : "unconfigured",
      time: new Date().toISOString(),
    },
    {
      status: 200,
      headers: { "Cache-Control": "no-store" },
    }
  );
}
