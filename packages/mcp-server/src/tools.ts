import { FastMCP } from "fastmcp";
import { z } from "zod";
import { supabase } from "./db.js";

// The tools run with the Supabase SERVICE-ROLE key, which bypasses RLS. To stop
// a caller (or a prompt-injected model) from reading/mutating an arbitrary
// account's safety-critical blocker settings, scope the server to a single user
// when RINKLER_USER_ID is set: any user_id arg must match it (or may be omitted
// and defaults to it). Set RINKLER_USER_ID in every real deployment.
const SCOPED_USER_ID = process.env.RINKLER_USER_ID;

function resolveUserId(requested?: string): string {
  if (SCOPED_USER_ID) {
    if (requested && requested !== SCOPED_USER_ID) {
      throw new Error(
        "Unauthorized: this server is scoped to a single user; user_id does not match RINKLER_USER_ID."
      );
    }
    return SCOPED_USER_ID;
  }
  if (!requested) {
    throw new Error(
      "user_id is required (or set RINKLER_USER_ID to scope this server to one account)."
    );
  }
  return requested;
}

export function registerTools(server: FastMCP) {
  server.addTool({
    name: "ping",
    description: "Health check — returns pong",
    execute: async () => "pong",
  });

  server.addTool({
    name: "get_blocker_state",
    description:
      "Get all blocker configs for a user. Returns is_active (computed from is_enabled + expires_at) and expires_at for countdown display.",
    parameters: z.object({
      user_id: z
        .string()
        .uuid()
        .optional()
        .describe("The user's UUID (optional/ignored when the server is scoped via RINKLER_USER_ID)"),
      active_only: z
        .boolean()
        .optional()
        .describe("If true, only return currently active blockers (default: false)"),
    }),
    execute: async ({ user_id, active_only }) => {
      const uid = resolveUserId(user_id);
      let query = supabase
        .from("active_blocker_state")
        .select("*")
        .eq("user_id", uid);
      if (active_only) {
        query = query.eq("is_active", true);
      }
      const { data, error } = await query;
      if (error) throw new Error(error.message);
      return JSON.stringify(data, null, 2);
    },
  });

  server.addTool({
    name: "set_blocker_option",
    description:
      "Enable or disable a blocking option for a user. Pass duration_minutes for a timed blocker (e.g. 180 for 3 hours). Omit duration_minutes for a permanent toggle.",
    parameters: z.object({
      user_id: z
        .string()
        .uuid()
        .optional()
        .describe("The user's UUID (optional/ignored when the server is scoped via RINKLER_USER_ID)"),
      app_id: z
        .string()
        .min(1)
        .describe("App ID (e.g. instagram, tiktok, youtube)"),
      option_id: z
        .string()
        .min(1)
        .describe("Option ID (e.g. reels, scroll, video)"),
      is_enabled: z.boolean().describe("Whether the option should be enabled"),
      duration_minutes: z
        .number()
        .positive()
        .optional()
        .describe(
          "Duration in minutes. Sets expires_at = now + duration. Omit for permanent."
        ),
    }),
    execute: async ({ user_id, app_id, option_id, is_enabled, duration_minutes }) => {
      const uid = resolveUserId(user_id);
      const expires_at = duration_minutes
        ? new Date(Date.now() + duration_minutes * 60_000).toISOString()
        : null;

      const { data, error } = await supabase
        .from("blocker_state")
        .upsert(
          {
            user_id: uid,
            app_id,
            option_id,
            is_enabled,
            expires_at,
            updated_at: new Date().toISOString(),
          },
          { onConflict: "user_id,app_id,option_id" }
        )
        .select()
        .single();
      if (error) throw new Error(error.message);
      return JSON.stringify(data, null, 2);
    },
  });

  server.addTool({
    name: "list_apps",
    description: "List all available apps and their blocking options",
    execute: async () => {
      const apps = [
        {
          id: "instagram",
          name: "Instagram",
          options: ["reels"],
        },
        {
          id: "tiktok",
          name: "TikTok",
          options: ["scroll"],
        },
        {
          id: "youtube",
          name: "YouTube",
          options: ["video"],
        },
      ];
      return JSON.stringify(apps, null, 2);
    },
  });
}
