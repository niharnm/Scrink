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
- Test web dashboard OTP login with the same Supabase project used by iOS.
- Test VPN start, stop, reconnect, and app relaunch behavior on a physical iPhone.
- Test Instagram and TikTok video feeds with each filter enabled and disabled. Rinkler intentionally does not ship a YouTube Shorts, Facebook Reels, Snapchat Spotlight, X video, Reddit video, or Threads/Reels section blocker yet because the current tunnel sees host/SNI metadata, not HTTPS paths or in-app section state.
- Confirm traffic events upload after sign-in and that the web dashboard summaries update without mock rows.
- Confirm no sensitive traffic details, auth tokens, or user content are logged.
- Update App Store privacy nutrition labels to match actual behavior. Do not claim data stays only on-device if Supabase auth or dashboard storage is enabled.
- Keep `ENABLE_EXTERNAL_AI_INSIGHTS=false` unless users explicitly opt into sending aggregate dashboard stats to the configured AI provider.
- Keep `ENABLE_DASHBOARD_ADMIN_TOOLS=false` and `NEXT_PUBLIC_ENABLE_DASHBOARD_ADMIN_TOOLS=false` for public deployments unless you are running a trusted maintenance session.

## App Store Connect Setup

- Register `com.rinkler.app` and `com.rinkler.app.tunnel` in Certificates, Identifiers & Profiles before creating the App Store Connect app record.
- Use `com.rinkler.app` as the app Bundle ID and a stable SKU such as `rinkler-ios`.
- Add `group.com.rinkler.app` to both targets after the App Group exists.
- Do not submit until a signed physical-device build has passed VPN start/stop, OTP login, traffic sync, and dashboard checks.

## Current Verification Gaps

- Unsigned iPhoneOS builds pass, but signed device install is blocked until Xcode has a signed-in Apple Developer account and matching provisioning profiles for the app, tunnel, and App Group.
- The latest signed iPhoneOS build probe failed because both targets have an empty `DEVELOPMENT_TEAM`. After setting the Apple Developer Team ID, matching provisioning profiles and Network Extension/App Group entitlements are still required.
- Simulator UX smoke testing is currently blocked on this machine. The simulator can report `Booted`, but install/launch commands hang and screenshots show only the system spinner.
- Section-only blocking for YouTube Shorts and other mainstream short-video surfaces needs a different, App-Store-safe architecture or verified app-specific hosts. The current local VPN tunnel must not claim that precision or it will break normal YouTube/social app behavior.
- The local machine still has no installed `pnpm`, `npm`, or `corepack`. Web checks were run with a temporary pnpm 9.15.4 executable under `/tmp`.
- `pnpm audit --json` currently reports zero known dependency advisories after the lockfile refresh.

## Supabase Data

Use Supabase for auth and server-side dashboard data only. Rinkler stores destination hostnames, block status, byte counts, timestamps, and minimal event metadata for dashboard summaries. Keep packet contents, screenshots, private text, auth tokens, and full request bodies out of logs and external APIs unless the user explicitly approves that data flow.
