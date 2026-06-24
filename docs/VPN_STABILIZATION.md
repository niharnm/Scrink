# VPN tunnel stabilization — crash root-cause + honest scope

This documents the June 2026 stabilization pass on the packet-tunnel blocker.
Two things were decided up front and are reflected here:

1. **The network-tier blocker is, and will remain, best-effort.** It cannot
   precisely separate Reels/FYP from the rest of an app — that is a platform
   limit, not a bug (see "Why precise per-feed blocking can't ship" below). The
   product copy should say "best effort," not promise surgical blocking.
2. **The decision was to keep this tier and stabilize it**, not re-architect to
   Screen Time shields. So this pass fixes the crash and documents the limits;
   it intentionally does **not** change the block heuristic in ways that can't be
   verified on-device (an untested filter change can silently break browsing).

## The crash (RinklerTunnel-*.ips)

All three captured reports are the **same** crash:

```
EXC_BAD_ACCESS (SIGKILL) / KERN_PROTECTION_FAILURE at 0x0  ("Invalid Page")
  hev_socks5_session_udp_fwd_b      <- UDP forward (appears recursively)
  hev_socks5_session_udp_fwd_b
  hev_socks5_session_udp_splice
  hev_socks5_session_task_entry
  hev_task_executer
```

This is a **coroutine stack overflow** on HevSocks5Tunnel's UDP forwarding path:
the task ran past its fixed stack's guard page and the return address landed on
a non-executable page, so the kernel killed it.

### Root cause: it's a Debug-build artifact

The decisive detail: every crash image is **`RinklerTunnel.debug.dylib`** — a
**Debug** build. `hev_socks5_session_udp_fwd_b` is a *tail-recursive* splice
loop. With optimizations **off** (Debug, `-Onone`) the compiler does **not**
eliminate the tail call, so every forwarded datagram pushes a new frame and the
stack grows without bound under sustained QUIC/UDP load → overflow. With
optimizations **on** (Release, `-O`) the tail call **is** eliminated, the loop
runs in constant stack, and it does not overflow.

That is why bumping the stack 24 K → 86 K (commit `b6aef5a`) reduced but didn't
fully end the Debug crashes: no fixed stack size "fixes" unbounded recursion.

### What changed in this pass

- `tun2socksTaskStackSize` 86016 → **131072** (`RinklerConstants.swift`).
  Defense-in-depth: more headroom for Debug on-device testing, negligible memory
  cost because hev stacks are allocated **per active flow** (freed on completion),
  not pre-allocated `maxConnections` times — steady state is a few MB.

### The actual fix (must be verified on a Release build)

The Network Extension **cannot run in the Simulator** — it needs a signed build
on a physical device. Verify the crash is gone like this:

1. Build/run the **RinklerTunnel** extension in a **Release / optimized**
   configuration (not Debug). In Xcode: Edit Scheme → Run → Build Configuration =
   Release, or test a TestFlight build.
2. Start Protection, open Instagram/TikTok, and **scroll Reels/FYP hard** for a
   few minutes to drive sustained QUIC/UDP through `udp_fwd`.
3. With the Mac connected, Console.app → device → filter `com.rinkler.app.tunnel`.
   Confirm: no `EXC_BAD_ACCESS` in `hev_socks5_session_udp_fwd_b`, and the tunnel
   stays Connected.
4. If a Release build still overflows, the next step is bounding hev's UDP
   recursion in the vendored library (or pinning a newer HevSocks5Tunnel), not
   growing the stack further.

## Why precise per-feed blocking can't ship (the honest limit)

Verified against the installed **iOS 26.5 SDK** and corroborated by research:

- This tier is a packet tunnel → local SOCKS proxy with **no TLS interception**,
  so every decision is made on **SNI domain** or **destination IP**. It never
  sees the URL path.
- Reels, posts, stories, and DM media share the same domains
  (`instagram.com`, `*.cdninstagram.com`, `*.fbcdn.net`) and CDN IPs, so the only
  available signal is a **per-connection byte threshold** (`streamBlockThreshold`,
  default 0.5 MB): "a large download on a tracked CDN is probably feed video."
  This both over-blocks (a big story/DM video) and leaks (the first ~0.5 MB of
  each new connection plays). That is inherent, not fixable here.
- The system-wide `NEFilterDataProvider` / `NEDNSProxyProvider` content filters
  require **supervised/MDM** devices — not shippable to consumers.
- iOS 26's public `NEURLFilter` API is a **voluntary self-check** an app runs on
  *its own* URLs (`+verdictForURL:completionHandler:`); it cannot inspect another
  app's traffic. The system-wide `NEURLFilterControlProvider` / `NEURLFilterManager`
  classes exist only as **private SPI** (no public header in 26.5) → App Store
  rejection. So there is **no** consumer-shippable iOS API that blocks Reels/FYP
  inside the native app. Every competitor (Opal, one sec, Freedom) uses whole-app
  Screen Time shields instead; ScrollGuard only filters its own wrapped web views.

Keep the UI honest about this: "best-effort feed blocking," with the whole-app
Screen Time **Shield** offered as the reliable fallback when a user wants a hard
block.
