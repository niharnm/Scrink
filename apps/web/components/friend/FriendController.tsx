"use client";

import { CSSProperties, useCallback, useEffect, useMemo, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { signal } from "@/lib/signal";

type Feature = { id: string; name: string; blurb: string };
type App = { id: string; name: string; features: Feature[] };
type Pairing = { pairing_id: string; owner_user_id: string; window_end: string };

export default function FriendController({ userId }: { userId: string; email: string }) {
  const supabase = useMemo(() => createClient(), []);

  const [code, setCode] = useState("");
  const [pairing, setPairing] = useState<Pairing | null>(null);
  const [apps, setApps] = useState<App[]>([]);
  const [enabled, setEnabled] = useState<Set<string>>(new Set()); // "appId/featureId"
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [now, setNow] = useState(() => Date.now());
  const [revoked, setRevoked] = useState(false);

  // Window countdown.
  useEffect(() => {
    const t = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(t);
  }, []);

  const remaining = pairing ? new Date(pairing.window_end).getTime() - now : 0;
  const expired = pairing != null && remaining <= 0;
  const locked = expired || revoked;

  const loadAfterRedeem = useCallback(
    async (p: Pairing) => {
      // Active rule pack → which apps/feeds exist to toggle.
      const { data: packRow, error: packErr } = await supabase
        .from("block_rules")
        .select("pack")
        .eq("is_active", true)
        .limit(1)
        .maybeSingle();
      if (packErr) setError("Couldn't load the app list — try refreshing.");
      const rawApps: App[] = Array.isArray(packRow?.pack?.apps) ? packRow!.pack.apps : [];
      const packApps: App[] = rawApps
        .map((a) => ({
          id: String(a?.id ?? ""),
          name: String(a?.name ?? ""),
          features: Array.isArray(a?.features)
            ? a.features.map((f) => ({ id: String(f?.id ?? ""), name: String(f?.name ?? ""), blurb: String(f?.blurb ?? "") }))
            : [],
        }))
        .filter((a) => a.id && a.features.length > 0);
      setApps(packApps);

      // Limits already set on this pairing.
      const { data: limits } = await supabase
        .from("friend_set_limits")
        .select("app_id,feature_id,enabled")
        .eq("pairing_id", p.pairing_id);
      const on = new Set<string>();
      (limits ?? []).forEach((l: { app_id: string; feature_id: string; enabled: boolean }) => {
        if (l.enabled) on.add(`${l.app_id}/${l.feature_id}`);
      });
      setEnabled(on);
    },
    [supabase]
  );

  // Rehydrate an in-progress session on refresh (the code is single-use, so we
  // recover via the pairing the friend already holds, not by re-redeeming).
  useEffect(() => {
    (async () => {
      const { data } = await supabase
        .from("friend_pairings")
        .select("id,owner_user_id,window_end")
        .eq("friend_user_id", userId)
        .eq("revoked", false)
        .gt("window_end", new Date().toISOString())
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();
      if (data?.id) {
        const p: Pairing = { pairing_id: data.id, owner_user_id: data.owner_user_id, window_end: data.window_end };
        setPairing(p);
        await loadAfterRedeem(p);
      }
    })();
  }, [supabase, userId, loadAfterRedeem]);

  // Live notice when the owner ends the window early. RLS lets the friend read
  // this pairing, so realtime delivers the revoke the moment it happens instead
  // of failing silently on the next toggle.
  useEffect(() => {
    if (!pairing) return;
    const channel = supabase
      .channel(`pairing-${pairing.pairing_id}`)
      .on(
        "postgres_changes",
        { event: "UPDATE", schema: "public", table: "friend_pairings", filter: `id=eq.${pairing.pairing_id}` },
        (payload) => {
          if ((payload.new as { revoked?: boolean })?.revoked) setRevoked(true);
        }
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [supabase, pairing]);

  async function redeem() {
    setBusy(true);
    setError(null);
    try {
      const clean = code.replace(/\D/g, "").slice(0, 6);
      const { data, error } = await supabase.rpc("redeem_pairing", { p_code: clean });
      if (error) throw error;
      const row = Array.isArray(data) ? data[0] : data;
      if (!row?.pairing_id) {
        setError("That code didn't work — it may be wrong, used, or expired.");
        return;
      }
      const p: Pairing = row;
      setPairing(p);
      await loadAfterRedeem(p);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Something went wrong. Try again.");
    } finally {
      setBusy(false);
    }
  }

  async function toggle(app: App, feature: Feature) {
    if (!pairing || locked) return;
    const key = `${app.id}/${feature.id}`;
    const next = !enabled.has(key);
    // optimistic
    setEnabled((prev) => {
      const s = new Set(prev);
      if (next) s.add(key); else s.delete(key);
      return s;
    });
    const { error } = await supabase.from("friend_set_limits").upsert(
      {
        pairing_id: pairing.pairing_id,
        owner_user_id: pairing.owner_user_id,
        app_id: app.id,
        feature_id: feature.id,
        enabled: next,
        set_by: userId,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "pairing_id,app_id,feature_id" }
    );
    if (error) {
      setError("Couldn't save that — the window may have ended.");
      setEnabled((prev) => {
        const s = new Set(prev);
        if (next) s.delete(key); else s.add(key);
        return s;
      });
    }
  }

  // ---- styles ----
  const wrap: CSSProperties = {
    minHeight: "100vh", background: signal.bg, color: signal.text,
    fontFamily: signal.sans, padding: 24, display: "flex", justifyContent: "center",
  };
  const col: CSSProperties = { width: "100%", maxWidth: 460 };
  const card: CSSProperties = {
    background: signal.card, border: `1px solid ${signal.border}`,
    borderRadius: 18, padding: 20,
  };
  const label: CSSProperties = { fontSize: 12, letterSpacing: 1, color: signal.textDim, fontWeight: 600 };
  const primaryBtn: CSSProperties = {
    width: "100%", height: 52, border: "none", borderRadius: 14, cursor: "pointer",
    background: signal.text, color: signal.bg, fontWeight: 700, fontSize: 16,
  };

  function fmt(ms: number) {
    const s = Math.max(0, Math.floor(ms / 1000));
    const h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60);
    return h > 0 ? `${h}h ${m}m` : `${m}m`;
  }

  return (
    <div style={wrap}>
      <div style={col}>
        <div style={{ marginBottom: 24 }}>
          <div style={label}>FRIEND CONTROL</div>
          <h1 style={{ fontSize: 30, fontWeight: 800, margin: "4px 0 6px" }}>
            {pairing ? "You're holding the keys" : "Control a friend's screen time"}
          </h1>
          <p style={{ color: signal.textDim, fontSize: 14, margin: 0, lineHeight: 1.5 }}>
            {pairing
              ? "Flip on the feeds you want killed for them. They can't undo these until the window ends."
              : "Enter the 6-digit code they generated in the Rinkler app. You'll get to tighten their limits for the window they set."}
          </p>
        </div>

        {!pairing && (
          <div style={card}>
            <div style={{ ...label, marginBottom: 8 }}>THEIR CODE</div>
            <input
              inputMode="numeric"
              value={code}
              onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
              placeholder="000000"
              style={{
                width: "100%", boxSizing: "border-box", textAlign: "center",
                fontFamily: signal.mono, fontSize: 30, letterSpacing: 8,
                padding: "14px 0", marginBottom: 14, color: signal.text,
                background: signal.cardRaised, border: `1px solid ${signal.border}`, borderRadius: 12,
              }}
            />
            <button style={{ ...primaryBtn, opacity: busy || code.length < 6 ? 0.5 : 1 }}
              disabled={busy || code.length < 6} onClick={redeem}>
              {busy ? "Checking…" : "Unlock controls"}
            </button>
          </div>
        )}

        {pairing && (
          <>
            <div style={{ ...card, marginBottom: 16, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div>
                <div style={label}>WINDOW</div>
                <div style={{ fontFamily: signal.mono, fontSize: 22, fontWeight: 600 }}>
                  {revoked ? "ended early" : expired ? "ended" : `${fmt(remaining)} left`}
                </div>
              </div>
              <div style={{ textAlign: "right" }}>
                <div style={label}>FEEDS KILLED</div>
                <div style={{ fontFamily: signal.mono, fontSize: 22, fontWeight: 600, color: signal.blue }}>
                  {enabled.size}
                </div>
              </div>
            </div>

            {revoked ? (
              <p style={{ color: signal.warning, fontSize: 13, marginBottom: 12 }}>
                They ended the window early. Your changes no longer apply.
              </p>
            ) : expired ? (
              <p style={{ color: signal.warning, fontSize: 13, marginBottom: 12 }}>
                The window ended — your changes no longer apply.
              </p>
            ) : null}

            {apps.map((app) => (
              <div key={app.id} style={{ ...card, marginBottom: 12 }}>
                <div style={{ fontSize: 17, fontWeight: 700, marginBottom: 4 }}>{app.name}</div>
                {app.features.map((f) => {
                  const key = `${app.id}/${f.id}`;
                  const on = enabled.has(key);
                  return (
                    <div key={f.id} style={{
                      display: "flex", justifyContent: "space-between", alignItems: "center",
                      padding: "10px 0", borderTop: `1px solid ${signal.border}`,
                    }}>
                      <div style={{ paddingRight: 12 }}>
                        <div style={{ fontSize: 15, fontWeight: 500 }}>{f.name}</div>
                        <div style={{ fontSize: 12, color: signal.textDim }}>{f.blurb}</div>
                      </div>
                      <button
                        onClick={() => toggle(app, f)}
                        disabled={locked}
                        aria-pressed={on}
                        style={{
                          width: 52, height: 31, borderRadius: 16, border: "none", flexShrink: 0,
                          cursor: locked ? "default" : "pointer",
                          background: on ? signal.blue : signal.cardRaised,
                          position: "relative", transition: "background .15s",
                        }}
                      >
                        <span style={{
                          position: "absolute", top: 3, left: on ? 24 : 3, width: 25, height: 25,
                          borderRadius: "50%", background: "#fff", transition: "left .15s",
                        }} />
                      </button>
                    </div>
                  );
                })}
              </div>
            ))}
          </>
        )}

        {error && <p style={{ color: signal.warning, fontSize: 13, marginTop: 12 }}>{error}</p>}

        <p style={{ color: signal.textFaint, fontSize: 12, marginTop: 20, lineHeight: 1.5 }}>
          You can only add blocks, never loosen them, and only until the window ends. Their phone
          applies your changes within a few seconds.
        </p>
      </div>
    </div>
  );
}
