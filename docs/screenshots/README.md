# App screenshots

Drop PNG/JPG captures here and they render automatically in the root `README.md`
"Screenshots" section. Use these exact filenames so the README links resolve:

| File | Screen |
|------|--------|
| `home.png` | Home — hero focus time, streak, protection card |
| `focus-session.png` | Active focus session / Living Sky |
| `protection.png` | Protection on (VPN connected) |
| `dashboard.png` | Traffic dashboard / insights |
| `settings.png` | Settings — per-app filters |

## How to capture (needs a Mac)

The app and its packet tunnel only build/run from Xcode on macOS; the tunnel
cannot run in the Simulator. To capture:

1. Run the app on a physical iPhone (or the Simulator for non-tunnel screens):
   `cd apps/ios && xcodegen generate && open Rinkler.xcodeproj`
2. Take a screenshot (device: side + volume-up; Simulator: `⌘S`).
3. Export at 1x device resolution, name per the table above, and place the PNGs
   in this folder. Keep them under ~500 KB each (compress with `pngquant`).

> Captured on a Mac because this repo was last worked on from Windows, where the
> iOS toolchain isn't available.
