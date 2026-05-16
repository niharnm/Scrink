export const missingSupabaseConfigMessage =
  "Supabase is not configured for this deployment.";

export function getSupabasePublicConfig() {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;

  if (!url || !publishableKey) {
    return null;
  }

  return { url, publishableKey };
}

export function requireSupabasePublicConfig() {
  const config = getSupabasePublicConfig();
  if (!config) {
    throw new Error(missingSupabaseConfigMessage);
  }
  return config;
}
