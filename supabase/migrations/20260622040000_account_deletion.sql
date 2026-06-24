-- Self-service account deletion.
--
-- The iOS app confirms it's really the owner by re-verifying a one-time code
-- emailed to the user (reusing Supabase's existing OTP email pipeline), then
-- calls this RPC to permanently delete their own account. Deleting the
-- auth.users row cascades every user-owned table (profiles, blocker_state,
-- traffic_events, traffic_summaries, llm_insights, friend_pairings,
-- friend_set_limits) via their ON DELETE CASCADE foreign keys.
--
-- SECURITY DEFINER so it runs as the function owner (postgres, which has DELETE
-- on auth.users). It can only ever delete the *caller's own* row — auth.uid()
-- comes from the verified JWT, so there is no way to target another account.

create or replace function public.delete_current_user()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;
  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_current_user() from public, anon;
grant execute on function public.delete_current_user() to authenticated;

comment on function public.delete_current_user() is
  'Permanently deletes the calling user''s own account (auth.users row) and all cascaded data. Called by the iOS app after re-verifying an emailed OTP.';
