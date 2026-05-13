"use client";

import { CSSProperties } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";
import { theme } from "@/lib/theme";

interface UsageDataPoint {
  label: string;
  allowed: number;
  blocked: number;
}

interface UsageChartProps {
  data: UsageDataPoint[];
  title?: string;
}

export default function UsageChart({
  data,
  title = "Usage Over Time",
}: UsageChartProps) {
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

  return (
    <div style={cardStyle}>
      <div style={titleStyle}>{title}</div>
      <ResponsiveContainer width="100%" height={280}>
        <AreaChart data={data} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
          <defs>
            <linearGradient id="gradAllowed" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor={theme.colors.white} stopOpacity={0.4} />
              <stop offset="95%" stopColor={theme.colors.white} stopOpacity={0.05} />
            </linearGradient>
            <linearGradient id="gradBlocked" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#FF6B6B" stopOpacity={0.4} />
              <stop offset="95%" stopColor="#FF6B6B" stopOpacity={0.05} />
            </linearGradient>
          </defs>
          <CartesianGrid
            strokeDasharray="3 3"
            stroke="rgba(255,255,255,0.1)"
            vertical={false}
          />
          <XAxis
            dataKey="label"
            tick={{ fill: "rgba(255,255,255,0.6)", fontFamily: theme.fonts.body, fontSize: 12 }}
            axisLine={{ stroke: "rgba(255,255,255,0.2)" }}
            tickLine={false}
          />
          <YAxis
            tick={{ fill: "rgba(255,255,255,0.6)", fontFamily: theme.fonts.body, fontSize: 12 }}
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
            labelStyle={{ color: theme.colors.white, fontFamily: theme.fonts.body }}
          />
          <Legend
            wrapperStyle={{
              fontFamily: theme.fonts.body,
              fontSize: 13,
              color: theme.colors.white,
            }}
          />
          <Area
            type="monotone"
            dataKey="allowed"
            stroke={theme.colors.white}
            strokeWidth={2}
            fill="url(#gradAllowed)"
            name="Allowed"
          />
          <Area
            type="monotone"
            dataKey="blocked"
            stroke="#FF6B6B"
            strokeWidth={2}
            fill="url(#gradBlocked)"
            name="Blocked"
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
