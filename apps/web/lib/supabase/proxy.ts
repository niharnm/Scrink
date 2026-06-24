import { createServerClient } from "@supabase/ssr";
import { NextResponse, type NextRequest } from "next/server";
import { getSupabasePublicConfig } from "./config";

/**
 * Public routes that must be reachable without signing in: the marketing
 * landing (`/`), the privacy policy, the auth screens themselves, and the
 * unauthenticated health probe (`/api/health`) used by uptime monitors.
 * Everything else (the dashboard, analytics APIs) still requires a session.
 */
function isPublicPath(pathname: string): boolean {
  if (pathname === "/") return true;
  // Dev-only visual preview routes (e.g. /dev/dashboard-preview); never public in prod.
  if (pathname.startsWith("/dev/") && process.env.NODE_ENV !== "production") return true;
  // SEO/crawler files must be reachable without a session.
  if (pathname === "/robots.txt" || pathname === "/sitemap.xml" || pathname === "/manifest.webmanifest") {
    return true;
  }
  // Exact path or a sub-path under it — so `/auth/callback` is public but a future
  // `/authsomething` or `/api/healthz` would NOT be unintentionally exposed.
  return ["/login", "/auth", "/privacy", "/terms", "/api/health"].some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

/**
 * Redirect an unauthenticated request to /login, remembering where they were
 * headed via ?next= so sign-in can return them there (e.g. a friend opening
 * /friend lands back on /friend instead of the marketing home). Only an internal
 * absolute path is preserved — never a protocol-relative or cross-origin value.
 */
function redirectToLogin(request: NextRequest) {
  const url = request.nextUrl.clone();
  const dest = url.pathname + url.search;
  url.pathname = "/login";
  url.search = "";
  if (dest.startsWith("/") && !dest.startsWith("//")) {
    url.searchParams.set("next", dest);
  }
  return NextResponse.redirect(url);
}

export async function updateSession(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request });
  const config = getSupabasePublicConfig();

  if (!config) {
    if (!isPublicPath(request.nextUrl.pathname)) {
      return redirectToLogin(request);
    }
    return supabaseResponse;
  }

  const supabase = createServerClient(config.url, config.publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        supabaseResponse = NextResponse.next({ request });
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options)
        );
      },
    },
  });

  // IMPORTANT: Do not run code between createServerClient and getClaims().
  const { data } = await supabase.auth.getClaims();
  const user = data?.claims;

  if (!user && !isPublicPath(request.nextUrl.pathname)) {
    return redirectToLogin(request);
  }

  return supabaseResponse;
}
