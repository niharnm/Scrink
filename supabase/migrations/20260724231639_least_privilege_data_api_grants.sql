-- Older Supabase projects grant broad Data API privileges by default. RLS is
-- still the row boundary, but explicit object grants provide a second boundary
-- and prevent accidental exposure if a policy or RLS setting later changes.

revoke all on all tables in schema public from public, anon, authenticated;
revoke all on all sequences in schema public from public, anon, authenticated;
revoke execute on all functions in schema public from public, anon, authenticated;

grant usage on schema public to anon, authenticated, service_role;

-- Public app configuration: callers may only read the active row allowed by RLS.
grant select on public.block_rules to anon, authenticated;

-- Signed-in application access. RLS further restricts every row to the caller.
grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.blocker_state to authenticated;
grant select on public.active_blocker_state to authenticated;
grant select, insert on public.traffic_events to authenticated;
grant select on public.traffic_summaries to authenticated;
grant select on public.llm_insights to authenticated;
grant select, insert, update, delete on public.friend_pairings to authenticated;
grant select, insert, update, delete on public.friend_set_limits to authenticated;
grant usage, select on sequence public.traffic_events_id_seq to authenticated;

-- These SECURITY DEFINER RPCs validate auth.uid() internally and intentionally
-- expose only caller-scoped operations.
grant execute on function public.delete_current_user() to authenticated;
grant execute on function public.redeem_pairing(text) to authenticated;

-- The waitlist migration may not yet exist in an older linked environment.
do $$
begin
  if to_regprocedure('public.email_can_sign_in(text)') is not null then
    grant execute on function public.email_can_sign_in(text) to anon, authenticated;
  end if;
end
$$;

-- New objects are private until a migration explicitly opts them into the Data
-- API. Revoke PUBLIC function execution as PostgreSQL grants it by default.
alter default privileges for role postgres in schema public
  revoke all on tables from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke all on sequences from public, anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;
