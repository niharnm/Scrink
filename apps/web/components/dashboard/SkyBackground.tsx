"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface SkyBackgroundProps {
  children: React.ReactNode;
  /** Retained for API compatibility with earlier callers; no longer used. */
  animateClouds?: boolean;
}

/**
 * Signal-identity page surface for the dashboard: a near-black gradient with a
 * single soft blue→violet glow at the top. Replaces the old animated blue
 * cloud background. Props are unchanged so existing call sites keep working.
 */
export default function SkyBackground({ children }: SkyBackgroundProps) {
  const wrapperStyle: CSSProperties = {
    minHeight: "100vh",
    position: "relative",
    color: theme.colors.white,
    fontFamily: theme.fonts.body,
    background: `linear-gradient(to bottom, ${theme.gradient.stop1}, ${theme.gradient.stop2}, ${theme.gradient.stop3}, ${theme.gradient.stop4})`,
  };

  const glowStyle: CSSProperties = {
    position: "fixed",
    top: -200,
    left: "50%",
    transform: "translateX(-50%)",
    width: "min(900px, 100vw)",
    height: 520,
    background:
      "radial-gradient(closest-side, rgba(91,124,255,0.20), rgba(139,92,246,0.07) 55%, transparent 75%)",
    filter: "blur(20px)",
    pointerEvents: "none",
    zIndex: 0,
  };

  const contentStyle: CSSProperties = {
    position: "relative",
    zIndex: 1,
  };

  return (
    <div style={wrapperStyle}>
      <div style={glowStyle} aria-hidden />
      <div style={contentStyle}>{children}</div>
    </div>
  );
}
