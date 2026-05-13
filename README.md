# Rinkler

Rinkler is an iOS network-filtering app for keeping useful app features available while blocking distracting traffic. The iOS app uses a local Network Extension tunnel and a Supabase-backed email OTP login flow.

## Repo Layout

- `apps/ios` - SwiftUI iOS app and packet tunnel source.
- `apps/web` - Next.js dashboard for traffic summaries and insights.
- `packages/mcp-server` - Supabase-backed MCP tools for blocker state.
- `packages/assets` - shared static assets.
- `quinn` - local filtering/proxy prototype code.
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
pnpm build
```

This machine currently does not have `pnpm` available, so regenerate `pnpm-lock.yaml` on a machine with pnpm before relying on web dependency changes.

Apply the Supabase schema before using the dashboard or MCP server:

```bash
supabase db push
```

The iOS app uploads terminal traffic events to `traffic_events` only after a user is signed in. The database trigger keeps hourly and daily `traffic_summaries` current for the web dashboard, so production does not need mock analytics rows.

`ENABLE_EXTERNAL_AI_INSIGHTS` defaults to `false`. Leave it disabled unless you intentionally want dashboard summary statistics sent to the configured external AI provider.

## Release State

Rinkler builds unsigned for iPhoneOS with the app and packet tunnel extension. Release still requires Apple Developer signing/provisioning, Network Extension entitlement approval, App Store Connect app setup, and physical-device VPN testing with a signed build.

See `RELEASE.md` for the remaining production checklist.
