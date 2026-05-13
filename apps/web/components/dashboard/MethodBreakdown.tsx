"use client";

import { CSSProperties } from "react";
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from "recharts";
import { theme } from "@/lib/theme";
import { MethodEntry } from "@/lib/analytics";

interface MethodBreakdownProps {
  methods: MethodEntry[];
}

const COLORS = [
  "rgba(255,255,255,0.8)",
  "rgba(255,255,255,0.5)",
  "rgba(255,255,255,0.3)",
  "rgba(255,255,255,0.18)",
  "rgba(255,255,255,0.1)",
];

export default function MethodBreakdown({ methods }: MethodBreakdownProps) {
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

  if (methods.length === 0) {
    return (
      <div style={cardStyle}>
        <div style={titleStyle}>HTTP Methods</div>
        <div style={{ fontFamily: theme.fonts.body, fontSize: theme.fontSizes.small, color: theme.colors.white60 }}>
          No method data yet.
        </div>
      </div>
    );
  }

  const data = methods.map((m) => ({ name: m.method, value: m.count }));

  return (
    <div style={cardStyle}>
      <div style={titleStyle}>HTTP Methods</div>
      <ResponsiveContainer width="100%" height={220}>
        <PieChart>
          <Pie
            data={data}
            dataKey="value"
            nameKey="name"
            cx="50%"
            cy="50%"
            outerRadius={80}
            strokeWidth={0}
          >
            {data.map((_, i) => (
              <Cell key={i} fill={COLORS[i % COLORS.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              background: "rgba(26,95,170,0.95)",
              border: `1px solid ${theme.colors.white30}`,
              borderRadius: 12,
              fontFamily: theme.fonts.body,
              color: theme.colors.white,
              fontSize: 14,
            }}
          />
          <Legend
            wrapperStyle={{
              fontFamily: theme.fonts.body,
              fontSize: 12,
              color: theme.colors.white,
            }}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
