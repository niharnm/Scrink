import { redirect } from "next/navigation";
import { connection } from "next/server";
import { createClient } from "@/lib/supabase/server";
import FriendController from "@/components/friend/FriendController";

// The friend (controller) side of remote control. Sign in, enter the code the
// other person generated in the Rinkler app, then tighten their limits for the
// window they granted.
export default async function FriendPage() {
  await connection();

  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  if (!data?.claims) {
    redirect("/login");
  }

  return (
    <FriendController
      userId={data.claims.sub as string}
      email={(data.claims.email as string) ?? ""}
    />
  );
}
