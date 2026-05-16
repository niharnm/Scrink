"use client";

import { createBrowserClient } from "@supabase/ssr";
import { requireSupabasePublicConfig } from "./config";

export function createClient() {
  const config = requireSupabasePublicConfig();

  return createBrowserClient(
    config.url,
    config.publishableKey
  );
}
