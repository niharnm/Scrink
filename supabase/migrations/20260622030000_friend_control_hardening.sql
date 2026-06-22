-- Friend control hardening (from adversarial review):
--  1. fsl_friend_write trusted a client-supplied owner_user_id. Correlate it to
--     the pairing's REAL owner so a friend can't stamp an arbitrary user id.
--  2. redeem_pairing had no brute-force throttle (6-digit codes). Add a per-user
--     rolling attempt limit.

-- 1) Lock owner_user_id to the pairing's real owner in both USING and WITH CHECK.
drop policy if exists fsl_friend_write on public.friend_set_limits;
create policy fsl_friend_write on public.friend_set_limits
  for all to authenticated
  using (
    set_by = (select auth.uid())
    and exists (
      select 1 from public.friend_pairings p
      where p.id = pairing_id
        and p.friend_user_id = (select auth.uid())
        and p.owner_user_id = friend_set_limits.owner_user_id
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
        and p.owner_user_id = friend_set_limits.owner_user_id
        and p.revoked = false
        and p.window_end > now()
    )
  );

-- 2) Redeem throttle: record attempts, cap them per rolling window.
create table if not exists public.friend_redeem_attempts (
  id           bigserial primary key,
  user_id      uuid not null,
  attempted_at timestamptz not null default now()
);
create index if not exists friend_redeem_attempts_user_time
  on public.friend_redeem_attempts (user_id, attempted_at desc);
alter table public.friend_redeem_attempts enable row level security;
-- No policies → only the SECURITY DEFINER function (which bypasses RLS) touches it.

create or replace function public.redeem_pairing(p_code text)
returns table (pairing_id uuid, owner_user_id uuid, window_end timestamptz)
language plpgsql security definer set search_path = '' as $$
declare recent int;
begin
  -- Throttle: at most 8 redeem attempts per user per 5 minutes.
  select count(*) into recent
    from public.friend_redeem_attempts
    where user_id = auth.uid() and attempted_at > now() - interval '5 minutes';
  if recent >= 8 then
    raise exception 'Too many attempts. Wait a few minutes and try again.';
  end if;
  insert into public.friend_redeem_attempts (user_id) values (auth.uid());

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
