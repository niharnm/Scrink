"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";
import { formatBytes } from "@/lib/format";

interface BandwidthCardProps {
  totalBytesIn: number;
  totalBytesOut: number;
}

export default function BandwidthCard({
  totalBytesIn,
  totalBytesOut,
}: BandwidthCardProps) {
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

  const subStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white60,
    marginTop: theme.spacing.xs,
  };

  return (
    <>
      <div style={cardStyle}>
        <div style={labelStyle}>Data In</div>
        <div style={valueStyle}>{formatBytes(totalBytesIn)}</div>
        <div style={subStyle}>downloaded</div>
      </div>
      <div style={cardStyle}>
        <div style={labelStyle}>Data Out</div>
        <div style={valueStyle}>{formatBytes(totalBytesOut)}</div>
        <div style={subStyle}>uploaded</div>
      </div>
    </>
  );
}
