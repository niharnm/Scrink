-- Friend remote control: an accountability partner sets your limits for a
-- time-boxed window. Owner (on iOS) generates a 6-digit code + a window; friend
-- (on web) redeems the code and toggles the owner's per-feed limits; the owner's
-- device polls and applies them, then restores the owner's own settings when the
-- window ends or is revoked. "Strict Mode, but a friend holds the key."
--
-- Security model:
--  • Owner can CRUD their own pairings; friend can only READ pairings they hold.
--  • Codes are short-lived and redeemed atomically via a SECURITY DEFINER fn
--    (the friend never gets to SELECT pairings by code — no enumeration).
--  • Friend can write limits ONLY while the window is live and not revoked, and
--    only as themselves (set_by = auth.uid()). Owner reads limits for own pairings.

create table if not exists public.friend_pairings (
  id              uuid primary key default gen_random_uuid(),
  owner_user_id   uuid not null references auth.users(id) on delete cascade,
  friend_user_id  uuid references auth.users(id) on delete set null,
  code            text not null,                 -- 6-digit, short-lived
  code_expires_at timestamptz not null,          -- ~15 min to redeem
  window_end      timestamptz not null,          -- control window end
  redeemed_at     timestamptz,
  revoked         boolean not null default false,
  created_at      timestamptz not null default now()
);
create index if not exists friend_pairings_owner  on public.friend_pairings (owner_user_id);
create index if not exists friend_pairings_friend on public.friend_pairings (friend_user_id);
-- one redeemable code at a time per owner
create unique index if not exists friend_pairings_live_code
  on public.friend_pairings (code) where (redeemed_at is null and revoked = false);

create table if not exists public.friend_set_limits (
  id            uuid primary key default gen_random_uuid(),
  pairing_id    uuid not null references public.friend_pairings(id) on delete cascade,
  owner_user_id uuid not null,                   -- denormalized for owner reads
  app_id        text not null,
  feature_id    text not null,
  enabled       boolean not null default true,
  set_by        uuid not null,
  updated_at    timestamptz not null default now(),
  unique (pairing_id, app_id, feature_id)
);
create index if not exists friend_set_limits_owner on public.friend_set_limits (owner_user_id);

alter table public.friend_pairings  enable row level security;
alter table public.friend_set_limits enable row level security;

-- friend_pairings: owner full control of own rows; friend may read theirs.
drop policy if exists fp_owner_all on public.friend_pairings;
create policy fp_owner_all on public.friend_pairings
  for all to authenticated
  using (owner_user_id = (select auth.uid()))
  with check (owner_user_id = (select auth.uid()));

drop policy if exists fp_friend_read on public.friend_pairings;
create policy fp_friend_read on public.friend_pairings
  for select to authenticated
  using (friend_user_id = (select auth.uid()));

-- friend_set_limits: owner reads own; friend reads+writes during a live window.
drop policy if exists fsl_owner_read on public.friend_set_limits;
create policy fsl_owner_read on public.friend_set_limits
  for select to authenticated
  using (owner_user_id = (select auth.uid()));

drop policy if exists fsl_friend_write on public.friend_set_limits;
create policy fsl_friend_write on public.friend_set_limits
  for all to authenticated
  using (
    set_by = (select auth.uid())
    and exists (
      select 1 from public.friend_pairings p
      where p.id = pairing_id
        and p.friend_user_id = (select auth.uid())
        and p.revoked = false
        and p.window_end > now()
    )
  )
  with check (
    set_by = (select auth.uid())
    and exists (
      select 1 from public.friend_pairings p
      where p.id = pairing_id
        and p.friend_user_id = (select auth.uid())
        and p.revoked = false
        and p.window_end > now()
    )
  );

-- Atomic, enumeration-safe redeem: claim a live code as the caller.
create or replace function public.redeem_pairing(p_code text)
returns table (pairing_id uuid, owner_user_id uuid, window_end timestamptz)
language plpgsql security definer set search_path = '' as $$
begin
  return query
  update public.friend_pairings
     set friend_user_id = auth.uid(), redeemed_at = now()
   where code = p_code
     and redeemed_at is null
     and revoked = false
     and code_expires_at > now()
     and owner_user_id <> auth.uid()
  returning id, friend_pairings.owner_user_id, friend_pairings.window_end;
end $$;

revoke all on function public.redeem_pairing(text) from public;
grant execute on function public.redeem_pairing(text) to authenticated;

comment on table public.friend_pairings is 'Time-boxed friend remote-control sessions.';
comment on table public.friend_set_limits is 'Per-feed limits a friend sets during a live pairing window.';
