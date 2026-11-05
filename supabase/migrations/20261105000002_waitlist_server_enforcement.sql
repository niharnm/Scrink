-- Enforce the waitlist server-side.
--
-- The lock used to live only in the web login action and auth callback, so the
-- iOS client (or anyone holding the publishable key calling /auth/v1/otp) could
-- create an account directly. A Supabase "Before User Created" auth hook runs
-- inside Auth for every signup path (email OTP, OAuth, API) and can reject it.
--
-- REQUIRED MANUAL STEP: Dashboard > Authentication > Hooks > "Before User
-- Created" > Postgres function > public.hook_before_user_created. Until that is
-- enabled this migration does not block anything.
--
-- The lock is OFF by default so applying this never locks anyone out. Turn it on
-- (in the same moment as ENABLE_WAITLIST_LOCK=true on the web app) with:
--   update public.waitlist_settings set lock_enabled = true;

create table if not exists public.waitlist_settings (
  singleton    boolean primary key default true check (singleton),
  lock_enabled boolean not null default false
);
alter table public.waitlist_settings enable row level security;
revoke all on public.waitlist_settings from anon, authenticated;
insert into public.waitlist_settings (singleton) values (true) on conflict do nothing;

create or replace function public.hook_before_user_created(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  locked boolean;
  user_email text;
begin
  select s.lock_enabled into locked from public.waitlist_settings s where s.singleton;
  if not coalesce(locked, false) then
    return '{}'::jsonb;
  end if;

  user_email := lower(nullif(event->'user'->>'email', ''));
  if user_email is not null and exists (
    select 1 from public.allowed_emails a where a.email = user_email
  ) then
    return '{}'::jsonb;
  end if;

  return jsonb_build_object(
    'error', jsonb_build_object(
      'message', 'You''re on the waitlist. We''ll email you the moment your spot opens.',
      'http_code', 403
    )
  );
end $$;

revoke all on function public.hook_before_user_created(jsonb) from public, anon, authenticated;
grant execute on function public.hook_before_user_created(jsonb) to supabase_auth_admin;

-- Auth reads the allowlist through the definer function above; nothing else
-- needs table access for this role.

-- email_can_sign_in was anon-callable, which made it an allowlist oracle for
-- anyone with the publishable key. Only the web server (service role) needs it.
revoke all on function public.email_can_sign_in(text) from public, anon, authenticated;
grant execute on function public.email_can_sign_in(text) to service_role;
