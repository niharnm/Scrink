-- Friend control security hardening.
--
--  1. Pairing codes were 6 digits in one global space, throttled per user only,
--     with a non-atomic count-then-insert. Codes are now generated server-side
--     (10 chars from a 32-symbol alphabet, 50 bits), redeem attempts are
--     serialized per user and capped globally as well.
--  2. fp_owner_all (FOR ALL) let the owner delete or rewrite their own pairing,
--     including the revoked/revoked_at audit fields. The owner can now only
--     SELECT; creating and revoking go through SECURITY DEFINER functions that
--     set the audit fields server-side.

-- Legacy 6-digit codes can no longer be redeemed. Retire any still-pending ones.
update public.friend_pairings
   set revoked = true,
       revoked_at = coalesce(revoked_at, now())
 where redeemed_at is null
   and revoked = false;

-- New rows must use the new code format (NOT VALID: historical rows are kept).
alter table public.friend_pairings
  drop constraint if exists friend_pairings_code_format;
alter table public.friend_pairings
  add constraint friend_pairings_code_format
  check (code ~ '^[2-9A-HJ-NP-Z]{10}$') not valid;

-- Global attempt ceiling needs a time-only index; also lets us prune cheaply.
create index if not exists friend_redeem_attempts_time
  on public.friend_redeem_attempts (attempted_at desc);

-- ---------------------------------------------------------------------------
-- Owner access: read-only through the Data API.
-- ---------------------------------------------------------------------------
drop policy if exists fp_owner_all on public.friend_pairings;
drop policy if exists fp_owner_select on public.friend_pairings;
create policy fp_owner_select on public.friend_pairings
  for select to authenticated
  using (owner_user_id = (select auth.uid()));

revoke insert, update, delete on public.friend_pairings from anon, authenticated;
grant select on public.friend_pairings to authenticated;

-- ---------------------------------------------------------------------------
-- create_pairing: server-side code generation.
-- ---------------------------------------------------------------------------
create or replace function public.generate_pairing_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ'; -- 32 symbols, no I/O/0/1
  bytes bytea := uuid_send(gen_random_uuid());                  -- CSPRNG bytes
  result text := '';
  i int;
begin
  for i in 0..9 loop
    -- 256 % 32 = 0, so masking to 5 bits is unbiased.
    result := result || substr(alphabet, (get_byte(bytes, i) & 31) + 1, 1);
  end loop;
  return result;
end $$;

revoke all on function public.generate_pairing_code() from public, anon, authenticated;

create or replace function public.create_pairing(p_window_hours integer)
returns table (
  id uuid,
  code text,
  window_end timestamptz,
  friend_user_id uuid,
  redeemed_at timestamptz,
  revoked boolean
)
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  new_code text;
  attempts int := 0;
begin
  if uid is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;
  if p_window_hours is null or p_window_hours < 1 or p_window_hours > 24 then
    raise exception 'Window must be between 1 and 24 hours.' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('friend_create:' || uid::text, 0));

  -- Retire any pending code so we keep one live code per owner.
  update public.friend_pairings p
     set revoked = true,
         revoked_at = coalesce(p.revoked_at, now())
   where p.owner_user_id = uid
     and p.redeemed_at is null
     and p.revoked = false;

  loop
    new_code := public.generate_pairing_code();
    begin
      return query
      insert into public.friend_pairings as fp
        (owner_user_id, code, code_expires_at, window_end)
      values
        (uid, new_code, now() + interval '15 minutes',
         now() + make_interval(hours => p_window_hours))
      returning fp.id, fp.code, fp.window_end, fp.friend_user_id, fp.redeemed_at, fp.revoked;
      return;
    exception when unique_violation then
      attempts := attempts + 1;
      if attempts >= 5 then
        raise exception 'Could not allocate a code. Try again.';
      end if;
    end;
  end loop;
end $$;

revoke all on function public.create_pairing(integer) from public, anon;
grant execute on function public.create_pairing(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- revoke_pairing: owner ends a pairing; audit fields are set server-side.
-- ---------------------------------------------------------------------------
create or replace function public.revoke_pairing(p_pairing_id uuid)
returns boolean
language plpgsql security definer set search_path = '' as $$
declare
  n int;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  update public.friend_pairings p
     set revoked = true,
         revoked_at = now()
   where p.id = p_pairing_id
     and p.owner_user_id = auth.uid()
     and p.revoked = false;
  get diagnostics n = row_count;
  return n > 0;
end $$;

revoke all on function public.revoke_pairing(uuid) from public, anon;
grant execute on function public.revoke_pairing(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- redeem_pairing: normalize input, serialize per user, per-user + global caps.
-- ---------------------------------------------------------------------------
create or replace function public.redeem_pairing(p_code text)
returns table (
  pairing_id uuid,
  owner_user_id uuid,
  window_end timestamptz,
  whole_app_control_enabled boolean,
  whole_app_selection_count integer
)
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  recent_user int;
  recent_global int;
  norm text;
begin
  if uid is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  -- Serialize this user's attempts so parallel calls can't all pass the count.
  perform pg_advisory_xact_lock(hashtextextended('friend_redeem:' || uid::text, 0));
  -- Then the global ceiling (fixed lock order: user, then global).
  perform pg_advisory_xact_lock(hashtextextended('friend_redeem:global', 0));

  select count(*) into recent_user
    from public.friend_redeem_attempts a
    where a.user_id = uid
      and a.attempted_at > now() - interval '5 minutes';
  if recent_user >= 8 then
    raise exception 'Too many attempts. Wait a few minutes and try again.';
  end if;

  select count(*) into recent_global
    from public.friend_redeem_attempts a
    where a.attempted_at > now() - interval '5 minutes';
  if recent_global >= 300 then
    raise exception 'Too many attempts. Wait a few minutes and try again.';
  end if;

  insert into public.friend_redeem_attempts (user_id) values (uid);
  delete from public.friend_redeem_attempts a
    where a.attempted_at < now() - interval '1 day';

  norm := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  if norm !~ '^[2-9A-HJ-NP-Z]{10}$' then
    return;
  end if;

  return query
  update public.friend_pairings fp
     set friend_user_id = uid,
         redeemed_at = now()
   where fp.code = norm
     and fp.redeemed_at is null
     and fp.revoked = false
     and fp.code_expires_at > now()
     and fp.owner_user_id <> uid
  returning
    fp.id,
    fp.owner_user_id,
    fp.window_end,
    fp.whole_app_control_enabled,
    fp.whole_app_selection_count;
end $$;

revoke all on function public.redeem_pairing(text) from public, anon;
grant execute on function public.redeem_pairing(text) to authenticated;
