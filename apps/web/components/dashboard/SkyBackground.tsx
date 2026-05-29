"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface SkyBackgroundProps {
  children: React.ReactNode;
  /**
   * Retained for API compatibility. The cloud animation was replaced by the
   * dark glow aesthetic; when true the accent glow drifts subtly.
   */
  animateClouds?: boolean;
}

/**
 * Full-bleed dark backdrop: a deep navy base gradient with two soft radial
 * glows (cool blue + violet). Matches the iOS app's dark theme and gives the
 * glass cards above it enough contrast to read cleanly.
 */
export default function SkyBackground({
  children,
  animateClouds = false,
}: SkyBackgroundProps) {
  const wrapperStyle: CSSProperties = {
    minHeight: "100vh",
    position: "relative",
    background: `linear-gradient(160deg, ${theme.gradient.stop1}, ${theme.gradient.stop2} 38%, ${theme.gradient.stop3} 64%, ${theme.gradient.stop4})`,
    overflow: "hidden",
  };

  const glowStyle: CSSProperties = {
    position: "fixed",
    inset: 0,
    pointerEvents: "none",
    zIndex: 0,
    background: `radial-gradient(60% 50% at 12% 6%, ${theme.surface.glowA}, transparent 70%), radial-gradient(55% 55% at 92% 100%, ${theme.surface.glowB}, transparent 70%)`,
    animation: animateClouds ? "rinklerGlowDrift 18s ease-in-out infinite alternate" : undefined,
  };

  const grainStyle: CSSProperties = {
    position: "fixed",
    inset: 0,
    pointerEvents: "none",
    zIndex: 0,
    opacity: 0.5,
    background:
      "radial-gradient(120% 120% at 50% -10%, transparent 55%, rgba(0,0,0,0.35) 100%)",
  };

  const contentStyle: CSSProperties = {
    position: "relative",
    zIndex: 1,
  };

  return (
    <div style={wrapperStyle}>
      <style>{`
        @keyframes rinklerGlowDrift {
          0%   { transform: translate3d(0, 0, 0); }
          100% { transform: translate3d(-3%, 2%, 0); }
        }
      `}</style>
      <div style={glowStyle} />
      <div style={grainStyle} />
      <div style={contentStyle}>{children}</div>
    </div>
  );
}
