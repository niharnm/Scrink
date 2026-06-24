import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const { searchParams, origin } = new URL(request.url);
  const code = searchParams.get("code");
  // Only ever redirect to a same-origin internal path. Resolving `next` against
  // our own origin and re-checking the origin rejects open-redirect payloads like
  // `//evil.com`, `/\evil.com`, or absolute URLs to another host.
  const next = safeNext(searchParams.get("next"), origin);

  if (code) {
    const supabase = await createClient();
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) {
      // Waitlist gate (same flag as the email path): if locked, an email not on
      // the allowlist isn't permitted in yet. OAuth creates the user before we can
      // check, so we sign them straight back out — they stay blocked because the
      // gate keys off the allowlist, not off account existence.
      if (process.env.ENABLE_WAITLIST_LOCK === "true") {
        const email = data.user?.email ?? "";
        const { data: allowed } = await supabase.rpc("email_can_sign_in", { p_email: email });
        if (!allowed) {
          await supabase.auth.signOut();
          return NextResponse.redirect(`${origin}/login?error=waitlist`);
        }
      }
      return NextResponse.redirect(`${origin}${next}`);
    }
  }

  return NextResponse.redirect(`${origin}/login?error=auth_callback_error`);
}

function safeNext(raw: string | null, origin: string): string {
  if (!raw) return "/";
  try {
    const url = new URL(raw, origin);
    if (url.origin !== origin) return "/";
    return `${url.pathname}${url.search}${url.hash}`;
  } catch {
    return "/";
  }
}
