alter table public.traffic_events
  add column if not exists client_event_id text not null default (gen_random_uuid()::text);

create unique index if not exists traffic_events_user_client_event_id_idx
  on public.traffic_events (user_id, client_event_id);

create or replace function public.upsert_traffic_summary_for_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.traffic_summaries (
    user_id,
    period,
    bucket,
    app_category,
    total_requests,
    blocked_count,
    allowed_count,
    bytes_in,
    bytes_out,
    updated_at
  )
  values (
    new.user_id,
    'hourly',
    date_trunc('hour', new.ts),
    coalesce(new.app_category, 'other'),
    1,
    case when new.was_blocked then 1 else 0 end,
    case when new.was_blocked then 0 else 1 end,
    new.bytes_in,
    new.bytes_out,
    now()
  )
  on conflict (user_id, period, bucket, app_category)
  do update set
    total_requests = public.traffic_summaries.total_requests + 1,
    blocked_count = public.traffic_summaries.blocked_count + case when excluded.blocked_count > 0 then 1 else 0 end,
    allowed_count = public.traffic_summaries.allowed_count + case when excluded.allowed_count > 0 then 1 else 0 end,
    bytes_in = public.traffic_summaries.bytes_in + excluded.bytes_in,
    bytes_out = public.traffic_summaries.bytes_out + excluded.bytes_out,
    updated_at = now();

  insert into public.traffic_summaries (
    user_id,
    period,
    bucket,
    app_category,
    total_requests,
    blocked_count,
    allowed_count,
    bytes_in,
    bytes_out,
    updated_at
  )
  values (
    new.user_id,
    'daily',
    date_trunc('day', new.ts),
    coalesce(new.app_category, 'other'),
    1,
    case when new.was_blocked then 1 else 0 end,
    case when new.was_blocked then 0 else 1 end,
    new.bytes_in,
    new.bytes_out,
    now()
  )
  on conflict (user_id, period, bucket, app_category)
  do update set
    total_requests = public.traffic_summaries.total_requests + 1,
    blocked_count = public.traffic_summaries.blocked_count + case when excluded.blocked_count > 0 then 1 else 0 end,
    allowed_count = public.traffic_summaries.allowed_count + case when excluded.allowed_count > 0 then 1 else 0 end,
    bytes_in = public.traffic_summaries.bytes_in + excluded.bytes_in,
    bytes_out = public.traffic_summaries.bytes_out + excluded.bytes_out,
    updated_at = now();

  return new;
end;
$$;

drop trigger if exists on_traffic_event_summary on public.traffic_events;
create trigger on_traffic_event_summary
  after insert on public.traffic_events
  for each row execute function public.upsert_traffic_summary_for_event();

revoke execute on function public.upsert_traffic_summary_for_event() from public, anon, authenticated;
grant execute on function public.upsert_traffic_summary_for_event() to service_role;

select public.recompute_all_rollups();
