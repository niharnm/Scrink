import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: NextRequest) {
  const supabase = await createClient();
  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;
  const limit = Math.min(
    Number(request.nextUrl.searchParams.get("limit") || "5"),
    20
  );

  const { data: insights, error } = await supabase
    .from("llm_insights")
    .select("id, job_type, content, metadata, created_at")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ insights: insights || [] });
}
