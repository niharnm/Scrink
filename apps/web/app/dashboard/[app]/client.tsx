"use client";

import { CSSProperties, useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import StatCard from "@/components/dashboard/StatCard";
import UsageChart from "@/components/dashboard/UsageChart";
import { fetchAppDetail, AppDetailData } from "@/lib/analytics";
import { theme } from "@/lib/theme";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
  Legend,
} from "recharts";

interface AppDetailClientProps {
  slug: string;
}

export default function AppDetailClient({ slug }: AppDetailClientProps) {
  const router = useRouter();
  const [detail, setDetail] = useState<AppDetailData | null>(null);

  useEffect(() => {
    let cancelled = false;
    fetchAppDetail(slug).then((result) => {
      if (!cancelled) setDetail(result);
    });
    return () => {
      cancelled = true;
    };
  }, [slug]);

  if (!detail) {
    return (
      <SkyBackground>
        <HeaderBar />
        <div
          style={{
            textAlign: "center",
            marginTop: 120,
            fontFamily: theme.fonts.display,
            fontSize: theme.fontSizes.titleMedium,
            color: theme.colors.white,
          }}
        >
          App not found
        </div>
      </SkyBackground>
    );
  }

  const contentStyle: CSSProperties = {
    maxWidth: 960,
    margin: "0 auto",
    padding: `0 ${theme.spacing.lg}px 200px`,
  };

  const backStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.body,
    color: theme.colors.white60,
    background: "none",
    border: "none",
    cursor: "pointer",
    marginBottom: theme.spacing.lg,
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.sm,
  };

  const titleRowStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.xl,
  };

  const iconWrapperStyle: CSSProperties = {
    width: theme.iconSizes.appLarge,
    height: theme.iconSizes.appLarge,
    borderRadius: "50%",
    background: theme.colors.white,
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
  };

  const iconStyle: CSSProperties = {
    width: theme.iconSizes.appLarge * 0.7,
    height: theme.iconSizes.appLarge * 0.7,
    objectFit: "contain",
  };

  const titleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 28,
    color: theme.colors.white,
  };

  const statsGridStyle: CSSProperties = {
    display: "flex",
    gap: theme.spacing.md,
    flexWrap: "wrap",
    marginBottom: theme.spacing.xl,
  };

  const sectionGap: CSSProperties = {
    marginBottom: theme.spacing.xl,
  };

  const cardStyle: CSSProperties = {
    background: theme.colors.white10,
    borderRadius: 20,
    padding: theme.spacing.lg,
    border: `1px solid ${theme.colors.white30}`,
  };

  const sectionTitleStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 20,
    color: theme.colors.white,
    marginBottom: theme.spacing.md,
  };

  const pieData = [
    { name: "Blocked", value: detail.blockedPercent },
    { name: "Allowed", value: 100 - detail.blockedPercent },
  ];

  const PIE_COLORS = ["#FF6B6B", theme.colors.white];

  const contentTypeBarStyle = (): CSSProperties => ({
    height: 8,
    borderRadius: 4,
    background: theme.colors.white30,
    width: "100%",
    position: "relative",
    overflow: "hidden",
  });

  const contentTypeFillStyle = (count: number, max: number): CSSProperties => ({
    position: "absolute",
    left: 0,
    top: 0,
    height: "100%",
    borderRadius: 4,
    background: theme.colors.white,
    width: `${(count / max) * 100}%`,
    transition: "width 0.5s ease",
  });

  const maxContentCount = Math.max(...detail.contentTypes.map((c) => c.count));

  return (
    <SkyBackground>
      <HeaderBar />

      <div style={contentStyle}>
        <button style={backStyle} onClick={() => router.push("/dashboard")}>
          <svg width="20" height="14" viewBox="0 0 34 22" fill="white" opacity={0.6}>
            <path d="M11 1L1 11L11 21M1 11H33" stroke="white" strokeOpacity="0.6" strokeWidth="2" fill="none" />
          </svg>
          Back to Dashboard
        </button>

        <div style={titleRowStyle}>
          <div style={iconWrapperStyle}>
            {detail.icon.startsWith("/") ? (
              <img src={detail.icon} alt={detail.name} style={iconStyle} />
            ) : (
              <span
                style={{
                  fontSize: theme.iconSizes.appLarge * 0.35,
                  color: theme.colors.skyBlue,
                  fontWeight: "bold",
                }}
              >
                {detail.icon}
              </span>
            )}
          </div>
          <div style={titleStyle}>{detail.name}</div>
        </div>

        <div style={statsGridStyle}>
          <StatCard
            label="Total Requests"
            value={String(detail.totalRequests)}
            subtitle="today"
          />
          <StatCard
            label="Blocked"
            value={`${detail.blockedPercent}%`}
            subtitle="of all requests"
          />
        </div>

        {/* Blocked vs Allowed Pie */}
        <div style={{ ...cardStyle, ...sectionGap }}>
          <div style={sectionTitleStyle}>Blocked vs Allowed</div>
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                dataKey="value"
                strokeWidth={0}
              >
                {pieData.map((_, i) => (
                  <Cell key={i} fill={PIE_COLORS[i]} />
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
                  fontSize: 13,
                  color: theme.colors.white,
                }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Hourly usage */}
        <div style={sectionGap}>
          <UsageChart data={detail.hourlyUsage} title="Today — Hourly" />
        </div>

        {/* Content type breakdown */}
        <div style={{ ...cardStyle, ...sectionGap }}>
          <div style={sectionTitleStyle}>Content Types</div>
          <div style={{ display: "flex", flexDirection: "column", gap: theme.spacing.md }}>
            {detail.contentTypes.map((ct) => (
              <div key={ct.type}>
                <div
                  style={{
                    display: "flex",
                    justifyContent: "space-between",
                    marginBottom: theme.spacing.xs,
                    fontFamily: theme.fonts.body,
                    fontSize: theme.fontSizes.small,
                    color: theme.colors.white,
                  }}
                >
                  <span>{ct.type}</span>
                  <span style={{ color: theme.colors.white60 }}>{ct.count}</span>
                </div>
                <div style={contentTypeBarStyle()}>
                  <div style={contentTypeFillStyle(ct.count, maxContentCount)} />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* 30-day trend */}
        <UsageChart data={detail.dailyTrend} title="30-Day Trend" />
      </div>
    </SkyBackground>
  );
}
