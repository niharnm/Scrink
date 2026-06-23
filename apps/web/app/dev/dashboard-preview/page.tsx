"use client";

import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import DashboardView from "@/components/dashboard/DashboardView";
import DashboardViewV2 from "@/components/dashboard/DashboardViewV2";
import WaitlistDashboard from "@/components/dashboard/WaitlistDashboard";
import { EMPTY_DASHBOARD } from "@/lib/analytics";
import { MOCK_DASHBOARD } from "@/lib/mock-dashboard";
import { MOCK_WELLBEING } from "@/lib/dashboard-v2";

/**
 * Dev-only visual preview of the dashboard with mock data, so the auth-gated
 * UI can be screenshotted/iterated without a session. Renders nothing in
 * production. Visit /dev/dashboard-preview or /dev/dashboard-preview?empty=1.
 */
export default function DashboardPreviewPage() {
  if (process.env.NODE_ENV === "production") return null;
  return (
    <Suspense fallback={null}>
      <Preview />
    </Suspense>
  );
}

function Preview() {
  const params = useSearchParams();
  const empty = params.get("empty") === "1";
  if (params.get("waitlist") === "1") return <WaitlistDashboard email="you@example.com" />;
  if (params.get("v") === "2") {
    return <DashboardViewV2 data={MOCK_WELLBEING} email="you@example.com" onSignOut={() => {}} />;
  }
  return (
    <DashboardView
      data={empty ? EMPTY_DASHBOARD : MOCK_DASHBOARD}
      range="today"
      onRangeChange={() => {}}
      email="you@example.com"
      onSignOut={() => {}}
      onAppClick={() => {}}
      onGenerateInsight={async () => null}
    />
  );
}
