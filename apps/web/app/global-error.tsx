"use client";

import { useEffect } from "react";

// global-error replaces the root layout, so it must render its own <html>/<body>
// and cannot depend on fonts/components defined upstream. Keep it self-contained.
export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <html lang="en">
      <body
        style={{
          margin: 0,
          minHeight: "100vh",
          display: "flex",
          flexDirection: "column",
          alignItems: "center",
          justifyContent: "center",
          textAlign: "center",
          padding: 24,
          gap: 16,
          background: "#08090B",
          color: "#F8FAFC",
          fontFamily: "system-ui, -apple-system, sans-serif",
        }}
      >
        <h1 style={{ fontSize: 32, fontWeight: 600, maxWidth: 520 }}>
          Something went wrong.
        </h1>
        <p
          style={{
            fontSize: 18,
            color: "rgba(255,255,255,0.62)",
            maxWidth: 480,
          }}
        >
          We hit an unexpected error and have logged it. Please try again.
        </p>
        {error.digest ? (
          <p style={{ fontSize: 12, color: "rgba(255,255,255,0.3)" }}>
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
            background: "linear-gradient(120deg, #3A8DDE, #0C6CC2)",
            color: "#fff",
            fontWeight: 600,
            fontSize: 18,
          }}
        >
          Try again
        </button>
      </body>
    </html>
  );
}
