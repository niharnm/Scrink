"use client";

import { CSSProperties, useMemo } from "react";
import { theme } from "@/lib/theme";

interface SkyBackgroundProps {
  children: React.ReactNode;
  /** Kept for API compatibility; the night sky always gently twinkles. */
  animateClouds?: boolean;
}

/** Rinkler's "Living Sky": a deep night sky warming toward dawn at the horizon,
 *  with a quiet starfield. Matches the iOS SkyBackgroundView and the marketing
 *  site so login + dashboard share one identity. */
export default function SkyBackground({ children }: SkyBackgroundProps) {
  // Deterministic starfield (seeded) so SSR and client agree — no hydration jump.
  const stars = useMemo(() => {
    let seed = 0x9e3779b9;
    const rand = () => {
      seed = (seed * 1664525 + 1013904223) >>> 0;
      return seed / 0xffffffff;
    };
    return Array.from({ length: 80 }, () => {
      const a = 0.25 + rand() * 0.55;
      return {
        left: `${rand() * 100}%`,
        top: `${rand() * 78}%`,
        size: `${0.8 + rand() * 2.1}px`,
        a,
        dur: `${3 + rand() * 4}s`,
        delay: `${rand() * 4}s`,
      };
    });
  }, []);

  const wrapperStyle: CSSProperties = {
    minHeight: "100vh",
    position: "relative",
    overflow: "hidden",
    background: `radial-gradient(1100px 640px at 50% 118%, rgba(245,201,168,0.20), transparent 60%), linear-gradient(to bottom, ${theme.gradient.stop1}, ${theme.gradient.stop2}, ${theme.gradient.stop4})`,
    color: theme.colors.white,
  };

  const starLayerStyle: CSSProperties = {
    position: "fixed",
    inset: 0,
    pointerEvents: "none",
    zIndex: 0,
  };

  const contentStyle: CSSProperties = {
    position: "relative",
    zIndex: 1,
  };

  return (
    <div style={wrapperStyle}>
      <style
        dangerouslySetInnerHTML={{
          __html:
            "@keyframes rnk-twinkle{0%,100%{opacity:var(--a0)}50%{opacity:var(--a1)}}",
        }}
      />
      <div style={starLayerStyle} aria-hidden>
        {stars.map((s, i) => (
          <span
            key={i}
            style={
              {
                position: "absolute",
                left: s.left,
                top: s.top,
                width: s.size,
                height: s.size,
                borderRadius: "50%",
                background: "#fff",
                "--a0": s.a * 0.35,
                "--a1": s.a,
                opacity: s.a,
                animation: `rnk-twinkle ${s.dur} ease-in-out infinite`,
                animationDelay: s.delay,
              } as CSSProperties
            }
          />
        ))}
      </div>
      <div style={contentStyle}>{children}</div>
    </div>
  );
}
