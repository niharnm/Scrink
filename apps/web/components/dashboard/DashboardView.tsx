"use client";

import { CSSProperties } from "react";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import DateRangeSelector from "@/components/dashboard/DateRangeSelector";
import RinklerCluster from "@/components/dashboard/RinklerCluster";
import StatCard from "@/components/dashboard/StatCard";
import UsageChart from "@/components/dashboard/UsageChart";
import HeatmapGrid from "@/components/dashboard/HeatmapGrid";
import InsightCard from "@/components/dashboard/InsightCard";
import TopDomainsTable from "@/components/dashboard/TopDomainsTable";
import BandwidthCard from "@/components/dashboard/BandwidthCard";
import MethodBreakdown from "@/components/dashboard/MethodBreakdown";
import ContentTypeChart from "@/components/dashboard/ContentTypeChart";
import EmptyState from "@/components/dashboard/EmptyState";
import Ring from "@/components/dashboard/Ring";
import { theme } from "@/lib/theme";
import { DashboardData } from "@/lib/analytics";

type Range = "today" | "7d" | "30d";

interface DashboardViewProps {
  data: DashboardData;
  range: Range;
  onRangeChange: (r: Range) => void;
  email?: string;
  onSignOut?: () => void;
  onAppClick?: (slug: string) => void;
  onGenerateInsight?: () => Promise<string | null>;
}

export default function DashboardView({
  data,
  range,
  onRangeChange,
  email,
  onSignOut,
  onAppClick,
  onGenerateInsight,
}: DashboardViewProps) {
  const blocked = data.totalBlocked ?? 0;
  const allowed = data.totalAllowed ?? 0;
  const total = blocked + allowed;
  const interceptRate = total > 0 ? blocked / total : 0;
  const hasData = total > 0 || (data.topDomains?.length ?? 0) > 0 || (data.apps?.length ?? 0) > 0;
  const rangeLabel = range === "today" ? "today" : `in the last ${range === "7d" ? "7 days" : "30 days"}`;

  const content: CSSProperties = {
    maxWidth: 1200,
    margin: "0 auto",
    padding: `4px ${theme.spacing.lg}px 140px`,
  };

  const topRow: CSSProperties = {
    display: "flex",
    alignItems: "flex-end",
    justifyContent: "space-between",
    flexWrap: "wrap",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.lg,
  };

  const greeting: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 30,
    fontWeight: 700,
    letterSpacing: "-0.02em",
    color: theme.colors.white,
  };

  const subGreeting: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: 15,
    color: theme.colors.white60,
    marginTop: 4,
  };

  const heroBand: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "minmax(280px, 360px) 1fr",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.md,
  };

  const heroCard: CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.lg,
    padding: theme.spacing.lg,
    background: "linear-gradient(180deg, rgba(91,124,255,0.10), rgba(255,255,255,0.015))",
    border: "1px solid rgba(91,124,255,0.28)",
    borderRadius: 22,
    boxShadow: "inset 0 1px 0 rgba(255,255,255,0.06), 0 10px 34px rgba(0,0,0,0.3)",
  };

  const kpiGrid: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
    gap: theme.spacing.md,
  };

  const sectionGap: CSSProperties = { marginBottom: theme.spacing.md };

  const analyticsGrid: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "1.15fr 1fr",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.md,
    alignItems: "start",
  };

  const rightCol: CSSProperties = { display: "flex", flexDirection: "column", gap: theme.spacing.md };

  return (
    <SkyBackground>
      <style>{`
        @media (max-width: 820px) {
          .dash-hero { grid-template-columns: 1fr !important; }
          .dash-2col { grid-template-columns: 1fr !important; }
        }
      `}</style>
      <HeaderBar email={email} onSignOut={onSignOut} />

      <div style={content}>
        <div style={topRow}>
          <div>
            <div style={greeting}>Your Scroll Report</div>
            <div style={subGreeting}>What Rinkler cut from your feed {rangeLabel}.</div>
          </div>
          <DateRangeSelector value={range} onChange={onRangeChange} />
        </div>

        {!hasData ? (
          <EmptyState />
        ) : (
          <>
            <div style={heroBand} className="dash-hero">
              <div style={heroCard}>
                <Ring percent={interceptRate} size={138} stroke={13} gradId="heroRing">
                  <div style={{ textAlign: "center" }}>
                    <div style={{ fontFamily: theme.fonts.mono, fontSize: 34, color: theme.colors.white, lineHeight: 1.0 }}>
                      {blocked.toLocaleString()}
                    </div>
                    <div style={{ fontFamily: theme.fonts.body, fontSize: 11, fontWeight: 600, color: theme.colors.white60, textTransform: "uppercase", letterSpacing: 1.2, marginTop: 2 }}>
                      blocked
                    </div>
                  </div>
                </Ring>
                <div>
                  <div style={{ fontFamily: theme.fonts.display, fontSize: 22, fontWeight: 700, color: theme.colors.white, letterSpacing: "-0.01em" }}>
                    {Math.round(interceptRate * 100)}% intercepted
                  </div>
                  <div style={{ fontFamily: theme.fonts.body, fontSize: 13.5, color: theme.colors.white60, lineHeight: 1.55, marginTop: 6 }}>
                    of tracked requests {rangeLabel}. {allowed.toLocaleString()} useful ones let through.
                  </div>
                </div>
              </div>

              <div style={kpiGrid}>
                <StatCard label="Time Saved" value={data.timeSaved} accent />
                <StatCard label="Peak Hours" value={data.peakHours} />
                <StatCard label="Most Active" value={data.mostActive} />
                <BandwidthCard totalBytesIn={data.totalBytesIn} totalBytesOut={data.totalBytesOut} />
              </div>
            </div>

            {data.apps?.length > 0 && (
              <div style={sectionGap}>
                <RinklerCluster apps={data.apps} onAppClick={onAppClick} />
              </div>
            )}

            <div style={sectionGap}>
              <UsageChart data={data.usageOverTime} title={range === "today" ? "Hourly Activity" : "Daily Activity"} />
            </div>

            <div style={analyticsGrid} className="dash-2col">
              <TopDomainsTable domains={data.topDomains} />
              <div style={rightCol}>
                <MethodBreakdown methods={data.methods} />
                <ContentTypeChart contentTypes={data.contentTypes} />
              </div>
            </div>

            <div style={sectionGap}>
              <HeatmapGrid data={data.heatmap} />
            </div>

            <InsightCard text={data.insight} onGenerate={onGenerateInsight} />
          </>
        )}
      </div>
    </SkyBackground>
  );
}
