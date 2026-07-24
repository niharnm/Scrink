-- Waitlist gate: an explicit allowlist of emails permitted to sign in/up.
--
-- The app enforces this only when ENABLE_WAITLIST_LOCK=true (see the web login
-- action + auth callback); the table + function ship inert until then. Approving
-- someone is a one-liner:  insert into public.allowed_emails(email) values ('x@y.com');

create table if not exists public.allowed_emails (
  email      text primary key,
  note       text,
  added_at   timestamptz not null default now()
);

alter table public.allowed_emails enable row level security;

insert into public.allowed_emails (email, note)
  select distinct lower(email), 'grandfathered'
    from auth.users
   where email is not null
on conflict (email) do nothing;

insert into public.allowed_emails (email, note)
  values ('nihar.manchikalapudi@gmail.com', 'owner')
on conflict (email) do nothing;

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

revoke all on public.allowed_emails from anon, authenticated;
