"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface HeatmapGridProps {
  data: number[][];
}

const DAYS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
const HOURS = Array.from({ length: 24 }, (_, i) =>
  i === 0 ? "12a" : i < 12 ? `${i}a` : i === 12 ? "12p" : `${i - 12}p`
);

function intensityToColor(value: number): string {
  const r = Math.round(255 - (255 - 58) * value);
  const g = Math.round(255 - (255 - 141) * value);
  const b = Math.round(255 - (255 - 222) * value);
  const alpha = 0.15 + value * 0.7;
  return `rgba(${r},${g},${b},${alpha})`;
}

export default function HeatmapGrid({ data }: HeatmapGridProps) {
  const cardStyle: CSSProperties = {
    background: theme.colors.white10,
    borderRadius: 20,
    padding: theme.spacing.lg,
    border: `1px solid ${theme.colors.white30}`,
    overflowX: "auto",
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 20,
    color: theme.colors.white,
    marginBottom: theme.spacing.md,
  };

  const gridStyle: CSSProperties = {
    display: "grid",
    gridTemplateColumns: `40px repeat(24, 1fr)`,
    gap: 2,
  };

  const hourLabelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 10,
    color: theme.colors.white60,
    textAlign: "center",
    paddingBottom: 4,
  };

  const dayLabelStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 12,
    color: theme.colors.white60,
    display: "flex",
    alignItems: "center",
    paddingRight: 8,
  };

  const cellStyle = (value: number): CSSProperties => ({
    aspectRatio: "1",
    borderRadius: 4,
    background: intensityToColor(value),
    border: `1px solid rgba(255,255,255,0.08)`,
    minWidth: 16,
    transition: "background 0.2s ease",
  });

  return (
    <div style={cardStyle}>
      <div style={titleStyle}>Activity Heatmap</div>
      <div style={gridStyle}>
        <div />
        {HOURS.map((h, i) => (
          <div key={`hour-${i}`} style={hourLabelStyle}>
            {i % 3 === 0 ? h : ""}
          </div>
        ))}

        {DAYS.map((day, di) => (
          <div key={day} style={{ display: "contents" }}>
            <div style={dayLabelStyle}>{day}</div>
            {Array.from({ length: 24 }).map((_, hi) => (
              <div
                key={`${day}-${hi}`}
                style={cellStyle(data[di]?.[hi] ?? 0)}
                title={`${day} ${HOURS[hi]}: ${Math.round((data[di]?.[hi] ?? 0) * 100)}%`}
              />
            ))}
          </div>
        ))}
      </div>
    </div>
  );
}
