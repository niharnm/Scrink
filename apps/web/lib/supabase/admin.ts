import { createClient as createServiceClient } from "@supabase/supabase-js";

export function areDashboardAdminToolsEnabled() {
  return process.env.ENABLE_DASHBOARD_ADMIN_TOOLS === "true";
}

/**
 * Maintenance routes run cross-tenant operations with the service role (e.g.
 * recompute_all_rollups deletes ALL users' summaries). Gate them on an explicit
 * allow-list of admin user IDs, not just a feature flag, so a normal signed-in
 * user can never trigger them. Unset ADMIN_USER_IDS => nobody is admin (deny).
 */
export function isAdminUser(userId: string | null | undefined): boolean {
  if (!userId) return false;
  const ids = (process.env.ADMIN_USER_IDS || "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  return ids.includes(userId);
}

export function createAdminClient() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !serviceRoleKey) {
    return null;
  }

  return createServiceClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
