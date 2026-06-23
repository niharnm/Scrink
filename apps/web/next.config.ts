import type { NextConfig } from "next";

// Defense-in-depth response headers applied to every route. (No CSP yet: the app
// ships static inline <style> blocks and Next's hydration scripts, so a strict CSP
// needs nonce wiring — tracked as a follow-up. X-Frame-Options still blocks the
// main clickjacking risk on /login and /dashboard.)
const securityHeaders = [
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
