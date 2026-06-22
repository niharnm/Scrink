"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";
import Ring from "./Ring";

/**
 * Shown when no traffic has synced yet. Designed to look intentional and
 * inviting (not a broken/empty page): explains what will appear and where the
 * data comes from, with ghosted previews of the cards to come.
 */
export default function EmptyState() {
  const wrap: CSSProperties = {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    textAlign: "center",
    padding: "56px 24px 40px",
    background: "linear-gradient(180deg, rgba(255,255,255,0.04), rgba(255,255,255,0.012))",
    border: "1px solid rgba(255,255,255,0.08)",
    borderRadius: 24,
    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.05), 0 12px 40px rgba(0,0,0,0.3)",
  };

  const title: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 26,
    fontWeight: 600,
    color: theme.colors.white,
    letterSpacing: "-0.02em",
    marginTop: 24,
  };

  const body: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 15,
    lineHeight: 1.6,
    color: theme.colors.white60,
    maxWidth: 460,
    marginTop: 12,
  };

  const previewRow: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "repeat(2, 1fr)",
    gap: 14,
    width: "100%",
    maxWidth: 460,
    marginTop: 36,
  };

  const ghostCard: CSSProperties = {
    background: "rgba(255,255,255,0.025)",
    border: "1px dashed rgba(255,255,255,0.12)",
    borderRadius: 16,
    padding: "16px 18px",
    textAlign: "left",
  };

  const ghostLabel: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 11,
    fontWeight: 600,
    letterSpacing: 1.2,
    textTransform: "uppercase",
    color: theme.colors.white60,
  };

  const ghostBar = (w: string): CSSProperties => ({
    height: 10,
    width: w,
    borderRadius: 6,
    background: "rgba(255,255,255,0.07)",
    marginTop: 12,
  });

  const note: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 13,
    color: theme.colors.white60,
    opacity: 0.85,
    marginTop: 32,
    display: "inline-flex",
    alignItems: "center",
    gap: 8,
  };

  const previews = ["Time saved", "Feeds blocked", "Top offenders", "Trends"];

  return (
    <div style={wrap}>
      <Ring percent={0.18} size={120} stroke={10} gradId="emptyRing">
        <svg width="34" height="34" viewBox="0 0 24 24" fill="none" stroke="#ECECEE" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 12a9 9 0 1 0 9-9" />
          <path d="M12 7v5l3 2" />
        </svg>
      </Ring>

      <div style={title}>Your report is waiting on your phone</div>
      <div style={body}>
        Rinkler filters traffic on your device — so this dashboard fills in once
        your phone starts syncing. Open the app, start a Control Session, and
        blocked feeds, time saved, and trends will show up right here.
      </div>

      <div style={previewRow}>
        {previews.map((p) => (
          <div key={p} style={ghostCard}>
            <div style={ghostLabel}>{p}</div>
            <div style={ghostBar("70%")} />
            <div style={ghostBar("45%")} />
          </div>
        ))}
      </div>

      <div style={note}>
        <span
          style={{
            width: 7,
            height: 7,
            borderRadius: "50%",
            background: theme.colors.success,
            boxShadow: `0 0 10px ${theme.colors.success}`,
          }}
        />
        Protection runs on your phone — nothing leaves your device.
      </div>
    </div>
  );
}
