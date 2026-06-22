-- Remote rule registry: versioned "rule packs" describing each app's addictive
-- surfaces (Reels / Shorts / For You / Spotlight / Home feed) and the hosts +
-- URL patterns Rinkler uses to block them. The iOS app ships a bundled default
-- (BlockCatalog.swift) and fetches the active pack here so endpoints can be
-- updated without an App Store release (Meta/Google/etc. move hosts constantly).
--
-- Only one pack is active at a time. The app reads it with the public anon key
-- (read-only, RLS below); writes are service-role only (Management API / dashboard).

create table if not exists public.block_rules (
  id          uuid primary key default gen_random_uuid(),
  version     text not null unique,          -- e.g. "2026.06.22"
  pack        jsonb not null,                -- { "version": "...", "apps": [ BlockApp... ] }
  is_active   boolean not null default false,
  notes       text,
  created_at  timestamptz not null default now()
);

-- At most one active pack.
create unique index if not exists block_rules_single_active
  on public.block_rules (is_active) where is_active;

alter table public.block_rules enable row level security;

-- Anyone signed in (or anon) may read the ACTIVE pack only. No write policy →
-- inserts/updates are denied for anon/authenticated; service_role bypasses RLS.
drop policy if exists block_rules_read_active on public.block_rules;
create policy block_rules_read_active
  on public.block_rules
  for select
  to anon, authenticated
  using (is_active);

comment on table public.block_rules is
  'Versioned addictive-feed rule packs fetched by the Rinkler app; one row active at a time.';
