import Link from "next/link";
import SkyBackground from "@/components/dashboard/SkyBackground";
import { theme } from "@/lib/theme";

export default function NotFound() {
  return (
    <SkyBackground>
      <main
        style={{
          minHeight: "100vh",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          textAlign: "center",
          padding: "24px",
          gap: "16px",
        }}
      >
        <p
          style={{
            fontFamily: theme.fonts.body,
            fontSize: 14,
            letterSpacing: 2,
            textTransform: "uppercase",
            color: theme.colors.skyBlue,
          }}
        >
          404
        </p>
        <h1
          style={{
            fontFamily: theme.fonts.display,
            fontSize: 36,
            fontWeight: 600,
            maxWidth: 520,
          }}
        >
          This page drifted off the map.
        </h1>
        <p style={{ fontSize: 18, color: theme.colors.white60, maxWidth: 480 }}>
          The page you’re looking for doesn’t exist or has moved.
        </p>
        <Link
          href="/"
          style={{
            marginTop: 8,
            display: "inline-flex",
            alignItems: "center",
            justifyContent: "center",
            height: 52,
            padding: "0 32px",
            borderRadius: 26,
            background: `linear-gradient(120deg, ${theme.colors.skyBlue}, ${theme.colors.backArrow})`,
            color: "#fff",
            fontWeight: 600,
            fontSize: 18,
            textDecoration: "none",
          }}
        >
          Back to home
        </Link>
      </main>
    </SkyBackground>
  );
}
