-- Plain-SQL regression checks for 20261105000001/2 (the repo has no pgTAP
-- harness). Run against a DISPOSABLE database with all migrations applied:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f supabase/tests/security_hardening.sql
-- Everything runs in one transaction and is rolled back.
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'owner@example.com'),
  ('00000000-0000-0000-0000-0000000000b2', 'friend@example.com'),
  ('00000000-0000-0000-0000-0000000000c3', 'rando@example.com');

create temp table t_ctx (code text, pid uuid);
grant all on t_ctx to authenticated;

-- 1) create_pairing issues a 10-char code server-side.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a1', true);
insert into t_ctx select code, id from public.create_pairing(4);
do $$ begin
  assert (select code ~ '^[2-9A-HJ-NP-Z]{10}$' from t_ctx), 'code format';
end $$;

-- Window bounds are enforced.
do $$ begin
  begin perform public.create_pairing(0); raise exception 'expected failure';
  exception when sqlstate '22023' then null; end;
  begin perform public.create_pairing(25); raise exception 'expected failure';
  exception when sqlstate '22023' then null; end;
end $$;
reset role;
-- (the two failed calls above ran after the first, but raised before changing state)

-- 2) Owner cannot write or delete pairings directly.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a1', true);
do $$ begin
  begin update public.friend_pairings set revoked = true; raise exception 'expected failure';
  exception when insufficient_privilege then null; end;
  begin delete from public.friend_pairings; raise exception 'expected failure';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.friend_pairings (owner_user_id, code, code_expires_at, window_end)
    values ('00000000-0000-0000-0000-0000000000a1', '123456', now(), now());
    raise exception 'expected failure';
  exception when insufficient_privilege then null; end;
  assert (select count(*) from public.friend_pairings) = 1, 'owner can select own pairing';
end $$;

-- 3) A different user cannot revoke it; the owner can, and revoked_at is server-set.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c3', true);
do $$ begin
  assert not public.revoke_pairing((select pid from t_ctx)), 'stranger cannot revoke';
end $$;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a1', true);
do $$ begin
  assert public.revoke_pairing((select pid from t_ctx)), 'owner revokes';
  assert (select revoked and revoked_at is not null from public.friend_pairings), 'audit fields set';
end $$;

-- 4) Redeem: legacy/short/garbage input never matches; a valid code works once.
insert into t_ctx select code, id from public.create_pairing(1);
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000b2', true);
do $$
declare c text := (select code from t_ctx order by pid limit 1 offset 1); n int;
begin
  select count(*) into n from public.redeem_pairing('123456'); assert n = 0, 'legacy code';
  select count(*) into n from public.redeem_pairing(null); assert n = 0, 'null code';
  select count(*) into n from public.redeem_pairing(lower(substr(c,1,5) || '-' || substr(c,6))); assert n = 1, 'normalized redeem';
  select count(*) into n from public.redeem_pairing(c); assert n = 0, 'single use';
end $$;

-- 5) Per-user ceiling: 8 attempts per 5 minutes (4 already used above).
do $$ begin
  perform public.redeem_pairing('AAAAAAAAAA');
  perform public.redeem_pairing('AAAAAAAAAA');
  perform public.redeem_pairing('AAAAAAAAAA');
  perform public.redeem_pairing('AAAAAAAAAA');
  begin perform public.redeem_pairing('AAAAAAAAAA'); raise exception 'expected throttle';
  exception when raise_exception then
    assert sqlerrm like 'Too many attempts%', 'per-user throttle: ' || sqlerrm;
  end;
end $$;

-- 6) Global ceiling: spread attempts across many users.
reset role;
insert into public.friend_redeem_attempts (user_id)
  select gen_random_uuid() from generate_series(1, 300);
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c3', true);
do $$ begin
  begin perform public.redeem_pairing('AAAAAAAAAA'); raise exception 'expected global throttle';
  exception when raise_exception then
    assert sqlerrm like 'Too many attempts%', 'global throttle: ' || sqlerrm;
  end;
end $$;
reset role;

-- 7) Waitlist: anon cannot call the oracle; hook is inert until locked, then enforces.
set local role anon;
do $$ begin
  begin perform public.email_can_sign_in('owner@example.com'); raise exception 'expected failure';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

insert into public.allowed_emails (email) values ('ok@example.com') on conflict do nothing;
do $$ begin
  assert public.hook_before_user_created('{"user":{"email":"new@example.com"}}') = '{}'::jsonb, 'hook inert when unlocked';
end $$;
update public.waitlist_settings set lock_enabled = true;
do $$ begin
  assert public.hook_before_user_created('{"user":{"email":"OK@example.com"}}') = '{}'::jsonb, 'allowlisted passes';
  assert public.hook_before_user_created('{"user":{"email":"new@example.com"}}') ? 'error', 'unlisted rejected';
  assert public.hook_before_user_created('{"user":{}}') ? 'error', 'no email rejected';
end $$;
set local role supabase_auth_admin;
do $$ begin
  perform public.hook_before_user_created('{"user":{"email":"ok@example.com"}}');
end $$;
reset role;

rollback;
\echo security_hardening: all assertions passed
