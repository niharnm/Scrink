"use client";

import { useState, useCallback, useEffect, useRef, CSSProperties, ReactNode } from "react";
import { useRouter } from "next/navigation";
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
import {
  fetchDashboardData,
  DashboardData,
} from "@/lib/analytics";
import { createClient as createSupabaseClient } from "@/lib/supabase/client";
import { theme } from "@/lib/theme";

interface DashboardClientProps {
  email: string;
}

type Range = "today" | "7d" | "30d";
const adminToolsEnabled = process.env.NEXT_PUBLIC_ENABLE_DASHBOARD_ADMIN_TOOLS === "true";

export default function DashboardClient({ email }: DashboardClientProps) {
  const router = useRouter();
  const [range, setRange] = useState<Range>("today");
  const [data, setData] = useState<DashboardData | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const supabaseRef = useRef(createSupabaseClient());
  const loadRequestRef = useRef(0);

  const loadDashboard = useCallback(async (activeRange: Range) => {
    const requestID = loadRequestRef.current + 1;
    loadRequestRef.current = requestID;
    setIsLoading(true);
    setLoadError(null);
    try {
      const result = await fetchDashboardData(activeRange);
      if (requestID !== loadRequestRef.current) return;
      setData(result);
    } catch (error) {
      if (requestID !== loadRequestRef.current) return;
      setData(null);
      setLoadError(error instanceof Error ? error.message : "Could not load dashboard data.");
    } finally {
      if (requestID !== loadRequestRef.current) return;
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadDashboard(range);
  }, [loadDashboard, range]);

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
    if (!adminToolsEnabled) return;
    setRollupStatus("running...");
    try {
      const res = await fetch("/api/analytics/rollup", { method: "POST" });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setRollupStatus(json.error || "rollup failed");
        return;
      }
      const parts = Object.entries(json.results || {}).map(
        ([k, v]) => `${k}: ${v}`
      );
      setRollupStatus(parts.join(" | "));
      void loadDashboard(range);
    } catch {
      setRollupStatus("failed");
    }
    setTimeout(() => setRollupStatus(null), 5000);
  }, [loadDashboard, range]);

  const [classifyStatus, setClassifyStatus] = useState<string | null>(null);
  const handleClassify = useCallback(async () => {
    if (!adminToolsEnabled) return;
    setClassifyStatus("classifying...");
    try {
      const res = await fetch("/api/analytics/classify", { method: "POST" });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setClassifyStatus(json.error || "classification failed");
        return;
      }
      const count = Object.keys(json.classified || {}).length;
      setClassifyStatus(`${count} hosts classified, ${json.updated || 0} events updated`);
      void loadDashboard(range);
    } catch {
      setClassifyStatus("failed");
    }
    setTimeout(() => setClassifyStatus(null), 8000);
  }, [loadDashboard, range]);

  const contentStyle: CSSProperties = {
    maxWidth: 1240,
    margin: "0 auto",
    paddingTop: 0,
    paddingRight: theme.spacing.lg,
    paddingBottom: 160,
    paddingLeft: theme.spacing.lg,
  };

  const blocked = data?.totalBlocked ?? 0;
  const allowed = data?.totalAllowed ?? 0;
  const interceptRate = blocked + allowed > 0 ? blocked / (blocked + allowed) : 0;

  const heroBandStyle: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "minmax(260px, 340px) 1fr",
    gap: theme.spacing.md,
    marginBottom: theme.spacing.lg,
  };

  const heroCardStyle: CSSProperties = {
    display: "flex",
    alignItems: "center",
    gap: theme.spacing.lg,
    padding: theme.spacing.lg,
    background: theme.colors.white10,
    border: `1px solid ${theme.colors.white30}`,
    borderRadius: 22,
  };

  const kpiGridStyle: CSSProperties = {
    display: "grid",
    gridTemplateColumns: "repeat(auto-fit, minmax(150px, 1fr))",
    gap: theme.spacing.md,
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

  if (isLoading) {
    return (
      <SkyBackground>
        <HeaderBar email={email} onSignOut={handleSignOut} />
        <div style={{ ...contentStyle, textAlign: "center" as const, paddingTop: 120 }}>
          <div style={{ ...greetingStyle, marginBottom: theme.spacing.md }}>Loading...</div>
        </div>
      </SkyBackground>
    );
  }

  if (loadError || !data) {
    return (
      <SkyBackground>
        <HeaderBar email={email} onSignOut={handleSignOut} />
        <div style={{ ...contentStyle, textAlign: "center" as const, paddingTop: 100 }}>
          <div style={{ ...greetingStyle, marginBottom: theme.spacing.sm }}>Dashboard unavailable</div>
          <div style={{ ...subGreetingStyle, marginBottom: theme.spacing.lg }}>
            {loadError || "Could not load dashboard data."}
          </div>
          <button onClick={() => void loadDashboard(range)} style={adminButtonStyle(false)}>
            Retry
          </button>
        </div>
      </SkyBackground>
    );
  }

  return (
    <SkyBackground>
      <HeaderBar email={email} onSignOut={handleSignOut} />

      <div style={contentStyle}>
        <style>{`@media (max-width: 720px){ .dash-hero{ grid-template-columns: 1fr !important; } }`}</style>

        <div style={topRowStyle}>
          <div>
            <div style={greetingStyle}>Your Scroll Report</div>
            <div style={subGreetingStyle}>keep the useful parts.</div>
          </div>
          <DateRangeSelector value={range} onChange={setRange} />
        </div>

        {/* Hero band: intercept ring + key KPIs */}
        <div style={heroBandStyle} className="dash-hero">
          <div style={heroCardStyle}>
            <Ring percent={interceptRate} size={132} stroke={12}>
              <div style={{ textAlign: "center" }}>
                <div style={{ fontFamily: theme.fonts.mono, fontSize: 32, color: theme.colors.white, lineHeight: 1.05 }}>
                  {data.totalBlocked}
                </div>
                <div style={{ fontFamily: theme.fonts.body, fontSize: 11, color: theme.colors.white60, textTransform: "uppercase", letterSpacing: 1 }}>
                  blocked
                </div>
              </div>
            </Ring>
            <div>
              <div style={{ fontFamily: theme.fonts.display, fontSize: 20, color: theme.colors.white, marginBottom: 4, fontWeight: 600 }}>
                {Math.round(interceptRate * 100)}% intercepted
              </div>
              <div style={{ fontFamily: theme.fonts.body, fontSize: 13, color: theme.colors.white60, lineHeight: 1.5 }}>
                of tracked requests {range === "today" ? "today" : `in the last ${range}`}. {data.totalAllowed} let through.
              </div>
            </div>
          </div>

          <div style={kpiGridStyle}>
            <StatCard label="Time Saved" value={data.timeSaved} />
            <StatCard label="Peak Hours" value={data.peakHours} />
            <StatCard label="Most Active" value={data.mostActive} />
            <BandwidthCard
              totalBytesIn={data.totalBytesIn}
              totalBytesOut={data.totalBytesOut}
            />
          </div>
        </div>

        <div style={sectionGap}>
          <RinklerCluster apps={data.apps} onAppClick={handleAppClick} />
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

        {adminToolsEnabled && (
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
        )}

        <InsightCard text={data.insight} onGenerate={handleGenerateInsight} />
      </div>
    </SkyBackground>
  );
}

/** Signal-style progress ring (blue→violet) used for the hero intercept rate. */
function Ring({
  percent,
  size,
  stroke,
  children,
}: {
  percent: number;
  size: number;
  stroke: number;
  children?: ReactNode;
}) {
  const r = (size - stroke) / 2;
  const circ = 2 * Math.PI * r;
  const dash = Math.max(0.001, Math.min(1, percent)) * circ;
  return (
    <div style={{ position: "relative", width: size, height: size, flexShrink: 0 }}>
      <svg width={size} height={size}>
        <defs>
          <linearGradient id="ringGrad" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#5B7CFF" />
            <stop offset="100%" stopColor="#8B5CF6" />
          </linearGradient>
        </defs>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.10)" strokeWidth={stroke} />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={r}
          fill="none"
          stroke="url(#ringGrad)"
          strokeWidth={stroke}
          strokeLinecap="round"
          strokeDasharray={`${dash} ${circ}`}
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center" }}>
        {children}
      </div>
    </div>
  );
}
