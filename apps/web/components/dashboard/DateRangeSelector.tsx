"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

type Range = "today" | "7d" | "30d";

interface DateRangeSelectorProps {
  value: Range;
  onChange: (range: Range) => void;
}

const options: { label: string; value: Range }[] = [
  { label: "Today", value: "today" },
  { label: "7 days", value: "7d" },
  { label: "30 days", value: "30d" },
];

export default function DateRangeSelector({
  value,
  onChange,
}: DateRangeSelectorProps) {
  const containerStyle: CSSProperties = {
    display: "flex",
    gap: theme.spacing.sm,
  };

  return (
    <div style={containerStyle}>
      {options.map((opt) => {
        const active = value === opt.value;
        const pillStyle: CSSProperties = {
          fontFamily: theme.fonts.body,
          fontSize: 14,
          fontWeight: active ? 600 : 500,
          color: active ? "#08080A" : theme.colors.white60,
          background: active ? theme.colors.white : "transparent",
          border: `1px solid ${active ? theme.colors.white : theme.colors.white30}`,
          borderRadius: 8,
          padding: "7px 14px",
          cursor: "pointer",
          transition: "all 0.15s ease",
        };
        return (
          <button
            key={opt.value}
            style={pillStyle}
            onClick={() => onChange(opt.value)}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
