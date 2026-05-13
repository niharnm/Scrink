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
          fontSize: theme.fontSizes.optionLabel,
          color: theme.colors.white,
          background: active ? theme.colors.skyBlue : "transparent",
          border: `1px solid ${active ? theme.colors.white : theme.colors.white30}`,
          borderRadius: 20,
          padding: `${theme.spacing.sm}px ${theme.spacing.md}px`,
          cursor: "pointer",
          transition: "all 0.2s ease",
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
