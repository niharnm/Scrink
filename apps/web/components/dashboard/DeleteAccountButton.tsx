"use client";

import { CSSProperties, useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

const DANGER = "#FF6B6B";

/**
 * In-app account deletion for the web, parity with the iOS app. Calls the same
 * SECURITY DEFINER `delete_current_user()` RPC (deletes the auth user; all rows
 * cascade via the user_id FKs), then clears the local session and leaves.
 */
export default function DeleteAccountButton() {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [confirmText, setConfirmText] = useState("");
  const [deleting, setDeleting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const canDelete = confirmText.trim().toUpperCase() === "DELETE" && !deleting;

  const close = () => {
    if (deleting) return;
    setOpen(false);
    setConfirmText("");
    setError(null);
  };

  const handleDelete = async () => {
    if (!canDelete) return;
    setDeleting(true);
    setError(null);
    try {
      const supabase = createClient();
      const { error: rpcError } = await supabase.rpc("delete_current_user");
      if (rpcError) {
        setError(rpcError.message || "Couldnt delete your account. Try again.");
        setDeleting(false);
        return;
      }
      // Account + all its data are gone — clear the local session and leave.
      await supabase.auth.signOut().catch(() => {});
      router.push("/login");
    } catch (e) {
      setError(e instanceof Error ? e.message : "Couldnt delete your account. Try again.");
      setDeleting(false);
    }
  };

  return (
    <>
      <button type="button" onClick={() => setOpen(true)} style={trigger} className="del-trigger">
        delete account
      </button>

      {open && (
        <div style={scrim} onClick={close}>
          <div style={card} onClick={(e) => e.stopPropagation()}>
            <h2 style={h2}>delete your account?</h2>
            <p style={body}>
              this permanently wipes your account and everything tied to it. it cant be undone.
            </p>
            <label style={label}>
              type <span style={{ color: signal.text, fontFamily: signal.mono }}>DELETE</span> to confirm
            </label>
            <input
              value={confirmText}
              onChange={(e) => setConfirmText(e.target.value)}
              placeholder="DELETE"
              autoFocus
              autoCapitalize="characters"
              autoComplete="off"
              style={input}
            />
            {error && <p style={errorStyle}>{error}</p>}
            <div style={row}>
              <button type="button" onClick={close} disabled={deleting} style={cancelBtn}>
                cancel
              </button>
              <button
                type="button"
                onClick={handleDelete}
                disabled={!canDelete}
                style={{ ...deleteBtn, opacity: canDelete ? 1 : 0.5, cursor: canDelete ? "pointer" : "not-allowed" }}
              >
                {deleting ? "deleting…" : "delete account"}
              </button>
            </div>
          </div>
        </div>
      )}

      <style>{`.del-trigger:hover { color: #FF8A8A; }`}</style>
    </>
  );
}

const trigger: CSSProperties = {
  background: "none",
  border: "none",
  cursor: "pointer",
  color: DANGER,
  fontFamily: signal.sans,
  fontSize: 14,
  padding: 0,
  transition: "color 0.15s ease",
};
const scrim: CSSProperties = {
  position: "fixed",
  inset: 0,
  zIndex: 50,
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  padding: 24,
  background: "rgba(4,4,6,0.72)",
  backdropFilter: "blur(4px)",
};
const card: CSSProperties = {
  width: "100%",
  maxWidth: 400,
  background: signal.card,
  border: `1px solid ${signal.border}`,
  borderRadius: 18,
  padding: 28,
  fontFamily: signal.sans,
};
const h2: CSSProperties = { margin: 0, fontSize: 22, fontWeight: 600, letterSpacing: "-0.02em", color: signal.text };
const body: CSSProperties = { margin: "12px 0 22px", fontSize: 14.5, lineHeight: 1.55, color: signal.textDim };
const label: CSSProperties = { display: "block", fontSize: 13, color: signal.textDim, marginBottom: 8 };
const input: CSSProperties = {
  width: "100%",
  padding: 13,
  borderRadius: 10,
  border: `1px solid ${signal.border}`,
  background: signal.bg,
  color: signal.text,
  fontFamily: signal.mono,
  fontSize: 15,
  letterSpacing: 3,
  outline: "none",
  boxSizing: "border-box",
};
const errorStyle: CSSProperties = { margin: "12px 0 0", fontSize: 13.5, color: DANGER };
const row: CSSProperties = { display: "flex", gap: 10, marginTop: 22 };
const cancelBtn: CSSProperties = {
  flex: 1,
  height: 44,
  borderRadius: 10,
  border: `1px solid ${signal.borderStrong}`,
  background: "transparent",
  color: signal.text,
  fontFamily: signal.sans,
  fontSize: 14.5,
  fontWeight: 500,
  cursor: "pointer",
};
const deleteBtn: CSSProperties = {
  flex: 1,
  height: 44,
  borderRadius: 10,
  border: "none",
  background: DANGER,
  color: "#2A0707",
  fontFamily: signal.sans,
  fontSize: 14.5,
  fontWeight: 600,
};
