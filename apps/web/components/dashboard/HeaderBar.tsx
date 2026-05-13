"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";

interface HeaderBarProps {
  email?: string;
  onSignOut?: () => void;
}

export default function HeaderBar({ email, onSignOut }: HeaderBarProps) {
  const headerStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    padding: `${theme.spacing.md + 10}px ${theme.spacing.lg + 5}px`,
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: theme.fontSizes.headerTitle,
    color: theme.colors.white,
  };

  const rightStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.md,
  };

  const emailStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white60,
  };

  const signOutStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white60,
    background: "none",
    border: `1px solid ${theme.colors.white30}`,
    borderRadius: 16,
    padding: `${theme.spacing.xs}px ${theme.spacing.md}px`,
    cursor: "pointer",
    transition: "all 0.2s ease",
  };

  return (
    <header style={headerStyle}>
      <div style={titleStyle}>BUBBLE</div>
      <div style={rightStyle}>
        {email && <span style={emailStyle}>{email}</span>}
        {onSignOut && (
          <button style={signOutStyle} onClick={onSignOut}>
            Sign Out
          </button>
        )}
      </div>
    </header>
  );
}
