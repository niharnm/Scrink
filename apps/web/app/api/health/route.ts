import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET() {
  const supabase = await createClient();

  const { data: claimsData, error: authError } = await supabase.auth.getClaims();

  if (authError || !claimsData?.claims) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const userId = claimsData.claims.sub as string;

  const { data: profile, error: dbError } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .single();

  return NextResponse.json({
    user: {
      id: userId,
      email: claimsData.claims.email,
    },
    profile: dbError ? null : profile,
    supabase: dbError ? "error" : "connected",
  });
}
