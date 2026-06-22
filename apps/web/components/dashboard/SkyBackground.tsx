"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface SkyBackgroundProps {
  children: React.ReactNode;
  /** Retained for API compatibility with earlier callers; no longer used. */
  animateClouds?: boolean;
}

/**
 * Stark page surface for the dashboard: flat true-black. No glow, no gradient —
 * the content (hairline cards, monochrome charts) carries the design.
 */
export default function SkyBackground({ children }: SkyBackgroundProps) {
  const wrapperStyle: CSSProperties = {
    minHeight: "100vh",
    background: theme.gradient.stop4,
    color: theme.colors.white,
    fontFamily: theme.fonts.body,
  };

  return <div style={wrapperStyle}>{children}</div>;
}
