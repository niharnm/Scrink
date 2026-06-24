-- Defense in depth for the two "no-policy lockdown" tables.
--
-- allowed_emails and friend_redeem_attempts have RLS enabled with zero policies,
-- so anon/authenticated already can't read or write them, and they're only
-- touched through SECURITY DEFINER functions (email_can_sign_in, redeem_pairing)
-- which don't rely on caller grants. Explicitly revoke the implicit Supabase
-- default-privilege grants so their protection doesn't depend solely on RLS
-- being left enabled (e.g. if RLS is ever disabled for debugging).

revoke all on public.allowed_emails from anon, authenticated;
revoke all on public.friend_redeem_attempts from anon, authenticated;
