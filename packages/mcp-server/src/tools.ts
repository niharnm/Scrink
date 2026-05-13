import { FastMCP } from "fastmcp";
import { z } from "zod";
import { supabase } from "./db.js";

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
      user_id: z.string().describe("The user's UUID"),
      active_only: z
        .boolean()
        .optional()
        .describe("If true, only return currently active blockers (default: false)"),
    }),
    execute: async ({ user_id, active_only }) => {
      let query = supabase
        .from("active_blocker_state")
        .select("*")
        .eq("user_id", user_id);
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
      user_id: z.string().describe("The user's UUID"),
      app_id: z.string().describe("App ID (e.g. instagram, shield, kalshi)"),
      option_id: z.string().describe("Option ID (e.g. reels, msgs, ex-gf)"),
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
      const expires_at = duration_minutes
        ? new Date(Date.now() + duration_minutes * 60_000).toISOString()
        : null;

      const { data, error } = await supabase
        .from("blocker_state")
        .upsert(
          {
            user_id,
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
          options: ["reels", "msgs", "ex-gf", "explore"],
        },
        {
          id: "shield",
          name: "Shield (Facebook)",
          options: ["alerts", "feeds"],
        },
        { id: "kalshi", name: "Kalshi", options: ["trades", "notifs"] },
      ];
      return JSON.stringify(apps, null, 2);
    },
  });
}
