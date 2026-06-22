# Screen-time app research → Rinkler roadmap

Notes from reviewing what people actually praise and complain about in screen-time
/ digital-wellbeing apps (Apple Screen Time, Opal, One Sec, Freedom, ScreenZen,
Forest, UNDOOMED), mapped to where Rinkler stands today. Sources at the bottom.

## Where Rinkler already fits

Rinkler's bet — block the addictive *part* (Reels, Shorts, TikTok feed) while
leaving DMs, search, and posting alone — is the same niche UNDOOMED occupies, and
it's the thing people say they want. Blanket "block the whole app" tools (Freedom,
Opal) get uninstalled because they're all-or-nothing. Surgical blocking is the
differentiator; lead with it.

## What users praise (build toward these)

- **Surgical / part-level blocking.** Keep useful features, cut the infinite feed.
  Rinkler's per-domain byte-threshold + QUIC fallback is exactly this. ✅ core
- **Schedules & focus windows.** Auto-enforce during work/sleep without toggling
  by hand. Rinkler has none yet — protection is fully manual. ⬜ high value
- **Friction instead of hard walls.** One Sec's breathing-pause before a blocked
  app reduces use more than a brick wall (people just turn brick walls off). A
  short "are you sure?" interstitial would fit Rinkler. ⬜
- **Insights that mean something.** Not just "3h today" — patterns, time-of-day,
  "you opened Reels 40× before noon." Rinkler already collects rich traffic data
  (TrafficMonitor + dashboard); turn it into plain-language insight. 🟡 partial
- **Gamification / streaks.** Forest's tree, streak counts, "days protected."
  Cheap to add on top of existing VPN-uptime data, strong retention lever. ⬜
- **Grayscale / wind-down.** Common, well-liked. Out of scope for a VPN app
  (needs system control), but worth a mention as "use alongside iOS Wind Down."

## What users complain about (the failure modes to avoid)

- **"Ridiculously easy to beat."** The #1 complaint about Apple Screen Time and
  most blockers: delete/reinstall, change the clock, incognito, new account, or
  just turn the VPN off. **This is Rinkler's biggest exposure** — a one-tap VPN
  toggle is the easiest bypass there is.
  → Add a **commitment mode**: make turning protection *off* the high-friction
    action (a deliberate delay, a typed confirmation, or an accountability
    partner), not turning it on. This converts the weakness into the moat.
- **Privacy fear of VPN apps.** A VPN can see all traffic, so users are wary of
  "free VPN blockers." Rinkler's advantage: the tunnel is **local-only** — no
  traffic leaves the device, nothing is proxied to a server. Say this loudly on
  the landing/App Store page; it's a real trust win.
- **Over-blocking / breaking other apps.** Heavy-handed rules (e.g. global UDP/443
  blocks) slow unrelated browsing. Rinkler now scopes QUIC blocking to tracked
  CDN IPs only — keep it that way; don't regress to global blocks.
- **Battery / "VPN always on" anxiety.** Keep the tunnel lean (the extension runs
  under a tight memory budget). Watch the per-second stats-file writes.
- **Silent failure.** Users hate when a blocker looks on but isn't working — which
  is precisely the "turns on, drops after 5s" report. Surface tunnel health
  honestly in the UI (the protection card already reflects status; consider a
  "last blocked X reels today" confidence signal).

## Suggested near-term order

1. ~~**Commitment / disable-friction mode**~~ — ✅ shipped (`CommitmentMode.swift`).
   Friction on turning protection *off* (cooldown + typed confirm), with an honest
   "iOS Settings can still kill the VPN" caveat and accountability receipts. Also
   Rinkler's most original angle — it turns the bypass into visible self-data
   instead of pretending to be unbreakable.
2. **Schedules** (block feeds 9–5, or after bedtime) — most-requested missing piece.
   Note: reliable *background* enforcement needs the app/extension awake on a
   schedule; a foreground/best-effort version is the realistic first cut.
3. **Plain-language insights + a streak** — leverages data you already collect (the
   streak already exists; turn traffic stats into "Reels intercepted today" and
   time-of-day patterns).
4. **Pre-open friction interstitial** — a true app-launch pause needs the Screen
   Time / FamilyControls API (a network tunnel can't intercept app opens). The
   Commitment Mode pause is the on-brand version Rinkler can ship today.

## Sources

- [UNDOOMED — block the addictive parts, keep the useful ones](https://sevag.app/undoomed/)
- [UNDOOMED — Best digital wellbeing apps 2025](https://undoomed.app/blog/best-digital-wellbeing-apps-2025-guide)
- [Protect Young Eyes — 12 ways people beat Screen Time](https://www.protectyoungeyes.com/blog-articles/12-ingenious-screen-time-hacks-how-to-beat-them)
- [Cloudwards — how Screen Time gets bypassed](https://www.cloudwards.net/how-to-hack-screen-time/)
- [ScreenZen — friction-based blocking](https://screenzen.co/)
- [Android Digital Wellbeing — limits, grayscale, focus, bedtime](https://www.android.com/digital-wellbeing/)
