-- Drop the unused waitlist_count() function.
--
-- It was SECURITY DEFINER and granted EXECUTE to anon, returning
-- `select count(*)::int from auth.users` — so any unauthenticated caller could
-- poll the exact total signup count. We deliberately never display a waitlist
-- count anywhere in the product, so this function is dead code and a needless
-- information leak. Remove it entirely (this also revokes the anon grant).
drop function if exists public.waitlist_count();
