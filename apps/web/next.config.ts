import type { NextConfig } from "next";

// Static Content-Security-Policy. We use 'unsafe-inline' for scripts/styles rather
// than nonces: the whole app is React inline styles + Next inline hydration scripts,
// and a per-request nonce is incompatible with statically-cached pages on Vercel
// (the cached HTML's nonce can't match a fresh per-request header nonce). Given the
// app has no XSS sink (every dangerouslySetInnerHTML is a static CSS literal), the
// real value here is the rest: frame-ancestors/object-src/base-uri/form-action and a
// scoped connect-src. challenges.cloudflare.com is allowed for the Turnstile captcha.
const csp = [
  "default-src 'self'",
  "script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "font-src 'self'",
  "connect-src 'self' https://*.supabase.co wss://*.supabase.co https://challenges.cloudflare.com",
  "frame-src https://challenges.cloudflare.com",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self'",
  "object-src 'none'",
  "upgrade-insecure-requests",
].join("; ");

// Defense-in-depth response headers applied to every route.
const securityHeaders = [
  { key: "Content-Security-Policy", value: csp },
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
];

const nextConfig: NextConfig = {
  transpilePackages: ["@rinkler/assets"],
  async headers() {
    return [{ source: "/:path*", headers: securityHeaders }];
  },
};

export default nextConfig;
