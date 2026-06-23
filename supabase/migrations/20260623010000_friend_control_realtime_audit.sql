-- Friend Control: revoke accountability, one-live-code-per-owner, and realtime.

-- 1) Revoke accountability. Record WHEN a window was ended early so "you can pull
--    the plug, but it logs" is backed by a real timestamp the friend can see,
--    not just a boolean flip.
alter table public.friend_pairings
  add column if not exists revoked_at timestamptz;

-- 2) One live (pending, unredeemed) code per owner. The original unique index was
--    on (code) only, so an owner could leave several pending codes outstanding and
--    the app could only surface the newest — orphaning the rest. First retire any
--    existing duplicate pending codes (keep the newest per owner), then enforce it.
update public.friend_pairings p
   set revoked = true,
       revoked_at = coalesce(revoked_at, now())
 where redeemed_at is null
   and revoked = false
   and exists (
     select 1 from public.friend_pairings q
      where q.owner_user_id = p.owner_user_id
        and q.redeemed_at is null
        and q.revoked = false
        and q.created_at > p.created_at
   );

create unique index if not exists friend_pairings_one_live_per_owner
  on public.friend_pairings (owner_user_id)
  where (redeemed_at is null and revoked = false);

-- 3) Realtime. Let clients subscribe to limit changes and revokes instead of
--    polling. RLS still applies to realtime, so a subscriber only receives rows
--    they're already allowed to read. Guarded so re-running is a no-op.
do $$
begin
  begin
    alter publication supabase_realtime add table public.friend_set_limits;
  exception when duplicate_object then null;
  end;
  begin
    alter publication supabase_realtime add table public.friend_pairings;
  exception when duplicate_object then null;
  end;
end $$;
