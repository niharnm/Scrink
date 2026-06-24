# Auto-deliver Rinkler to your phone via TestFlight

Goal: `git push` to `main` (touching `apps/ios/**`) → GitHub Actions builds + signs the
app → uploads to TestFlight → your phone updates **automatically**.

The repo side is already wired (shared scheme, fastlane, two workflows). You need to
do the one-time Apple/GitHub setup below. Budget ~30 minutes. After that it's hands-off.

---

## Why it can't just "pull from GitHub"
An app installed via Xcode is compiled native code, and iOS forbids an app from
replacing its own binary — there's no way for the installed app to watch the repo and
update itself. TestFlight is the supported channel for OTA build delivery, so that's
what this uses. Rinkler's Network Extension is native Swift, so JS-style OTA (CodePush
/ Expo) can't apply to it either.

---

## Step 1 — App Store Connect API key  (~3 min)
1. https://appstoreconnect.apple.com → **Users and Access → Integrations → App Store Connect API**.
2. **Generate API Key** (or use the "Keys" tab). Access role: **App Manager**.
3. Note the **Key ID** and the **Issuer ID** (shown above the key list).
4. **Download the `.p8`** — you only get one chance. Keep it safe.

## Step 2 — Make sure the app record exists  (~1 min)
In App Store Connect → **Apps**, confirm there's an app with bundle id
`com.rinkler.app`. If not, **+ → New App**, platform iOS, pick that bundle id.
(TestFlight can't accept a build for an app that doesn't exist yet.)

## Step 3 — Private certs repo for fastlane match  (~1 min)
Create a new **empty private** GitHub repo, e.g. `niharnm/Rinkler-certs`. This is where
match stores your distribution cert + profiles, encrypted. Leave it empty.

## Step 4 — A PAT so CI can read that certs repo  (~2 min)
GitHub → **Settings → Developer settings → Personal access tokens → Fine-grained tokens**.
- Repository access: only `Rinkler-certs`.
- Permission: **Contents → Read and write**.
- Generate, copy the token (`github_pat_...`).

Then base64-encode `username:token` (any username works with a PAT):
```bash
printf 'niharnm:github_pat_XXXX' | base64
```
Copy the output — that's `MATCH_GIT_BASIC_AUTHORIZATION`.

## Step 5 — Add the GitHub Secrets  (~5 min)
In the **Rinkler** repo → **Settings → Secrets and variables → Actions → New repository secret**.
Add each:

| Secret | Value |
|---|---|
| `ASC_KEY_ID` | Key ID from Step 1 |
| `ASC_ISSUER_ID` | Issuer ID from Step 1 |
| `ASC_KEY_P8` | the **entire contents** of the `.p8` file (paste the text, `-----BEGIN PRIVATE KEY-----` … included) |
| `MATCH_GIT_URL` | `https://github.com/niharnm/Rinkler-certs.git` |
| `MATCH_PASSWORD` | invent a strong passphrase — this encrypts the certs. Save it in your password manager. |
| `MATCH_GIT_BASIC_AUTHORIZATION` | base64 string from Step 4 |

To paste the `.p8` contents quickly:
```bash
pbcopy < /path/to/AuthKey_XXXXXX.p8   # now paste into ASC_KEY_P8
```

## Step 6 — Seed the signing assets  (~3 min, one click)
Rinkler repo → **Actions → "iOS Signing Seed" → Run workflow** (on `main`).
This creates your **Apple Distribution** certificate and the three App Store
provisioning profiles (app, tunnel, activityreport) and stores them in `Rinkler-certs`.
Wait for it to go green. You never had to install fastlane locally.

## Step 7 — Ship the first build
Either push any change under `apps/ios/`, or run **Actions → "iOS TestFlight" → Run
workflow** manually. It builds, bumps the build number, and uploads to TestFlight.
First Apple-side processing takes a few minutes.

## Step 8 — Turn on automatic updates on the phone  (~1 min)
On your iPhone, open **TestFlight → Rinkler → enable "Automatic Updates"** (and make
sure you've accepted the tester invite for your Apple ID — add yourself as an Internal
Tester under App Store Connect → your app → TestFlight if needed). From now on every
push that lands a TestFlight build auto-installs on your phone.

---

## After setup — the daily loop
```
edit iOS code → commit → push to main → (CI builds + uploads) → phone auto-updates
```
Internal TestFlight builds skip Apple review, so turnaround is just CI + processing
time (typically 5–15 min end to end).

## Notes & gotchas
- **Build numbers** auto-increment from the GitHub run number; you don't manage them.
  Bump the marketing version (`CFBundleShortVersionString`, currently `1.0`) by hand in
  the three Info.plists when you want a new user-facing version.
- **Network Extension entitlement**: the `.tunnel` target needs the Network Extensions
  capability enabled on its App ID in the Developer portal. If the seed step errors on
  the tunnel profile, enable it under Certificates, IDs & Profiles → Identifiers →
  `com.rinkler.app.tunnel` → Capabilities, then re-run the seed.
- **Free vs paid**: this requires your paid Developer Program membership (you have it).
- **Cost**: GitHub-hosted macOS minutes are billed at a higher multiplier; a build is a
  few minutes. Fine for normal use; if it gets heavy, consider a self-hosted Mac runner.
- **Re-running seed** is safe — match reuses existing certs/profiles.
