"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";
import { formatBytes } from "@/lib/format";

interface BandwidthCardProps {
  totalBytesIn: number;
  totalBytesOut: number;
}

export default function BandwidthCard({ totalBytesIn, totalBytesOut }: BandwidthCardProps) {
  const cardStyle: CSSProperties = {
    background: "rgba(255,255,255,0.018)",
    borderRadius: 14,
    padding: "16px 18px",
    border: "1px solid rgba(255,255,255,0.08)",
    minWidth: 150,
    flex: 1,
    display: "flex",
    flexDirection: "column",
    gap: 12,
  };

  const labelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 11,
    fontWeight: 600,
    color: theme.colors.white60,
    textTransform: "uppercase",
    letterSpacing: 1.2,
  };

  const row: CSSProperties = { display: "flex", alignItems: "baseline", gap: 8 };
  const arrow: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 13, color: theme.colors.white60, width: 12 };
  const value: CSSProperties = { fontFamily: theme.fonts.mono, fontSize: 18, color: theme.colors.white, letterSpacing: "-0.01em" };
  const unit: CSSProperties = { fontFamily: theme.fonts.body, fontSize: 12, color: theme.colors.white60 };

  return (
    <div style={cardStyle}>
      <div style={labelStyle}>Bandwidth</div>
      <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
        <div style={row}>
          <span style={arrow}>↓</span>
          <span style={value}>{formatBytes(totalBytesIn)}</span>
          <span style={unit}>in</span>
        </div>
        <div style={row}>
          <span style={arrow}>↑</span>
          <span style={value}>{formatBytes(totalBytesOut)}</span>
          <span style={unit}>out</span>
        </div>
      </div>
    </div>
  );
}
