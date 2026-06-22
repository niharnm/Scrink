"use client";

import { createClient } from "@/lib/supabase/client";

export default function SignOutButton() {
  async function handleSignOut() {
    const supabase = createClient();
    await supabase.auth.signOut();
    window.location.href = "/login";
  }

  return (
    <button
      onClick={handleSignOut}
      style={{
        padding: "8px 16px",
        cursor: "pointer",
        color: "rgba(255,255,255,0.6)",
        background: "rgba(255,255,255,0.05)",
        border: "1px solid rgba(255,255,255,0.14)",
        borderRadius: 16,
        fontSize: 14,
        fontFamily: "'Geist', system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif",
      }}
    >
      Sign Out
    </button>
  );
}
