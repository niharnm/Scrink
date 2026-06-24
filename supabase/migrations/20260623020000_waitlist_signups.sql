-- Waitlist gate: an explicit allowlist of emails permitted to sign in/up.
--
-- The app enforces this only when ENABLE_WAITLIST_LOCK=true (see the web login
-- action + auth callback); the table + function ship inert until then. Approving
-- someone is a one-liner:  insert into public.allowed_emails(email) values ('x@y.com');

create table if not exists public.allowed_emails (
  email      text primary key,         -- stored lowercased
  note       text,
  added_at   timestamptz not null default now()
);

alter table public.allowed_emails enable row level security;
-- No policies: anon/authenticated cannot read or write the list (no enumeration).
-- Reads happen only through the security-definer function below; writes are
-- service-role (dashboard / admin) only.

-- Grandfather everyone who already has an account so enabling the lock can never
-- shut out an existing user (the owner included). Gate on this list ONLY — not on
-- "exists in auth.users" — because an OAuth attempt creates a user row before we
-- can check it; keying off the list keeps unapproved OAuth sign-ins blocked.
insert into public.allowed_emails (email, note)
  select distinct lower(email), 'grandfathered'
    from auth.users
   where email is not null
on conflict (email) do nothing;

-- Belt-and-suspenders: always allow the owner.
insert into public.allowed_emails (email, note)
  values ('nihar.manchikalapudi@gmail.com', 'owner')
on conflict (email) do nothing;

-- Returns true if this email may sign in. Security-definer so callers never read
-- the list directly; returns only a boolean (no enumeration). Case-insensitive.
create or replace function public.email_can_sign_in(p_email text)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.allowed_emails where email = lower(p_email)
  )
$$;

revoke all on function public.email_can_sign_in(text) from public;
grant execute on function public.email_can_sign_in(text) to anon, authenticated;
