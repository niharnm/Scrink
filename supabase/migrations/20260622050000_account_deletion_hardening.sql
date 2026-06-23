-- Harden self-service deletion: some user-linked tables have no ON DELETE
-- CASCADE foreign key to auth.users, so deleting the auth row alone would leave
-- orphaned, user-attributable rows (a right-to-erasure gap). Explicitly purge
-- them inside the SECURITY DEFINER RPC before deleting the account:
--   * friend_redeem_attempts.user_id  — bare uuid throttle log, no FK
--   * friend_set_limits.set_by        — limits THIS user imposed on others'
--     accounts (their own owned pairings already cascade)

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

  delete from public.friend_redeem_attempts where user_id = uid;
  delete from public.friend_set_limits where set_by = uid;

  delete from auth.users where id = uid;
end;
$$;

revoke all on function public.delete_current_user() from public, anon;
grant execute on function public.delete_current_user() to authenticated;
