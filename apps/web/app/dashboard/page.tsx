import { redirect } from "next/navigation";
import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";
import WaitlistDashboard from "@/components/dashboard/WaitlistDashboard";

// Waitlist phase: the live dashboard (DashboardClient) is built but the app
// hasn't shipped, so signing in shows the "coming soon" waitlist view. Swap
// back to <DashboardClient> once the app is live.
export default async function DashboardPage() {
  await connection();

  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  if (!data?.claims) {
    redirect("/login");
  }

  return <WaitlistDashboard email={data.claims.email as string} />;
}
