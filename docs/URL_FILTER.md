# iOS 26 URL Filter — the precise per-feed engine (scaffold + requirements)

This is the "block Reels, keep DMs" engine. Unlike the VPN tunnel (which only
sees hostnames + byte counts and so can't tell a feed apart from useful traffic
on shared hosts), Apple's **iOS 26 NetworkExtension URL Filter** matches the
**full URL** system-wide, privately. It's the right long-term core per the
architecture decision; the VPN stays as the best-effort fallback.

Verified at WWDC25 ("Filter and tunnel network traffic with NetworkExtension"):

## What it is
- System-wide HTTP/HTTPS filtering that can match the **entire URL** (path +
  query), not just host — exactly what Reels-vs-DMs needs.
- Checks all requests made via Apple networking (URLSession, WebKit)
  automatically. Apps that roll their own networking must adopt the
  participation API to be covered (most social apps use system networking for
  media, so this reaches the feeds we care about).
- Privacy-preserving by design: the system answers matches using **Bloom
  filters + Private Information Retrieval (PIR) + Privacy Pass + Oblivious HTTP
  Relay**, so Rinkler never sees the user's URLs.

## What it requires (the honest cost)
1. **Entitlement:** `com.apple.developer.networking.networkextension.url-filter-provider`
   — request in the Developer portal. App Store distribution of this entitlement
   is **approval-gated** by Apple (like Family Controls).
2. **A PIR server we host:** the blocklist (our `urlPatterns` from
   `BlockCatalog`) is compiled into a **Bloom filter** served from a Private
   Information Retrieval endpoint. The device queries it privately. This is a
   real backend component to build + operate, not just app code.
3. **iOS 26+ device.** Gate all of it behind `@available(iOS 26, *)` and degrade
   to the VPN/Shield tiers below 26.
4. **A URL-filter app-extension target** (`RinklerURLFilter`) configured via
   `NEURLFilterManager.shared` from the app.

## How our pieces feed it
- `BlockCatalog` already carries `urlPatterns` per feature (e.g.
  `instagram.com/reels/*`, `youtubei.googleapis.com/*/shorts*`). Those are the
  source list compiled into the Bloom filter.
- `RuleRegistry` (Supabase `block_rules`) already ships rule-pack updates without
  an App Store release — the same packs regenerate the Bloom filter server-side.
- `BlockSelectionStore` already records which features the user wants killed; the
  URL filter consults that to decide enforce vs. allow.

## Fallback ladder (what runs when)
1. **iOS 26 + entitlement + PIR up** → URL Filter: precise per-feed (best).
2. **Family Controls Shield** (entitlement) → whole-app hard block (reliable).
3. **VPN host filter** (today) → best-effort feed block on distinct hosts.
4. If a platform moves endpoints and a rule goes stale → degrade to whole-app
   shield + flag it in the UI ("Reels block degraded — lock the app instead").

## Activation steps (when ready)
1. Request the `url-filter-provider` entitlement from Apple.
2. Add a `RinklerURLFilter` app-extension target (Xcode → New Target →
   Network Extension; pick the URL Filter provider) + its entitlements
   (url-filter-provider + App Group). Register in `project.yml` **and**
   `project.pbxproj` (mirror the `RinklerTunnel` wiring).
3. Stand up the PIR/Bloom-filter server from the active `block_rules` pack.
4. Implement `apps/ios/RinklerURLFilter/URLFilterProvider.swift` (skeleton
   alongside this doc) against the **iOS 26 SDK** — verify the exact
   `NEURLFilterManager` / provider symbols before relying on them; they're new
   in 2025 and must be checked against the installed SDK, not from memory.

> Status: scaffolded + documented. Not wired into the build yet because the
> entitlement (and the matching provisioning profile) aren't granted — adding the
> target now would break signing, exactly like Family Controls did. Flip it on
> once Apple approves the entitlement.
