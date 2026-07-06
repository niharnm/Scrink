"use client";

import { useEffect, useState, CSSProperties } from "react";
import { signal } from "@/lib/signal";

// App release target.
const TARGET = new Date("2026-08-10T00:00:00").getTime();

export default function Countdown() {
  const [diff, setDiff] = useState<number | null>(null);

  useEffect(() => {
    const tick = () => setDiff(Math.max(0, TARGET - Date.now()));
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, []);

  const d = diff == null ? null : Math.floor(diff / 86400000);
  const h = diff == null ? null : Math.floor(diff / 3600000) % 24;
  const m = diff == null ? null : Math.floor(diff / 60000) % 60;
  const s = diff == null ? null : Math.floor(diff / 1000) % 60;

  return (
    <div style={wrap}>
      <div style={row}>
        <Seg n={d} label="days" />
        <Colon />
        <Seg n={h} label="hrs" />
        <Colon />
        <Seg n={m} label="min" />
        <Colon />
        <Seg n={s} label="sec" />
      </div>
    </div>
  );
}

function Seg({ n, label }: { n: number | null; label: string }) {
  return (
    <div style={seg}>
      <div style={num}>{n == null ? "--" : String(n).padStart(2, "0")}</div>
      <div style={lbl}>{label}</div>
    </div>
  );
}

function Colon() {
  return <div style={{ ...num, color: signal.textFaint, alignSelf: "flex-start", paddingTop: 2 }}>:</div>;
}

const wrap: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center" };
const row: CSSProperties = { display: "flex", alignItems: "flex-start", gap: "clamp(8px, 2vw, 18px)" };
const seg: CSSProperties = { display: "flex", flexDirection: "column", alignItems: "center", minWidth: "clamp(48px, 9vw, 80px)" };
const num: CSSProperties = {
  fontFamily: signal.mono,
  fontSize: "clamp(34px, 7vw, 64px)",
  fontWeight: 500,
  color: signal.text,
  lineHeight: 1,
  letterSpacing: "-0.02em",
  fontVariantNumeric: "tabular-nums",
};
const lbl: CSSProperties = {
  fontFamily: signal.mono,
  fontSize: 11,
  letterSpacing: "0.14em",
  textTransform: "uppercase",
  color: signal.textFaint,
  marginTop: 10,
};
