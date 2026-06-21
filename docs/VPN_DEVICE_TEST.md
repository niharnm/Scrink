# VPN on-device test & sign-off checklist

The packet-tunnel cannot run in the iOS Simulator and cannot be exercised
without a **signed build on a physical device** (the Network Extension
entitlement must be approved on the Apple Developer account — see `RELEASE.md`).
The code changes below are reasoned fixes; this checklist is how you confirm them
on real hardware before publishing.

## Pre-reqs
- [ ] Network Extension + App Groups + Personal VPN capabilities enabled in the
      developer portal for both `com.rinkler.app` and `com.rinkler.app.tunnel`.
- [ ] `apps/ios/Secrets.xcconfig` filled with the real Supabase URL/key.
- [ ] `DEVELOPMENT_TEAM` set in `project.yml` and a signed build installed on a
      physical iPhone.

## A. Tunnel stays up (the "drops after 5s" bug)
1. [ ] Launch app → **Start Protection** → approve the VPN profile prompt.
2. [ ] Watch the protection card: status should reach **Connected** and **stay**
       connected past 30s (previously dropped ~5s).
3. [ ] Open the in-app tunnel log (Settings → extension log) and confirm you see
       `STEP 3 SUCCESS` and **not** `exit code -1 ... utun fd was NOT found`.
4. [ ] Browse a normal site (e.g. apple.com) — pages should load through the
       tunnel. This confirms `tun2socks` found the utun fd and traffic flows.

**If it still drops:** capture the real reason. On a Mac with the device
connected, open **Console.app** → select the device → filter on
`com.rinkler.app.tunnel`. The tunnel log also records the exact
`NEProviderStopReason` in `stopTunnel(...)`. The most useful lines:
   - `STEP 1 FAILED` → network-settings rejected (MTU/routes).
   - `STEP 3: tun2socks EXITED with code -1` → fd not found (signing/entitlement).
   - `stopTunnel (reason: providerFailed/...)` → tells you who tore it down.
Send me those lines and I can pin the cause precisely.

> What changed in code: the tunnel MTU was lowered from a non-standard 9000 to
> the conventional 1500. 9000 is not a valid path MTU to real servers and is a
> plausible cause of stalls/teardown. If logs show a *different* stop reason,
> that points at signing/entitlements rather than code.

## B. Reels / Shorts / TikTok actually get blocked
With all three filters ON and protection connected:
1. [ ] **Instagram** → open Reels, scroll. Video should stall/refuse to play
       after the first clip. Tunnel log should show `STREAM BLOCK` (TCP/TLS path)
       and/or `QUIC BLOCKED ... (tracked CDN)` (UDP/443 path).
2. [ ] **TikTok** → open the For You feed. Same expectation.
3. [ ] **YouTube** → open Shorts. Same expectation.
4. [ ] Confirm the **non-blocked** parts still work: Instagram DMs, search,
       posting; YouTube regular (long-form) video if its filter is the only thing
       you intend to limit.
5. [ ] Toggle a filter OFF → that app's video should play normally again
       (verifies per-app enable is respected).

> What changed in code: video on these apps rides QUIC (HTTP/3, UDP 443), which
> the old build relayed untouched — so the byte-threshold blocker never saw it.
> Rinkler now learns which IPs belong to the tracked CDNs (by snooping plaintext
> DNS answers and TLS SNI) and drops UDP/443 to *only those* IPs, forcing the
> apps onto TCP/TLS where the existing 0.5 MB stream-kill works.

## C. Known limitations to verify against your expectations
- [ ] **Encrypted DNS (DoH/DoT):** if an app resolves names over encrypted DNS,
      the DNS-snoop path won't learn its IPs. The TLS-SNI learning path still
      catches IPs once any TCP/443 connection to the CDN is seen. Watch for any
      app whose video keeps playing — its log line `[UNTRACKED-LARGE]` flags a
      domain getting big downloads with no rule.
- [ ] **Threshold feel:** 0.5 MB per stream ≈ ~1s of video before the cut. Adjust
      `streamBlockDefaultThreshold` in `RinklerConstants.swift` if you want it
      tighter/looser.
- [ ] **Other apps' QUIC is untouched** (we only block tracked CDN IPs) — confirm
      general browsing speed is unaffected.
