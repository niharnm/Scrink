"use client";

import { CSSProperties } from "react";
import { theme } from "@/lib/theme";
import { TopDomain } from "@/lib/analytics";
import { APP_META } from "@/lib/app-meta";

interface TopDomainsTableProps {
  domains: TopDomain[];
}

export default function TopDomainsTable({ domains }: TopDomainsTableProps) {
  const cardStyle: CSSProperties = {
    background: theme.colors.white10,
    borderRadius: 20,
    padding: theme.spacing.lg,
    border: `1px solid ${theme.colors.white30}`,
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 20,
    color: theme.colors.white,
    marginBottom: theme.spacing.md,
  };

  const scrollStyle: CSSProperties = {
    maxHeight: 320,
    overflowY: "auto",
  };

  const rowStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.md,
    padding: `${theme.spacing.sm}px 0`,
    borderBottom: `1px solid ${theme.colors.white10}`,
  };

  const rankStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white30,
    width: 28,
    textAlign: "right",
  };

  const domainStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white,
    flex: 1,
    overflow: "hidden",
    textOverflow: "ellipsis",
    whiteSpace: "nowrap",
  };

  const badgeStyle = (category: string): CSSProperties => ({
    fontFamily: theme.fonts.body,
    fontSize: 11,
    color: theme.colors.white,
    background: theme.colors.white15,
    border: `1px solid ${theme.colors.white30}`,
    borderRadius: 8,
    padding: "2px 8px",
    whiteSpace: "nowrap",
  });

  const countStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.small,
    color: theme.colors.white60,
    minWidth: 40,
    textAlign: "right",
  };

  if (domains.length === 0) {
    return (
      <div style={cardStyle}>
        <div style={titleStyle}>Top Domains</div>
        <div style={{ fontFamily: theme.fonts.body, fontSize: theme.fontSizes.small, color: theme.colors.white60 }}>
          No domain data available yet.
        </div>
      </div>
    );
  }

  return (
    <div style={cardStyle}>
      <div style={titleStyle}>Top Domains</div>
      <div style={scrollStyle}>
        {domains.map((d, i) => (
          <div key={d.domain} style={rowStyle}>
            <span style={rankStyle}>{i + 1}</span>
            <span style={domainStyle}>{d.domain}</span>
            <span style={badgeStyle(d.category)}>
              {APP_META[d.category]?.name || d.category}
            </span>
            <span style={countStyle}>{d.count}</span>
          </div>
        ))}
      </div>
    </div>
  );
}
