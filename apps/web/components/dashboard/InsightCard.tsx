"use client";

import { CSSProperties, useState } from "react";
import { theme } from "@/lib/theme";

interface InsightCardProps {
  text: string;
  onGenerate?: () => Promise<string | null>;
}

export default function InsightCard({ text, onGenerate }: InsightCardProps) {
  const [displayText, setDisplayText] = useState(text);
  const [loading, setLoading] = useState(false);

  const handleGenerate = async () => {
    if (!onGenerate || loading) return;
    setLoading(true);
    try {
      const result = await onGenerate();
      if (result) setDisplayText(result);
    } finally {
      setLoading(false);
    }
  };

  const cardStyle: CSSProperties = {
    background: theme.colors.white10,
    borderRadius: 20,
    padding: `${theme.spacing.lg}px ${theme.spacing.xl}px`,
    border: `1px solid ${theme.colors.white30}`,
  };

  const headerRowStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: theme.spacing.sm,
  };

  const headerStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 20,
    color: theme.colors.white,
  };

  const buttonStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 13,
    color: loading ? theme.colors.white30 : theme.colors.white,
    background: theme.colors.white10,
    border: `1px solid ${theme.colors.white30}`,
    borderRadius: 12,
    padding: "6px 14px",
    cursor: loading ? "default" : "pointer",
    transition: "all 0.2s ease",
  };

  const textStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 15,
    color: theme.colors.white60,
    lineHeight: 1.6,
    fontStyle: "italic",
  };

  return (
    <div style={cardStyle}>
      <div style={headerRowStyle}>
        <div style={headerStyle}>Insight</div>
        {onGenerate && (
          <button style={buttonStyle} onClick={handleGenerate} disabled={loading}>
            {loading ? "Generating..." : "Generate Insight"}
          </button>
        )}
      </div>
      <div style={textStyle}>{displayText}</div>
    </div>
  );
}
