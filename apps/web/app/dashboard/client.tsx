"use client";

import { useState, useCallback, useEffect, useRef, CSSProperties } from "react";
import { useRouter } from "next/navigation";
import { createBrowserClient } from "@supabase/ssr";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import DateRangeSelector from "@/components/dashboard/DateRangeSelector";
import BubbleCluster from "@/components/dashboard/BubbleCluster";
import StatCard from "@/components/dashboard/StatCard";
import UsageChart from "@/components/dashboard/UsageChart";
import HeatmapGrid from "@/components/dashboard/HeatmapGrid";
import InsightCard from "@/components/dashboard/InsightCard";
import TopDomainsTable from "@/components/dashboard/TopDomainsTable";
import BandwidthCard from "@/components/dashboard/BandwidthCard";
import MethodBreakdown from "@/components/dashboard/MethodBreakdown";
import ContentTypeChart from "@/components/dashboard/ContentTypeChart";
import {
  fetchDashboardData,
  DashboardData,
} from "@/lib/analytics";
import { theme } from "@/lib/theme";

interface DashboardClientProps {
  email: string;
}

type Range = "today" | "7d" | "30d";

export default function DashboardClient({ email }: DashboardClientProps) {
  const router = useRouter();
  const [range, setRange] = useState<Range>("today");
  const [data, setData] = useState<DashboardData | null>(null);

  const supabaseRef = useRef(
    createBrowserClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY!
    )
  );

  useEffect(() => {
    let cancelled = false;
    fetchDashboardData(range).then((result) => {
      if (!cancelled) setData(result);
    });
    return () => {
      cancelled = true;
    };
  }, [range]);

  const handleSignOut = useCallback(async () => {
    await supabaseRef.current.auth.signOut();
    router.push("/login");
  }, [router]);

  const handleAppClick = useCallback(
    (slug: string) => {
      router.push(`/dashboard/${slug}`);
    },
    [router]
  );

  const handleGenerateInsight = useCallback(async (): Promise<string | null> => {
    try {
      const res = await fetch("/api/analytics/generate-insight", {
        method: "POST",
      });
      if (!res.ok) return null;
      const json = await res.json();
      return json.insight?.content || null;
    } catch {
      return null;
    }
  }, []);

  const [rollupStatus, setRollupStatus] = useState<string | null>(null);
  const handleRollup = useCallback(async () => {
    setRollupStatus("running...");
    try {
      const res = await fetch("/api/analytics/rollup", { method: "POST" });
      const json = await res.json();
      const parts = Object.entries(json.results || {}).map(
        ([k, v]) => `${k}: ${v}`
      );
      setRollupStatus(parts.join(" | "));
      fetchDashboardData(range).then(setData);
    } catch {
      setRollupStatus("failed");
    }
    setTimeout(() => setRollupStatus(null), 5000);
  }, [range]);

  const [classifyStatus, setClassifyStatus] = useState<string | null>(null);
  const handleClassify = useCallback(async () => {
    setClassifyStatus("classifying...");
    try {
      const res = await fetch("/api/analytics/classify", { method: "POST" });
      const json = await res.json();
      const count = Object.keys(json.classified || {}).length;
      setClassifyStatus(`${count} hosts classified, ${json.updated || 0} events updated`);
      fetchDashboardData(range).then(setData);
    } catch {
      setClassifyStatus("failed");
    }
    setTimeout(() => setClassifyStatus(null), 8000);
  }, [range]);

  const contentStyle: CSSProperties = {
    maxWidth: 960,
    margin: "0 auto",
    paddingTop: 0,
    paddingRight: theme.spacing.lg,
    paddingBottom: 200,
    paddingLeft: theme.spacing.lg,
  };

  const greetingStyle: CSSProperties = {
    fontFamily: theme.fonts.display,
    fontSize: 28,
    color: theme.colors.white,
    marginBottom: theme.spacing.xs,
  };

  const subGreetingStyle: CSSProperties = {
    fontFamily: theme.fonts.body,
    fontSize: theme.fontSizes.body,
    color: theme.colors.white60,
    fontStyle: "italic",
    marginBottom: theme.spacing.lg,
  };

  const topRowStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    flexWrap: "wrap",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.xl,
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

  const twoColStyle: CSSProperties = {
    display: "flex",
    gap: theme.spacing.md,
    flexWrap: "wrap",
    marginBottom: theme.spacing.xl,
  };

  const adminButtonStyle = (disabled: boolean): CSSProperties => ({
    fontFamily: theme.fonts.body,
    fontSize: 13,
    color: disabled ? theme.colors.white30 : theme.colors.white,
    background: theme.colors.white10,
    border: `1px solid ${theme.colors.white30}`,
    borderRadius: 12,
    padding: "8px 16px",
    cursor: disabled ? "default" : "pointer",
  });

  if (!data) {
    return (
      <SkyBackground>
        <HeaderBar email={email} onSignOut={handleSignOut} />
        <div style={{ ...contentStyle, textAlign: "center" as const, paddingTop: 120 }}>
          <div style={{ ...greetingStyle, marginBottom: theme.spacing.md }}>Loading...</div>
        </div>
      </SkyBackground>
    );
  }

  return (
    <SkyBackground>
      <HeaderBar email={email} onSignOut={handleSignOut} />

      <div style={contentStyle}>
        <div style={topRowStyle}>
          <div>
            <div style={greetingStyle}>Your Bubble</div>
            <div style={subGreetingStyle}>into the clouds.</div>
          </div>
          <DateRangeSelector value={range} onChange={setRange} />
        </div>

        <div style={sectionGap}>
          <BubbleCluster apps={data.apps} onAppClick={handleAppClick} />
        </div>

        <div style={statsGridStyle}>
          <StatCard
            label="Blocked"
            value={String(data.totalBlocked)}
            subtitle={`${range === "today" ? "today" : `last ${range}`}`}
          />
          <StatCard label="Time Saved" value={data.timeSaved} />
          <StatCard label="Peak Hours" value={data.peakHours} />
          <StatCard label="Most Active" value={data.mostActive} />
          <BandwidthCard
            totalBytesIn={data.totalBytesIn}
            totalBytesOut={data.totalBytesOut}
          />
        </div>

        <div style={sectionGap}>
          <UsageChart
            data={data.usageOverTime}
            title={range === "today" ? "Hourly Usage" : "Daily Usage"}
          />
        </div>

        <div style={sectionGap}>
          <TopDomainsTable domains={data.topDomains} />
        </div>

        <div style={twoColStyle}>
          <MethodBreakdown methods={data.methods} />
          <ContentTypeChart contentTypes={data.contentTypes} />
        </div>

        <div style={sectionGap}>
          <HeatmapGrid data={data.heatmap} />
        </div>

        <div style={{ ...sectionGap, display: "flex", alignItems: "center", gap: theme.spacing.md, flexWrap: "wrap" }}>
          <button
            onClick={handleRollup}
            disabled={rollupStatus === "running..."}
            style={adminButtonStyle(rollupStatus === "running...")}
          >
            {rollupStatus === "running..." ? "Rolling up..." : "Rollup Traffic"}
          </button>
          <button
            onClick={handleClassify}
            disabled={classifyStatus === "classifying..."}
            style={adminButtonStyle(classifyStatus === "classifying...")}
          >
            {classifyStatus === "classifying..." ? "Classifying..." : "Classify Domains"}
          </button>
          {rollupStatus && rollupStatus !== "running..." && (
            <span style={{ fontFamily: theme.fonts.body, fontSize: 12, color: theme.colors.white60 }}>
              {rollupStatus}
            </span>
          )}
          {classifyStatus && classifyStatus !== "classifying..." && (
            <span style={{ fontFamily: theme.fonts.body, fontSize: 12, color: theme.colors.white60 }}>
              {classifyStatus}
            </span>
          )}
        </div>

        <InsightCard text={data.insight} onGenerate={handleGenerateInsight} />
      </div>
    </SkyBackground>
  );
}
