"use client";

import { useEffect, useRef, CSSProperties } from "react";
import { theme } from "@/lib/theme";

const CLOUD_COPIES = 6;
const CLOUD_OVERLAP = 5;

interface SkyBackgroundProps {
  children: React.ReactNode;
  /** When true, clouds scroll. When false, clouds are static. Default false. */
  animateClouds?: boolean;
}

export default function SkyBackground({
  children,
  animateClouds = false,
}: SkyBackgroundProps) {
  const stripRef = useRef<HTMLDivElement>(null);
  const offsetRef = useRef(0);
  const frameRef = useRef<number>(0);

  useEffect(() => {
    if (!animateClouds) return;

    const strip = stripRef.current;
    if (!strip) return;

    let cancelled = false;

    function startAnimation(singleWidth: number) {
      const speed = singleWidth / (theme.animation.cloudDuration * 600);
      const el = strip!;

      const tick = () => {
        if (cancelled) return;
        offsetRef.current -= speed;
        if (Math.abs(offsetRef.current) >= singleWidth - CLOUD_OVERLAP) {
          offsetRef.current += singleWidth - CLOUD_OVERLAP;
        }
        el.style.transform = `translateX(${offsetRef.current}px)`;
        frameRef.current = requestAnimationFrame(tick);
      };
      frameRef.current = requestAnimationFrame(tick);
    }

    const img = new Image();
    img.src = "/images/clouds_continous.png";

    if (img.complete && img.naturalWidth > 0) {
      startAnimation(img.naturalWidth);
    } else {
      img.onload = () => {
        if (!cancelled) startAnimation(img.naturalWidth);
      };
    }

    return () => {
      cancelled = true;
      cancelAnimationFrame(frameRef.current);
    };
  }, [animateClouds]);

  const wrapperStyle: CSSProperties = {
    minHeight: "100vh",
    position: "relative",
    background: `linear-gradient(to bottom, ${theme.gradient.stop1}, ${theme.gradient.stop2}, ${theme.gradient.stop3}, ${theme.gradient.stop4})`,
  };

  const cloudContainerStyle: CSSProperties = {
    position: "fixed",
    bottom: 0,
    left: 0,
    width: "100%",
    height: "25%",
    overflow: "hidden",
    pointerEvents: "none",
    zIndex: 0,
  };

  const cloudStripStyle: CSSProperties = {
    display: "flex",
    height: "100%",
    willChange: animateClouds ? "transform" : "auto",
  };

  const cloudImgStyle: CSSProperties = {
    height: "100%",
    width: "auto",
    marginRight: -CLOUD_OVERLAP,
    flexShrink: 0,
    userSelect: "none",
    pointerEvents: "none",
  };

  const contentStyle: CSSProperties = {
    position: "relative",
    zIndex: 1,
  };

  return (
    <div style={wrapperStyle}>
      <div style={cloudContainerStyle}>
        <div ref={stripRef} style={cloudStripStyle}>
          {Array.from({ length: CLOUD_COPIES }).map((_, i) => (
            <img
              key={i}
              src="/images/clouds_continous.png"
              alt=""
              style={cloudImgStyle}
              draggable={false}
            />
          ))}
        </div>
      </div>
      <div style={contentStyle}>{children}</div>
    </div>
  );
}
