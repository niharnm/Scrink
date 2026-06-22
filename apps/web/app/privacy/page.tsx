import type { Metadata } from "next";
import SkyBackground from "@/components/dashboard/SkyBackground";
import LegalShell from "@/components/marketing/LegalShell";

export const metadata: Metadata = {
  title: "Privacy Policy — Rinkler",
  description: "How Rinkler handles your data. Short version: filtering runs on your device and never reads your content.",
};

export default function PrivacyPage() {
  return (
    <SkyBackground>
      <LegalShell title="Privacy Policy" updated="June 2026">
        <p>
          Rinkler is built to reduce what looks at you, not to look at you. The
          short version: filtering happens on your device, and Rinkler never
          decrypts your traffic or reads your messages, photos, or page contents.
        </p>

        <h2>What stays on your device</h2>
        <p>
          The packet-tunnel filter inspects only network metadata — the
          destination host/SNI and byte sizes — to decide whether a stream is a
          heavy short-video feed. It does not read or store the contents of your
          traffic. Your focus-session history and settings are stored locally in
          the app.
        </p>

        <h2>What we store if you sign in</h2>
        <p>
          Signing in is optional and only enables the web dashboard. Authentication
          uses email one-time codes via Supabase. If you sign in, Rinkler uploads
          coarse traffic summaries — destination hostnames, blocked/allowed status,
          byte counts, and timestamps — so the dashboard can show you trends. We do
          not upload packet contents, request bodies, screenshots, or message text.
        </p>

        <h2>What we never do</h2>
        <ul>
          <li>We do not sell your data.</li>
          <li>We do not decrypt your HTTPS traffic.</li>
          <li>We do not send your data to third-party AI providers unless you explicitly opt in.</li>
        </ul>

        <h2>Your control</h2>
        <p>
          You can turn filtering off at any time from iOS Settings, and you can
          request deletion of your account and synced summaries by contacting us.
        </p>

        <h2>Contact</h2>
        <p>Questions about privacy? Email hello@rinkler.app.</p>
      </LegalShell>
    </SkyBackground>
  );
}
