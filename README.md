# Rinkler

Rinkler is an iOS network-filtering app for keeping useful app features available while blocking distracting traffic. The iOS app uses a local Network Extension tunnel and a Supabase-backed email OTP login flow.

The current production filters target large Instagram and TikTok short-video media streams. Filtering is enforced locally in the packet tunnel by SNI/domain and byte thresholds; it does not decrypt traffic or inspect private page contents. YouTube Shorts, Facebook Reels, Snapchat Spotlight, X video, Reddit video, and similar sections are not enabled as section-only blockers because they share hosts with normal app traffic at the tunnel layer. Adding those without verified path-level visibility would overblock legitimate app features.

## Repo Layout

- `apps/ios` - SwiftUI iOS app and packet tunnel source.
- `apps/web` - Next.js dashboard for traffic summaries and insights.
- `packages/mcp-server` - Supabase-backed MCP tools for blocker state.
- `packages/assets` - shared static assets.
- `supabase` - database migrations.

## Local Setup

Create `apps/ios/Secrets.xcconfig` from `apps/ios/Secrets.xcconfig.example`:

```xcconfig
SUPABASE_URL = https:/$()/YOUR_PROJECT.supabase.co
SUPABASE_KEY = YOUR_SUPABASE_PUBLISHABLE_KEY
```

Do not commit real keys. The checked-in `.gitignore` keeps local secrets and build output out of git.

For web development, install the pinned package manager from `package.json`, then run:

```bash
pnpm install
pnpm typecheck
pnpm lint
pnpm build
```

The pinned package manager is `pnpm@9.15.4` (see `packageManager` in `package.json`); enable it with `corepack enable` if needed. Regenerate `pnpm-lock.yaml` after any dependency change.

Apply the Supabase schema before using the dashboard or MCP server:

```bash
supabase db push
```

The iOS app uploads terminal traffic events to `traffic_events` only after a user is signed in. The database trigger keeps hourly and daily `traffic_summaries` current for the web dashboard, so production does not need mock analytics rows.

The web dashboard uses the same email-code Supabase auth flow as iOS. Configure the Supabase email template to include the OTP token if you want numeric code entry, and keep `/auth/callback` enabled if you also support magic links.

`ENABLE_EXTERNAL_AI_INSIGHTS` defaults to `false`. Leave it disabled unless you intentionally want dashboard summary statistics sent to the configured external AI provider.

`ENABLE_DASHBOARD_ADMIN_TOOLS` and `NEXT_PUBLIC_ENABLE_DASHBOARD_ADMIN_TOOLS` default to `false`. Only enable them for trusted maintenance sessions because those endpoints run service-role rollups and domain classification.

`GET /api/health` is a public, unauthenticated liveness/readiness probe (returns `{status:"ok",...}` with no user data) for load balancers and uptime monitors.

The MCP server (`packages/mcp-server`) runs with the Supabase service-role key. When served over HTTP it **requires** `MCP_API_KEY` (a strong shared secret, ≥16 chars) and refuses to start without one; it binds to `127.0.0.1` by default (set `MCP_HOST=0.0.0.0` only behind a proxy/LB). The `stdio` transport (`MCP_TRANSPORT=stdio`) is local-only and needs no key.

## Release State

Rinkler builds unsigned for iPhoneOS with the app and packet tunnel extension. Release still requires Apple Developer signing/provisioning, Network Extension entitlement approval, App Store Connect app setup, and physical-device VPN testing with a signed build.

See `RELEASE.md` for the remaining production checklist.
