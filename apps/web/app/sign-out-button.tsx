"use client";

import { createClient } from "@/lib/supabase/client";

export default function SignOutButton() {
  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    window.location.href = "/login";
  }

  return (
    <button onClick={handleSignOut} style={{ padding: "8px 16px", cursor: "pointer" }}>
      Sign Out
    </button>
  );
}
