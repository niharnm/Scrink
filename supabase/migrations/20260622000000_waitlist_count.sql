-- Public waitlist count: exposes only the total number of signed-up users
-- (no rows, no PII) so the landing/login can show "N people waiting".
create or replace function public.waitlist_count()
returns integer
language sql
security definer
set search_path = ''
as $$ select count(*)::int from auth.users $$;

revoke all on function public.waitlist_count() from public;
grant execute on function public.waitlist_count() to anon, authenticated;
