-- Schedule the daily retention purge.
--
-- cleanup_old_traffic() deletes traffic_events older than 90 days and
-- traffic_summaries older than 180 days. Without a schedule nothing ever calls
-- it, so server-side data (hostnames, byte counts, timestamps) grows unbounded —
-- a privacy-label and storage-cost problem. pg_cron runs it in the database, so
-- no service-role key or HTTP endpoint is needed.
--
-- Apply to prod via the Supabase SQL editor or Management API. Re-running is safe:
-- cron.schedule upserts by job name.

create extension if not exists pg_cron;

select cron.schedule(
  'rinkler-cleanup-old-traffic',
  '0 4 * * *', -- daily at 04:00 UTC
  $$ select public.cleanup_old_traffic(); $$
);
