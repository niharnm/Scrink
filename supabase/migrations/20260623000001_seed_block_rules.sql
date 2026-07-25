-- Seed the active block-rules pack.
--
-- The web Friend Control page builds its entire toggle list from the ACTIVE
-- block_rules pack; with no seeded row the friend sees an empty list and can't
-- set any limits, so the whole friend flow is dead on the web side. (iOS silently
-- falls back to its bundled BlockCatalog, which masked this.)
--
-- This pack MIRRORS apps/ios/Rinkler/Models/BlockCatalog.swift `bundled` exactly
-- (same app/feature ids, hosts, urlPatterns) so the two surfaces agree and
-- RuleRegistry.sync() on iOS decodes it cleanly into RulePack. This is the single
-- source of truth: update this pack (bump `version`, flip is_active) to ship rule
-- changes without an App Store release. KEEP IN SYNC WITH BlockCatalog.bundled.

insert into public.block_rules (version, pack, is_active, notes)
values (
  '2026.06.22',
  '{
    "version": "2026.06.22",
    "apps": [
      {
        "id": "instagram", "name": "Instagram", "symbol": "camera.fill", "mostlyFeed": false,
        "features": [
          {"id": "reels", "name": "Reels", "blurb": "The short-video slot machine",
           "hosts": ["cdninstagram.com", "fbcdn.net", "fbvideo.net", "instagram.fbcdn.net"],
           "urlPatterns": ["instagram.com/reels/*", "i.instagram.com/api/*reels*", "i.instagram.com/api/*clips*"],
           "sharedHosts": true},
          {"id": "explore", "name": "Explore", "blurb": "The discover grid",
           "hosts": [],
           "urlPatterns": ["instagram.com/explore/*", "i.instagram.com/api/*explore*", "i.instagram.com/api/*discover*"],
           "sharedHosts": true},
          {"id": "feed", "name": "Home feed", "blurb": "The endless scroll",
           "hosts": [],
           "urlPatterns": ["i.instagram.com/api/*feed/timeline*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "tiktok", "name": "TikTok", "symbol": "music.note", "mostlyFeed": true,
        "features": [
          {"id": "fyp", "name": "For You feed", "blurb": "Nearly the whole app is the feed",
           "hosts": ["tiktokv.com", "tiktokcdn.com", "tiktokcdn-us.com", "byteoversea.com", "muscdn.com", "ibytedtos.com", "byteimg.com"],
           "urlPatterns": ["*/api/recommend/item_list*", "*/aweme/v1/feed*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "youtube", "name": "YouTube", "symbol": "play.rectangle.fill", "mostlyFeed": false,
        "features": [
          {"id": "shorts", "name": "Shorts", "blurb": "Vertical short video",
           "hosts": [],
           "urlPatterns": ["youtube.com/shorts/*", "youtubei.googleapis.com/*/reel/*", "youtubei.googleapis.com/*/shorts*"],
           "sharedHosts": true},
          {"id": "home", "name": "Home recommendations", "blurb": "The recommended grid",
           "hosts": [],
           "urlPatterns": ["youtubei.googleapis.com/*/browse*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "snapchat", "name": "Snapchat", "symbol": "bolt.fill", "mostlyFeed": false,
        "features": [
          {"id": "spotlight", "name": "Spotlight", "blurb": "Snap's short-video feed",
           "hosts": [],
           "urlPatterns": ["*/spotlight*", "*/discover/*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "reddit", "name": "Reddit", "symbol": "bubble.left.and.bubble.right.fill", "mostlyFeed": false,
        "features": [
          {"id": "home", "name": "Home / Popular feed", "blurb": "The endless front page",
           "hosts": [],
           "urlPatterns": ["*/svc/shreddit/feeds/*", "oauth.reddit.com/*best*", "oauth.reddit.com/*popular*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "x", "name": "X / Twitter", "symbol": "bird.fill", "mostlyFeed": false,
        "features": [
          {"id": "foryou", "name": "For You timeline", "blurb": "The algorithmic feed",
           "hosts": [],
           "urlPatterns": ["*/HomeTimeline*", "*/HomeLatestTimeline*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "facebook", "name": "Facebook", "symbol": "person.2.fill", "mostlyFeed": false,
        "features": [
          {"id": "reels", "name": "Reels & Watch", "blurb": "Facebook's video feeds",
           "hosts": [],
           "urlPatterns": ["*/reels*", "*/watch*", "*/video/feed*"],
           "sharedHosts": true},
          {"id": "feed", "name": "News feed", "blurb": "The home scroll",
           "hosts": [],
           "urlPatterns": ["*/feed*", "*/newsfeed*"],
           "sharedHosts": true}
        ]
      },
      {
        "id": "pinterest", "name": "Pinterest", "symbol": "pin.fill", "mostlyFeed": true,
        "features": [
          {"id": "home", "name": "Home feed", "blurb": "The pin discovery feed",
           "hosts": ["pinimg.com"],
           "urlPatterns": ["*/v3/users/*/feed*", "*/v3/pidgets/*"],
           "sharedHosts": true}
        ]
      }
    ]
  }'::jsonb,
  true,
  'Initial pack, mirrors BlockCatalog.bundled (2026.06.22).'
)
on conflict (version) do update
  set pack = excluded.pack,
      is_active = excluded.is_active,
      notes = excluded.notes;
