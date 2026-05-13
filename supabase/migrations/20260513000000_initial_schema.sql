create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own"
  on public.profiles for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "profiles_update_own"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists public.blocker_state (
  user_id uuid not null references auth.users(id) on delete cascade,
  app_id text not null check (length(app_id) > 0),
  option_id text not null check (length(option_id) > 0),
  is_enabled boolean not null default false,
  expires_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, app_id, option_id)
);

alter table public.blocker_state enable row level security;

create policy "blocker_state_select_own"
  on public.blocker_state for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "blocker_state_write_own"
  on public.blocker_state for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create or replace view public.active_blocker_state
with (security_invoker = true) as
select
  user_id,
  app_id,
  option_id,
  is_enabled,
  expires_at,
  updated_at,
  (is_enabled and (expires_at is null or expires_at > now())) as is_active
from public.blocker_state;

create table if not exists public.traffic_events (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  ts timestamptz not null default now(),
  host text not null,
  app_category text not null default 'other',
  method text,
  content_type text,
  bytes_in bigint not null default 0 check (bytes_in >= 0),
  bytes_out bigint not null default 0 check (bytes_out >= 0),
  was_blocked boolean not null default false,
  block_reason text,
  metadata jsonb not null default '{}'::jsonb
);

create index if not exists traffic_events_user_ts_idx on public.traffic_events (user_id, ts desc);
create index if not exists traffic_events_user_category_ts_idx on public.traffic_events (user_id, app_category, ts desc);
create index if not exists traffic_events_host_idx on public.traffic_events (host);

alter table public.traffic_events enable row level security;

create policy "traffic_events_select_own"
  on public.traffic_events for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "traffic_events_insert_own"
  on public.traffic_events for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create table if not exists public.traffic_summaries (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  period text not null check (period in ('hourly', 'daily')),
  bucket timestamptz not null,
  app_category text not null default 'other',
  total_requests bigint not null default 0,
  blocked_count bigint not null default 0,
  allowed_count bigint not null default 0,
  bytes_in bigint not null default 0,
  bytes_out bigint not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id, period, bucket, app_category)
);

create index if not exists traffic_summaries_user_period_bucket_idx
  on public.traffic_summaries (user_id, period, bucket desc);

alter table public.traffic_summaries enable row level security;

create policy "traffic_summaries_select_own"
  on public.traffic_summaries for select
  to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.llm_insights (
  id bigserial primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  job_type text not null,
  content text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.llm_insights enable row level security;

create policy "llm_insights_select_own"
  on public.llm_insights for select
  to authenticated
  using ((select auth.uid()) = user_id);

create table if not exists public.cron_runs (
  id bigserial primary key,
  job_type text not null,
  status text not null,
  finished_at timestamptz,
  result jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.cron_runs enable row level security;

create policy "cron_runs_service_only"
  on public.cron_runs for all
  to service_role
  using (true)
  with check (true);

create or replace function public.rollup_traffic(target_period text)
returns void
language sql
security definer
set search_path = public
as $$
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
  select
    user_id,
    target_period,
    case
      when target_period = 'hourly' then date_trunc('hour', ts)
      else date_trunc('day', ts)
    end as bucket,
    coalesce(app_category, 'other') as app_category,
    count(*) as total_requests,
    count(*) filter (where was_blocked) as blocked_count,
    count(*) filter (where not was_blocked) as allowed_count,
    coalesce(sum(bytes_in), 0) as bytes_in,
    coalesce(sum(bytes_out), 0) as bytes_out,
    now() as updated_at
  from public.traffic_events
  where ts >= now() - interval '90 days'
  group by user_id, bucket, app_category
  on conflict (user_id, period, bucket, app_category)
  do update set
    total_requests = excluded.total_requests,
    blocked_count = excluded.blocked_count,
    allowed_count = excluded.allowed_count,
    bytes_in = excluded.bytes_in,
    bytes_out = excluded.bytes_out,
    updated_at = now();
$$;

create or replace function public.rollup_traffic_hourly()
returns void
language sql
security definer
set search_path = public
as $$
  select public.rollup_traffic('hourly');
$$;

create or replace function public.rollup_traffic_daily()
returns void
language sql
security definer
set search_path = public
as $$
  select public.rollup_traffic('daily');
$$;

create or replace function public.recompute_all_rollups()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.traffic_summaries;
  perform public.rollup_traffic_hourly();
  perform public.rollup_traffic_daily();
end;
$$;

create or replace function public.cleanup_old_traffic()
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.traffic_events where ts < now() - interval '90 days';
  delete from public.traffic_summaries where bucket < now() - interval '180 days';
$$;

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

grant usage on schema public to authenticated, service_role;

grant select, update on public.profiles to authenticated;
grant select, insert, update, delete on public.blocker_state to authenticated;
grant select on public.active_blocker_state to authenticated;
grant select, insert on public.traffic_events to authenticated;
grant select on public.traffic_summaries to authenticated;
grant select on public.llm_insights to authenticated;

grant all on public.profiles to service_role;
grant all on public.blocker_state to service_role;
grant select on public.active_blocker_state to service_role;
grant all on public.traffic_events to service_role;
grant all on public.traffic_summaries to service_role;
grant all on public.llm_insights to service_role;
grant all on public.cron_runs to service_role;

grant usage, select on sequence public.traffic_events_id_seq to authenticated;
grant usage, select on sequence public.traffic_events_id_seq to service_role;
grant usage, select on sequence public.traffic_summaries_id_seq to service_role;
grant usage, select on sequence public.llm_insights_id_seq to service_role;
grant usage, select on sequence public.cron_runs_id_seq to service_role;
