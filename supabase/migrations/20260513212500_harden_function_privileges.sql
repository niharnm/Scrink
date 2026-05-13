create policy "cron_runs_service_only"
  on public.cron_runs for all
  to service_role
  using (true)
  with check (true);

revoke execute on function public.rollup_traffic(text) from public, anon, authenticated;
revoke execute on function public.rollup_traffic_hourly() from public, anon, authenticated;
revoke execute on function public.rollup_traffic_daily() from public, anon, authenticated;
revoke execute on function public.recompute_all_rollups() from public, anon, authenticated;
revoke execute on function public.cleanup_old_traffic() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;

grant execute on function public.rollup_traffic(text) to service_role;
grant execute on function public.rollup_traffic_hourly() to service_role;
grant execute on function public.rollup_traffic_daily() to service_role;
grant execute on function public.recompute_all_rollups() to service_role;
grant execute on function public.cleanup_old_traffic() to service_role;
