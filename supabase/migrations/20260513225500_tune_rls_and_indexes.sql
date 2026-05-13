create index if not exists llm_insights_user_id_idx
  on public.llm_insights (user_id);

drop policy if exists "blocker_state_write_own" on public.blocker_state;

create policy "blocker_state_insert_own"
  on public.blocker_state for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "blocker_state_update_own"
  on public.blocker_state for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "blocker_state_delete_own"
  on public.blocker_state for delete
  to authenticated
  using ((select auth.uid()) = user_id);
