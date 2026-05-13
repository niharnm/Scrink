# Rinkler Release Checklist

## Required Before TestFlight

- Set the Apple Developer Team ID in the app and tunnel targets.
- Enable App Groups and Network Extension capabilities for:
  - `com.rinkler.app`
  - `com.rinkler.app.tunnel`
  - `group.com.rinkler.app`
- Confirm the Network Extension entitlement is approved for the Apple Developer account.
- Replace `apps/ios/Secrets.xcconfig` local placeholders with the real Supabase project URL and anon key.
- Apply `supabase/migrations/20260513000000_initial_schema.sql` to the real Supabase project.
- Test OTP login against the real Supabase project on a physical iPhone.
- Test VPN start, stop, reconnect, and app relaunch behavior on a physical iPhone.
- Confirm no sensitive traffic details, auth tokens, or user content are logged.
- Update App Store privacy nutrition labels to match actual behavior. Do not claim data stays only on-device if Supabase auth or dashboard storage is enabled.
- Keep `ENABLE_EXTERNAL_AI_INSIGHTS=false` unless users explicitly opt into sending aggregate dashboard stats to the configured AI provider.

## Current Verification Gaps

- Full `xcodebuild` is blocked on this Mac by an Xcode/CoreSimulator mismatch:
  `CoreSimulator is out of date. Current version (1051.50.0) is older than build version (1051.54.0).`
- The local machine has Node but no `pnpm`, `npm`, or `corepack`, so web build, typecheck, and lockfile regeneration were not run here.
- GitHub reports dependency alerts on the default branch. Review Dependabot after the next dependency install and lockfile refresh.

## Supabase Data

Use Supabase for auth and server-side dashboard data only. Keep packet contents, screenshots, private text, and raw personal browsing details out of logs and external APIs unless the user explicitly approves that data flow.
