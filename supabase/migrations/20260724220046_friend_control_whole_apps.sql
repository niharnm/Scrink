-- Let a friend control a privacy-preserving, owner-approved Screen Time
-- selection. The opaque Family Controls tokens never leave the owner's iPhone;
-- the pairing only exposes whether whole-app control is allowed and how many
-- app/category selections were approved.

alter table public.friend_pairings
  add column if not exists whole_app_control_enabled boolean not null default false,
  add column if not exists whole_app_selection_count integer not null default 0;

alter table public.friend_pairings
  drop constraint if exists friend_pairings_whole_app_selection_count_check;

alter table public.friend_pairings
  add constraint friend_pairings_whole_app_selection_count_check
  check (
    whole_app_selection_count >= 0
    and (
      whole_app_control_enabled
      or whole_app_selection_count = 0
    )
  );

-- PostgreSQL cannot change a function's table return shape with CREATE OR
-- REPLACE, so replace the RPC while preserving the existing throttle and
-- enumeration-safe atomic update.
drop function if exists public.redeem_pairing(text);

create function public.redeem_pairing(p_code text)
returns table (
  pairing_id uuid,
  owner_user_id uuid,
  window_end timestamptz,
  whole_app_control_enabled boolean,
  whole_app_selection_count integer
)
language plpgsql security definer set search_path = '' as $$
declare recent int;
begin
  if auth.uid() is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  select count(*) into recent
    from public.friend_redeem_attempts
    where user_id = auth.uid()
      and attempted_at > now() - interval '5 minutes';
  if recent >= 8 then
    raise exception 'Too many attempts. Wait a few minutes and try again.';
  end if;

  insert into public.friend_redeem_attempts (user_id) values (auth.uid());

  return query
  update public.friend_pairings
     set friend_user_id = auth.uid(),
         redeemed_at = now()
   where code = p_code
     and redeemed_at is null
     and revoked = false
     and code_expires_at > now()
     and owner_user_id <> auth.uid()
  returning
    id,
    friend_pairings.owner_user_id,
    friend_pairings.window_end,
    friend_pairings.whole_app_control_enabled,
    friend_pairings.whole_app_selection_count;
end $$;

revoke all on function public.redeem_pairing(text) from public, anon;
grant execute on function public.redeem_pairing(text) to authenticated;

comment on column public.friend_pairings.whole_app_control_enabled is
  'Whether the owner granted control of an opaque, locally stored Screen Time selection.';
comment on column public.friend_pairings.whole_app_selection_count is
  'Privacy-safe count of owner-approved app/category tokens; token identities never leave the device.';
