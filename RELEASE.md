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

- `DEVELOPMENT_TEAM` is now set to `QDKSUX27F9` on both targets, and the simulator build (`Rinkler` scheme, `iphonesimulator`, `CODE_SIGNING_ALLOWED=NO`) compiles the app and packet-tunnel extension cleanly.
- Signed device install is still blocked until Xcode has a signed-in Apple Developer account with matching provisioning profiles for the app, tunnel, and App Group, plus an approved Network Extension entitlement.
- On-device UX smoke testing (VPN start/stop, OTP login, traffic sync) still requires a signed build on a physical iPhone; the simulator cannot exercise the Network Extension packet tunnel.
- Section-only blocking for YouTube Shorts and other mainstream short-video surfaces needs a different, App-Store-safe architecture or verified app-specific hosts. The current local VPN tunnel must not claim that precision or it will break normal YouTube/social app behavior.
- Web checks (`pnpm typecheck`, `pnpm lint`, `pnpm build`) pass with the pinned `pnpm@9.15.4`.
- Re-run `pnpm audit` after any lockfile change and before each release.

## Social Sign-In (Apple / Google)

Onboarding ends with an account step offering **Sign in with Apple** and
**Continue with Google**. The code is wired (`SocialAuthService`,
`SupabaseAuthClient.signInWithApple` / `oauthAuthorizeURL` / `completeOAuth`,
`rinkler://auth-callback` URL scheme, `com.apple.developer.applesignin`
entitlement), but the following account-side config is required for it to work on
a device — it cannot be done from the source tree:

Apple Developer portal:
- Enable the **Sign in with Apple** capability on the `com.rinkler.app` App ID.
- Regenerate the provisioning profile after enabling it.

Supabase dashboard (Authentication → Providers):
- **Apple**: enable the provider; set Services ID / Team ID / Key ID / private
  key. For the native iOS `id_token` flow, add the app bundle id
  `com.rinkler.app` to the Apple provider's authorized client IDs.
- **Google**: enable the provider; set the OAuth client ID + secret (Google Cloud
  console, OAuth consent screen configured).
- Authentication → URL Configuration → **Redirect URLs**: add
  `rinkler://auth-callback` to the allow list.

Verify on a physical iPhone: Apple sign-in returns to the app signed in; Google
opens the web sheet and returns to `rinkler://auth-callback` signed in; "Maybe
later" skips without an account; the session persists across relaunch (Landing →
Today without re-auth). The official Google logo asset can be dropped into
`Assets.xcassets` as `google-logo` and swapped into `GoogleGlyph`.

## Supabase Data

Use Supabase for auth and server-side dashboard data only. Rinkler stores destination hostnames, block status, byte counts, timestamps, and minimal event metadata for dashboard summaries. Keep packet contents, screenshots, private text, auth tokens, and full request bodies out of logs and external APIs unless the user explicitly approves that data flow.
