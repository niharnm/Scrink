import type { Metadata } from "next";
import SkyBackground from "@/components/dashboard/SkyBackground";
import LegalShell from "@/components/marketing/LegalShell";

export const metadata: Metadata = {
  title: "Terms of Service — Rinkler",
  description: "The terms for using Rinkler.",
};

export default function TermsPage() {
  return (
    <SkyBackground>
      <LegalShell title="Terms of Service" updated="June 2026">
        <p>
          By using Rinkler you agree to these terms. Rinkler is a tool to help you
          reduce time spent in short-video feeds; it is provided as-is.
        </p>

        <h2>What Rinkler does</h2>
        <p>
          Rinkler runs a local network filter that interrupts heavy short-video
          streams from the apps you choose. It is a productivity aid, not a security
          product, and it does not guarantee that every feed on every app will be
          blocked.
        </p>

        <h2>Acceptable use</h2>
        <ul>
          <li>Use Rinkler on devices and accounts you control.</li>
          <li>Do not attempt to disrupt the service or other users.</li>
        </ul>

        <h2>No warranty</h2>
        <p>
          Rinkler is provided without warranties of any kind. We are not liable for
          missed notifications, content, or any indirect damages arising from using
          or being unable to use the app.
        </p>

        <h2>Changes</h2>
        <p>
          We may update these terms; continued use after an update means you accept
          the revised terms.
        </p>

        <h2>Contact</h2>
        <p>Questions? Email hello@rinkler.app.</p>
      </LegalShell>
    </SkyBackground>
  );
}
