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
SUPABASE_KEY = YOUR_SUPABASE_ANON_KEY
```

Do not commit real keys. The checked-in `.gitignore` keeps local secrets and build output out of git.

For web development, install the pinned package manager from `package.json`, then run:

```bash
pnpm install
pnpm typecheck
pnpm build
```

This machine currently does not have `pnpm` available, so regenerate `pnpm-lock.yaml` on a machine with pnpm before relying on web dependency changes.

## Release State

Rinkler is not App Store-ready yet. The main app compiles at the Swift typecheck level, but the checked-in Xcode project still needs a real packet tunnel extension target before the VPN functionality can ship.

See `RELEASE.md` for the remaining production checklist.
