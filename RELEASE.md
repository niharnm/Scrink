# Rinkler Release Checklist

## Required Before TestFlight

- Set the Apple Developer Team ID in the app and tunnel targets.
- Enable App Groups and Network Extension capabilities for:
  - `com.rinkler.app`
  - `com.rinkler.app.tunnel`
  - `group.com.rinkler.app`
- Confirm the Network Extension entitlement is approved for the Apple Developer account.
- Replace `apps/ios/Secrets.xcconfig` local placeholders with the real Supabase project URL and publishable key.
- Apply all migrations in `supabase/migrations` to the real Supabase project.
- Test OTP login against the real Supabase project on a physical iPhone.
- Test VPN start, stop, reconnect, and app relaunch behavior on a physical iPhone.
- Confirm traffic events upload after sign-in and that the web dashboard summaries update without mock rows.
- Confirm no sensitive traffic details, auth tokens, or user content are logged.
- Update App Store privacy nutrition labels to match actual behavior. Do not claim data stays only on-device if Supabase auth or dashboard storage is enabled.
- Keep `ENABLE_EXTERNAL_AI_INSIGHTS=false` unless users explicitly opt into sending aggregate dashboard stats to the configured AI provider.

## App Store Connect Setup

- Register `com.rinkler.app` and `com.rinkler.app.tunnel` in Certificates, Identifiers & Profiles before creating the App Store Connect app record.
- Use `com.rinkler.app` as the app Bundle ID and a stable SKU such as `rinkler-ios`.
- Add `group.com.rinkler.app` to both targets after the App Group exists.
- Do not submit until a signed physical-device build has passed VPN start/stop, OTP login, traffic sync, and dashboard checks.

## Current Verification Gaps

- Unsigned iPhoneOS builds pass, but signed device install is blocked until Xcode has a signed-in Apple Developer account and matching provisioning profiles for the app, tunnel, and App Group.
- Simulator listing is affected by an Xcode/CoreSimulator mismatch:
  `CoreSimulator is out of date. Current version (1051.50.0) is older than build version (1051.54.0).`
- The local machine has Node but no `pnpm`, `npm`, or `corepack`, so web build, typecheck, and lockfile regeneration were not run here.
- GitHub reports dependency alerts on the default branch. Review Dependabot after the next dependency install and lockfile refresh.

## Supabase Data

Use Supabase for auth and server-side dashboard data only. Rinkler stores destination hostnames, block status, byte counts, timestamps, and minimal event metadata for dashboard summaries. Keep packet contents, screenshots, private text, auth tokens, and full request bodies out of logs and external APIs unless the user explicitly approves that data flow.
