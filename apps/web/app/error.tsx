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
            fontFamily: theme.fonts.mono,
            fontSize: 12,
            letterSpacing: "0.16em",
            textTransform: "uppercase",
            color: theme.colors.white60,
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
        <p style={{ fontSize: 17, color: theme.colors.white60, maxWidth: 480, lineHeight: 1.55 }}>
          The issue has been logged. You can try again, and if it keeps
          happening, reach us at nihar.manchikalapudi@gmail.com.
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
            height: 46,
            padding: "0 26px",
            borderRadius: 10,
            border: "none",
            cursor: "pointer",
            background: theme.colors.white,
            color: "#08080A",
            fontWeight: 600,
            fontSize: 15,
            fontFamily: theme.fonts.body,
          }}
        >
          Try again
        </button>
      </main>
    </SkyBackground>
  );
}
