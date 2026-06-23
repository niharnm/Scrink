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
  // Exact path or a sub-path under it — so `/auth/callback` is public but a future
  // `/authsomething` or `/api/healthz` would NOT be unintentionally exposed.
  return ["/login", "/auth", "/privacy", "/terms", "/api/health"].some(
    (p) => pathname === p || pathname.startsWith(p + "/")
  );
}

/**
 * Per-request Content-Security-Policy. Scripts are locked to a fresh nonce +
 * `strict-dynamic` (Next applies the nonce to its own scripts automatically when
 * it sees this header on the request). Styles must allow `unsafe-inline`: the app
 * is built entirely on React inline styles + static inline <style> blocks, which
 * cannot be nonced. `frame-ancestors 'none'` blocks clickjacking; `connect-src`
 * permits the Supabase API/realtime.
 */
function buildCsp(nonce: string): string {
  return [
    "default-src 'self'",
    `script-src 'self' 'nonce-${nonce}' 'strict-dynamic'`,
    "style-src 'self' 'unsafe-inline'",
    "img-src 'self' data: blob:",
    "font-src 'self'",
    "connect-src 'self' https://*.supabase.co wss://*.supabase.co",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "object-src 'none'",
    "upgrade-insecure-requests",
  ].join("; ");
}

export async function updateSession(request: NextRequest) {
  const nonce = btoa(crypto.randomUUID());
  const csp = buildCsp(nonce);

  // Forward the nonce + CSP on the request so Next can nonce its inline scripts.
  const baseHeaders = () => {
    const h = new Headers(request.headers);
    h.set("x-nonce", nonce);
    h.set("content-security-policy", csp);
    return h;
  };

  let supabaseResponse = NextResponse.next({ request: { headers: baseHeaders() } });

  const finish = (res: NextResponse) => {
    res.headers.set("content-security-policy", csp);
    return res;
  };
  const redirectToLogin = () => {
    const url = request.nextUrl.clone();
    url.pathname = "/login";
    return finish(NextResponse.redirect(url));
  };

  const config = getSupabasePublicConfig();
  if (!config) {
    if (!isPublicPath(request.nextUrl.pathname)) return redirectToLogin();
    return finish(supabaseResponse);
  }

  const supabase = createServerClient(config.url, config.publishableKey, {
    cookies: {
      getAll() {
        return request.cookies.getAll();
      },
      setAll(cookiesToSet) {
        cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value));
        // Rebuild from the now-updated request (carries refreshed auth cookies)
        // and re-attach the nonce/CSP headers.
        supabaseResponse = NextResponse.next({ request: { headers: baseHeaders() } });
        cookiesToSet.forEach(({ name, value, options }) =>
          supabaseResponse.cookies.set(name, value, options)
        );
      },
    },
  });

  // IMPORTANT: Do not run code between createServerClient and getClaims().
  const { data } = await supabase.auth.getClaims();
  const user = data?.claims;

  if (!user && !isPublicPath(request.nextUrl.pathname)) return redirectToLogin();

  return finish(supabaseResponse);
}
