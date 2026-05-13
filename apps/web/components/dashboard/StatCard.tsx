"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface StatCardProps {
  label: string;
  value: string;
  subtitle?: string;
}

export default function StatCard({ label, value, subtitle }: StatCardProps) {
  const cardStyle: CSSProperties = {
    background: theme.colors.white15,
    borderRadius: 20,
    padding: `${theme.spacing.lg}px ${theme.spacing.xl}px`,
    border: `1px solid ${theme.colors.white30}`,
    minWidth: 180,
    flex: 1,
  };

  const labelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.optionLabel,
    color: theme.colors.white60,
    marginBottom: theme.spacing.sm,
    textTransform: "uppercase",
    letterSpacing: 1,
  };

  const valueStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 28,
    color: theme.colors.white,
    lineHeight: 1.2,
    fontWeight: 400,
  };

  const subtitleStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white60,
    marginTop: theme.spacing.xs,
  };

  return (
    <div style={cardStyle}>
      <div style={labelStyle}>{label}</div>
      <div style={valueStyle}>{value}</div>
      {subtitle && <div style={subtitleStyle}>{subtitle}</div>}
    </div>
  );
}
