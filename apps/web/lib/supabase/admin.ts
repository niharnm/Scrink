import { createClient as createServiceClient } from "@supabase/supabase-js";

export function areDashboardAdminToolsEnabled() {
  return process.env.ENABLE_DASHBOARD_ADMIN_TOOLS === "true";
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
