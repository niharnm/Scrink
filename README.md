# Rinkler

Rinkler is an iOS network-filtering app for keeping useful app features available while blocking distracting traffic. The iOS app uses a local Network Extension tunnel and a Supabase-backed email OTP login flow.

The current production filters target large Instagram and TikTok short-video media streams. Filtering is enforced locally in the packet tunnel by SNI/domain and byte thresholds; it does not decrypt traffic or inspect private page contents. Short-video that rides QUIC (HTTP/3, UDP 443) is forced back onto TCP/TLS — where the byte-threshold blocker can act — by dropping UDP 443 to only the CDN IPs Rinkler has learned belong to a tracked app (from plaintext DNS answers and TLS SNI). YouTube Shorts, Facebook Reels, Snapchat Spotlight, X video, Reddit video, and similar sections are not enabled as section-only blockers because they share hosts with normal app traffic at the tunnel layer. Adding those without verified path-level visibility would overblock legitimate app features.

## Screenshots

Captures live in [`docs/screenshots/`](docs/screenshots/) — see that folder's README for how to add them on a Mac.

| Home | Focus session | Dashboard |
|------|---------------|-----------|
| ![Home](docs/screenshots/home.png) | ![Focus session](docs/screenshots/focus-session.png) | ![Dashboard](docs/screenshots/dashboard.png) |

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
pnpm build
```

This machine currently does not have `pnpm` available, so regenerate `pnpm-lock.yaml` on a machine with pnpm before relying on web dependency changes.

Apply the Supabase schema before using the dashboard or MCP server:

```bash
supabase db push
```

The iOS app uploads terminal traffic events to `traffic_events` only after a user is signed in. The database trigger keeps hourly and daily `traffic_summaries` current for the web dashboard, so production does not need mock analytics rows.

The web dashboard uses the same email-code Supabase auth flow as iOS. Configure the Supabase email template to include the OTP token if you want numeric code entry, and keep `/auth/callback` enabled if you also support magic links.

`ENABLE_EXTERNAL_AI_INSIGHTS` defaults to `false`. Leave it disabled unless you intentionally want dashboard summary statistics sent to the configured external AI provider.

`ENABLE_DASHBOARD_ADMIN_TOOLS` and `NEXT_PUBLIC_ENABLE_DASHBOARD_ADMIN_TOOLS` default to `false`. Only enable them for trusted maintenance sessions because those endpoints run service-role rollups and domain classification.

## Protecting `main`

`main` should only change through a merged pull request. After cloning, enable the tracked git hooks once:

```bash
./scripts/setup-hooks.sh   # sets core.hooksPath=.githooks
```

This installs a `pre-push` hook that blocks direct pushes, force-pushes, and deletions of `main` from your machine (bypass a real emergency with `git push --no-verify`).

Server-side protection on GitHub is the stronger guarantee but, for a **private** repo, requires GitHub Pro/Team or making the repo public. Once you're on a supporting plan, add a branch ruleset for `main` (Settings → Rules → Rulesets): restrict deletions, block force pushes, and require a pull request before merging.

## Release State

Rinkler builds unsigned for iPhoneOS with the app and packet tunnel extension. Release still requires Apple Developer signing/provisioning, Network Extension entitlement approval, App Store Connect app setup, and physical-device VPN testing with a signed build.

See `RELEASE.md` for the remaining production checklist.
