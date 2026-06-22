"use client";

import { ReactNode } from "react";

/** Signal-style progress ring (blue→violet). gradId must be unique per instance. */
export default function Ring({
  percent,
  size,
  stroke,
  children,
  gradId = "ringGrad",
  track = "rgba(255,255,255,0.08)",
  dashed = false,
}: {
  percent: number;
  size: number;
  stroke: number;
  children?: ReactNode;
  gradId?: string;
  track?: string;
  dashed?: boolean;
}) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = Math.max(0.0001, Math.min(1, percent)) * circ;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size}>
        <defs>
          <linearGradient id={gradId} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#5B7CFF" />
            <stop offset="100%" stopColor="#8B5CF6" />
          </linearGradient>
        </defs>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke={track}
          strokeWidth={stroke}
          strokeDasharray={dashed ? "2 8" : undefined}
          strokeLinecap="round"
        />
        {!dashed && (
          <circle
            cx={size / 2}
            cy={size / 2}
            r={r}
            fill="none"
            stroke={`url(#${gradId})`}
            strokeWidth={stroke}
            strokeLinecap="round"
            strokeDasharray={`${dash} ${circ}`}
            transform={`rotate(-90 ${size / 2} ${size / 2})`}
          />
        )}
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
        {children}
      </div>
    </div>
  );
}
