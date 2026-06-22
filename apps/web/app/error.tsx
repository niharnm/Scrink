"use client";

import { useEffect } from "react";
import SkyBackground from "@/components/dashboard/SkyBackground";
import { theme } from "@/lib/theme";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // Surface the error to the browser console / monitoring without leaking it
    // into the rendered UI.
    console.error(error);
  }, [error]);

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
          Something went wrong
        </p>
        <h1
          style={{
            fontFamily: theme.fonts.display,
            fontSize: 36,
            fontWeight: 600,
            maxWidth: 520,
          }}
        >
          We hit an unexpected error.
        </h1>
        <p style={{ fontSize: 18, color: theme.colors.white60, maxWidth: 480 }}>
          The issue has been logged. You can try again, and if it keeps
          happening, reach us at hello@rinkler.app.
        </p>
        {error.digest ? (
          <p
            style={{
              fontFamily: theme.fonts.body,
              fontSize: 12,
              color: theme.colors.white30,
            }}
          >
            Reference: {error.digest}
          </p>
        ) : null}
        <button
          onClick={reset}
          style={{
            marginTop: 8,
            height: 52,
            padding: "0 32px",
            borderRadius: 26,
            border: "none",
            cursor: "pointer",
            background: `linear-gradient(120deg, ${theme.colors.skyBlue}, ${theme.colors.backArrow})`,
            color: "#fff",
            fontWeight: 600,
            fontSize: 18,
            fontFamily: theme.fonts.display,
          }}
        >
          Try again
        </button>
      </main>
    </SkyBackground>
  );
}
