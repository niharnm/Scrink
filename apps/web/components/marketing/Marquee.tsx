import type { CSSProperties } from "react";
import { signal } from "@/lib/signal";

/**
 * Full-bleed infinite scrolling text wall — the "endless scroll", literally.
 * Two rows moving opposite directions, pure CSS, seamless loop. Pauses for
 * reduced-motion.
 */
const ROW1 = ["reels", "tiktok", "shorts", "explore", "for you", "spotlight", "the feed"];
const ROW2 = ["just one more", "40 minutes gone", "how did i get here", "i dont even like this", "the algorithm wins"];

export default function Marquee() {
  return (
    <div style={band} aria-hidden>
      <style dangerouslySetInnerHTML={{ __html: css }} />
      <Row items={ROW1} cls="mq-l" />
      <Row items={ROW2} cls="mq-r" dim />
    </div>
  );
}

function Row({ items, cls, dim }: { items: string[]; cls: string; dim?: boolean }) {
  const doubled = [...items, ...items];
  return (
    <div style={rowWrap}>
      <div style={track} className={cls}>
        {doubled.map((t, i) => (
          <span key={i} style={{ ...item, color: dim ? signal.textFaint : signal.textDim }}>
            {t}
            <span style={sep}>/</span>
          </span>
        ))}
      </div>
    </div>
  );
}

const band: CSSProperties = {
  width: "100vw",
  marginLeft: "calc(50% - 50vw)",
  overflow: "hidden",
  borderTop: `1px solid ${signal.border}`,
  borderBottom: `1px solid ${signal.border}`,
  padding: "clamp(18px, 3vw, 32px) 0",
  display: "flex",
  flexDirection: "column",
  gap: "clamp(6px, 1.2vw, 14px)",
};
const rowWrap: CSSProperties = { overflow: "hidden", whiteSpace: "nowrap" };
const track: CSSProperties = { display: "inline-flex", width: "max-content", willChange: "transform" };
const item: CSSProperties = {
  display: "inline-flex",
  alignItems: "center",
  fontSize: "clamp(24px, 4.5vw, 50px)",
  fontWeight: 600,
  letterSpacing: "-0.02em",
  paddingRight: "clamp(16px, 2.5vw, 36px)",
};
const sep: CSSProperties = { marginLeft: "clamp(16px, 2.5vw, 36px)", color: signal.borderStrong };

const css = `
  .mq-l { animation: mqL 32s linear infinite; }
  .mq-r { animation: mqR 38s linear infinite; }
  @keyframes mqL { from { transform: translateX(0); } to { transform: translateX(-50%); } }
  @keyframes mqR { from { transform: translateX(-50%); } to { transform: translateX(0); } }
  @media (prefers-reduced-motion: reduce) { .mq-l, .mq-r { animation: none; } }
`;
