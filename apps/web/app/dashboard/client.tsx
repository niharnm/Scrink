"use client";

import { useState, useCallback, useEffect, useRef, CSSProperties } from "react";
import { useRouter } from "next/navigation";
import SkyBackground from "@/components/dashboard/SkyBackground";
import HeaderBar from "@/components/dashboard/HeaderBar";
import DashboardView from "@/components/dashboard/DashboardView";
import { fetchDashboardData, DashboardData } from "@/lib/analytics";
import { createClient as createSupabaseClient } from "@/lib/supabase/client";
import { theme } from "@/lib/theme";

interface DashboardClientProps {
  email: string;
}

type Range = "today" | "7d" | "30d";

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

  const handleAppClick = useCallback((slug: string) => router.push(`/dashboard/${slug}`), [router]);

  const handleGenerateInsight = useCallback(async (): Promise<string | null> => {
    try {
      const res = await fetch("/api/analytics/generate-insight", { method: "POST" });
      if (!res.ok) return null;
      const json = await res.json();
      return json.insight?.content || null;
    } catch {
      return null;
    }
  }, []);

  const centered: CSSProperties = {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "60vh",
    gap: 14,
    fontFamily: theme.fonts.body,
  };

  if (isLoading && !data) {
    return (
      <SkyBackground>
        <HeaderBar email={email} onSignOut={handleSignOut} />
        <div style={centered}>
          <Spinner />
          <div style={{ color: theme.colors.white60, fontSize: 14 }}>Loading your report…</div>
        </div>
      </SkyBackground>
    );
  }

  if (loadError || !data) {
    return (
      <SkyBackground>
        <HeaderBar email={email} onSignOut={handleSignOut} />
        <div style={centered}>
          <div style={{ color: theme.colors.white, fontFamily: theme.fonts.display, fontSize: 22, fontWeight: 600 }}>
            Dashboard unavailable
          </div>
          <div style={{ color: theme.colors.white60, fontSize: 14, maxWidth: 420, textAlign: "center" }}>
            {loadError || "Could not load dashboard data."}
          </div>
          <button
            onClick={() => void loadDashboard(range)}
            style={{
              marginTop: 6,
              padding: "10px 22px",
              borderRadius: 12,
              border: "1px solid rgba(255,255,255,0.14)",
              background: "rgba(255,255,255,0.05)",
              color: theme.colors.white,
              fontFamily: theme.fonts.body,
              fontSize: 14,
              cursor: "pointer",
            }}
          >
            Retry
          </button>
        </div>
      </SkyBackground>
    );
  }

  return (
    <DashboardView
      data={data}
      range={range}
      onRangeChange={setRange}
      email={email}
      onSignOut={handleSignOut}
      onAppClick={handleAppClick}
      onGenerateInsight={handleGenerateInsight}
    />
  );
}

function Spinner() {
  return (
    <>
      <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
      <div
        style={{
          width: 30,
          height: 30,
          borderRadius: "50%",
          border: "3px solid rgba(255,255,255,0.12)",
          borderTopColor: "#5B7CFF",
          animation: "spin 0.8s linear infinite",
        }}
      />
    </>
  );
}
