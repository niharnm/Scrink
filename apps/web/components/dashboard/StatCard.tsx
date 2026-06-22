"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface StatCardProps {
  label: string;
  value: string;
  subtitle?: string;
  accent?: boolean;
}

export default function StatCard({ label, value, subtitle, accent }: StatCardProps) {
  const cardStyle: CSSProperties = {
    background: "linear-gradient(180deg, rgba(255,255,255,0.055), rgba(255,255,255,0.018))",
    borderRadius: 18,
    padding: "18px 20px",
    border: `1px solid ${accent ? "rgba(91,124,255,0.35)" : "rgba(255,255,255,0.08)"}`,
    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 8px 24px rgba(0,0,0,0.28)",
    minWidth: 150,
    flex: 1,
    display: "flex",
    flexDirection: "column",
    justifyContent: "space-between",
    gap: 14,
  };

  const labelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 11,
    fontWeight: 600,
    color: theme.colors.white60,
    textTransform: "uppercase",
    letterSpacing: 1.2,
  };

  const valueStyle: CSSProperties = {
    fontFamily: theme.fonts.mono,
    fontSize: 26,
    color: theme.colors.white,
    lineHeight: 1.05,
    letterSpacing: "-0.01em",
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 12.5,
    color: theme.colors.white60,
  };

  return (
    <div style={cardStyle}>
      <div style={labelStyle}>{label}</div>
      <div>
        <div style={valueStyle}>{value}</div>
        {subtitle && <div style={{ ...subtitleStyle, marginTop: 4 }}>{subtitle}</div>}
      </div>
    </div>
  );
}
