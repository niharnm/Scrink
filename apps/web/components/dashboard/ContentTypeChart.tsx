"use client";

import { CSSProperties } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { theme } from "@/lib/theme";
import { ContentTypeEntry } from "@/lib/analytics";

interface ContentTypeChartProps {
  contentTypes: ContentTypeEntry[];
}

export default function ContentTypeChart({
  contentTypes,
}: ContentTypeChartProps) {
  const cardStyle: CSSProperties = {
    background: theme.colors.white10,
    borderRadius: 20,
    padding: theme.spacing.lg,
    border: `1px solid ${theme.colors.white30}`,
    flex: 1,
    minWidth: 280,
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 20,
    color: theme.colors.white,
    marginBottom: theme.spacing.md,
  };

  if (contentTypes.length === 0) {
    return (
      <div style={cardStyle}>
        <div style={titleStyle}>Content Types</div>
        <div style={{ fontFamily: theme.fonts.body, fontSize: theme.fontSizes.small, color: theme.colors.white60 }}>
          No content type data yet.
        </div>
      </div>
    );
  }

  // Shorten labels for display
  const data = contentTypes.map((ct) => ({
    name: ct.type.replace("application/", "").replace("text/", "t/"),
    count: ct.count,
    fullName: ct.type,
  }));

  return (
    <div style={cardStyle}>
      <div style={titleStyle}>Content Types</div>
      <ResponsiveContainer width="100%" height={220}>
        <BarChart
          data={data}
          layout="vertical"
          margin={{ top: 0, right: 10, left: 0, bottom: 0 }}
        >
          <XAxis
            type="number"
            tick={{
              fill: "rgba(255,255,255,0.6)",
              fontFamily: theme.fonts.body,
              fontSize: 11,
            }}
            axisLine={{ stroke: "rgba(255,255,255,0.2)" }}
            tickLine={false}
          />
          <YAxis
            type="category"
            dataKey="name"
            width={100}
            tick={{
              fill: "rgba(255,255,255,0.6)",
              fontFamily: theme.fonts.body,
              fontSize: 11,
            }}
            axisLine={false}
            tickLine={false}
          />
          <Tooltip
            contentStyle={{
              background: "rgba(26,95,170,0.95)",
              border: `1px solid ${theme.colors.white30}`,
              borderRadius: 12,
              fontFamily: theme.fonts.body,
              color: theme.colors.white,
              fontSize: 14,
            }}
            formatter={(value: number) => [value, "Requests"]}
            labelFormatter={(label: string) => {
              const item = data.find((d) => d.name === label);
              return item?.fullName || label;
            }}
          />
          <Bar
            dataKey="count"
            fill="rgba(255,255,255,0.4)"
            radius={[0, 6, 6, 0]}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
