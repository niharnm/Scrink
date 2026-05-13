import { redirect } from "next/navigation";
import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";
import DashboardClient from "./client";

export default async function DashboardPage() {
  await connection();

  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  if (!data?.claims) {
    redirect("/login");
  }

  return <DashboardClient email={data.claims.email as string} />;
}
