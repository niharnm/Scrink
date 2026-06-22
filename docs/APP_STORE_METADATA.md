# Rinkler — App Store Listing & Metadata

Draft copy and submission notes for App Store Connect. Fill the `[BRACKETED]`
items. Character limits are Apple's; stay under them.

---

## Core listing

**App name** (max 30 chars)
```
Rinkler: Scroll Less
```
(Alt if taken: `Rinkler — Focus & Scroll Less`)

**Subtitle** (max 30 chars)
```
Block reels, reclaim focus
```

**Primary category:** Productivity
**Secondary category:** Health & Fitness (or Lifestyle)

**Age rating:** 4+ (no objectionable content). Note: the app helps *limit*
social media; it does not contain it.

---

## Promotional text (max 170 chars — editable any time without review)
```
Your phone isn't the problem — the infinite scroll is. Rinkler quietly
interrupts Reels and TikTok so you keep the useful parts and lose the trap.
```

## Description (max 4000 chars)
```
Rinkler helps you scroll less without deleting the apps you actually use.

Most "focus" apps just block everything and leave you locked out. Rinkler is
sharper: it interrupts the infinite short-video feeds designed to pull you in —
Instagram Reels, TikTok — while keeping DMs, search, and messages working.

HOW IT WORKS
Rinkler sets up an on-device filter (a private VPN configuration that never
sends your traffic to a server) and interrupts short-video streams based on
your rules. Everything happens locally on your iPhone.

BUILD YOUR FOCUS SYSTEM
A quick setup asks what pulls you in and when you lose control, then builds a
personal system for you — Homework Mode, Night Lock, School Mode, a clean
morning start. No fiddling with settings; it's ready before you finish.

CONTROL SESSIONS
Start a focus session in one tap. Choose how strict: Gentle, Focused, or a
locked Deep session you can't quit early. Watch real focused time and blocked
pulls add up — every number is real, nothing is faked.

PROGRESS THAT MEANS SOMETHING
A Scroll Report shows what you actually cut. Earn Signal Rings as you build
streaks and reclaim hours.

HONEST BY DESIGN
- Rinkler filters traffic locally. It does not read your messages, posts, or
  the content of anything you do.
- It is not a content VPN and does not hide your IP.
- We don't sell your data or show ads.

Take back your attention. Start with ten minutes.
```

## Keywords (max 100 chars, comma-separated, no spaces)
```
focus,scroll,reels,tiktok,screen time,blocker,distraction,productivity,study,doomscroll,habit,limit
```

## URLs
- **Support URL:** [e.g. https://rinkler.app/support or a GitHub page]
- **Marketing URL (optional):** [e.g. https://rinkler.app]
- **Privacy Policy URL (required):** [host docs/PRIVACY.md and put the URL here]

---

## App Privacy "nutrition labels" (App Store Connect → App Privacy)

Declare these so they match `docs/PRIVACY.md` (Apple rejects mismatches).

**Data used to track you:** None.

**Data linked to you:**
- **Contact Info → Email Address** — App Functionality (account/auth).
- **Identifiers → User ID** — App Functionality.
- **Usage Data → Product Interaction** — App Functionality (blocked-connection
  metadata: hostnames, categories, byte counts, timestamps, block status that
  power the dashboard).

**Data not linked to you:** None beyond the above (keep it simple).

**Explicitly NOT collected:** location, contacts, photos, messages/content,
browsing/search history content, financial info, health data, audio.

> If you enable the optional AI insights feature, review whether the "Usage
> Data" disclosure needs a "Third-Party Advertising/Analytics" note — by default
> it's off, so it stays None.

---

## ⚠️ App Review notes (Network Extension / VPN) — read before submitting

Apps using `NEPacketTunnelProvider` get **extra scrutiny**. Put a clear note in
**App Review Information → Notes** explaining the legitimate purpose, e.g.:

```
Rinkler uses a NEPacketTunnelProvider purely as an on-device content filter to
help the user reduce short-video usage (a personal digital-wellbeing tool). It
does NOT route traffic to any remote server, does not act as an anonymizing
VPN, and does not inspect or store the contents of connections — only
destination hostname/SNI and stream size metadata, used locally to interrupt
short-video feeds per the user's own rules. No traffic leaves the device via
the tunnel.
```

Also be ready for these common requirements/risks:
- **Guideline 5.4 (VPN apps):** must use the Network Extension/NEVPNManager APIs
  (Rinkler does) and clearly disclose data collection (this metadata is disclosed
  in the privacy policy). VPN apps generally must be offered by an organization,
  not an individual — **you may need an organization Apple Developer account**,
  not an individual one. Verify this early; it can block submission.
- **Background usage / battery:** be ready to justify the always-on filter.
- **Demo:** provide a working test account in App Review Information so the
  reviewer can sign in (Apple/Google sign-in plus the email path).
- The app must **degrade gracefully** if the user denies the VPN permission.

---

## Pre-submission checklist (Apple side)
- [ ] App icon (1024×1024) + all required sizes
- [ ] Screenshots for required device sizes (6.7" / 6.9" iPhone at minimum)
- [ ] Privacy Policy URL live and reachable
- [ ] App Privacy labels filled to match PRIVACY.md
- [ ] App Review notes (VPN justification above) added
- [ ] Test account credentials provided
- [ ] Export compliance answered (uses standard HTTPS/TLS encryption)
- [ ] Confirm individual vs organization account is acceptable for a VPN-API app
```
