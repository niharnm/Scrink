import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";
import Landing from "@/components/marketing/Landing";

export default async function Home() {
  await connection();

  // Public marketing page. We only read auth to decide the CTA label/target
  // (logged-in visitors get a "Open dashboard" button instead of "Get started").
  let loggedIn = false;
  try {
    const supabase = await createClient();
    const { data } = await supabase.auth.getClaims();
    loggedIn = Boolean(data?.claims);
  } catch {
    loggedIn = false;
  }

  return <Landing loggedIn={loggedIn} />;
}
