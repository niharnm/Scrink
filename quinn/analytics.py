"""
Buffered flow logger — records traffic events from mitmproxy to Supabase.

Usage in veil_logic.py:
    from analytics import AnalyticsClient
    analytics = AnalyticsClient()
    analytics.record(flow, blocked=False)
"""

import os
import time
import threading
import logging
from typing import Optional

import httpx

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Domain → app_category mapping
# ---------------------------------------------------------------------------
DOMAIN_CATEGORIES: dict[str, str] = {
    # Social media
    "instagram": "instagram",
    "cdninstagram": "instagram",
    "fbcdn.net": "instagram",
    "fbsbx.com": "instagram",
    "facebook.net": "instagram",
    "tiktok.com": "tiktok",
    "tiktokcdn.com": "tiktok",
    "musical.ly": "tiktok",
    "googlevideo.com": "youtube",
    "youtube.com": "youtube",
    "ytimg.com": "youtube",
    "youtu.be": "youtube",
    "twitter.com": "twitter",
    "x.com": "twitter",
    "twimg.com": "twitter",
    "reddit.com": "reddit",
    "redd.it": "reddit",
    "redditstatic.com": "reddit",
    "snapchat.com": "snapchat",
    "snap.com": "snapchat",
    "sc-cdn.net": "snapchat",
    # Betting
    "fanduel.com": "fanduel",
    "kalshi.com": "kalshi",
    # Google workspace (must come after googlevideo/youtube)
    "google.com": "google",
    "googleapis.com": "google",
    "gstatic.com": "google",
    "googleusercontent.com": "google",
    "gmail.com": "google",
    "google-analytics.com": "analytics",
    # Education
    "canvas": "education",
    "harvard.edu": "education",
    "instructure.com": "education",
    ".edu": "education",
    # Infrastructure
    "supabase": "infrastructure",
    "vercel": "infrastructure",
    "cloudflare": "infrastructure",
    "amazonaws.com": "infrastructure",
    "netlify": "infrastructure",
    "github.com": "infrastructure",
    "githubusercontent.com": "infrastructure",
    # Analytics & monitoring
    "datadog": "analytics",
    "sentry": "analytics",
    "mixpanel": "analytics",
    "amplitude": "analytics",
    "segment": "analytics",
    "hotjar": "analytics",
    # Productivity
    "slack": "productivity",
    "notion.so": "productivity",
    "notion.site": "productivity",
    "linear.app": "productivity",
    "figma": "productivity",
    "zoom.us": "productivity",
    "microsoft.com": "productivity",
    "office.com": "productivity",
    "outlook.com": "productivity",
    # AI
    "openai.com": "ai",
    "anthropic.com": "ai",
    "claude.ai": "ai",
    "chatgpt.com": "ai",
}


def categorize_host(host: str) -> str:
    """Map a hostname to an app category via keyword/suffix matching."""
    h = host.lower()
    for keyword, category in DOMAIN_CATEGORIES.items():
        if keyword in h:
            return category
    return "other"


class AnalyticsClient:
    """Thread-safe buffered analytics client that POSTs to Supabase REST API."""

    def __init__(
        self,
        supabase_url: Optional[str] = None,
        supabase_key: Optional[str] = None,
        flush_interval: float = 10.0,
        flush_size: int = 50,
    ):
        self._url = (supabase_url or os.environ.get("SUPABASE_URL", "")).rstrip("/")
        self._key = supabase_key or os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "")
        self._flush_interval = flush_interval
        self._flush_size = flush_size

        self._buffer: list[dict] = []
        self._lock = threading.Lock()
        self._enabled = bool(self._url and self._key)

        # Cache: wireguard_ip → (user_id, expires_at)
        self._ip_cache: dict[str, tuple[str, float]] = {}
        self._ip_cache_ttl = 300.0  # 5 minutes

        if not self._enabled:
            logger.warning("analytics: disabled (SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set)")
            return

        self._client = httpx.Client(
            base_url=self._url,
            headers={
                "apikey": self._key,
                "Authorization": f"Bearer {self._key}",
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
            },
            timeout=10.0,
        )

        # Background flush timer
        self._timer: Optional[threading.Timer] = None
        self._start_timer()
        logger.info("analytics: enabled, flush every %.0fs or %d events", flush_interval, flush_size)

    # ------------------------------------------------------------------
    # IP → user_id resolution
    # ------------------------------------------------------------------

    def _resolve_user_id(self, client_ip: str) -> Optional[str]:
        """Look up user_id from vpn_clients table, with TTL cache."""
        now = time.time()
        cached = self._ip_cache.get(client_ip)
        if cached and cached[1] > now:
            return cached[0]

        if not self._enabled:
            return None

        try:
            resp = self._client.get(
                "/rest/v1/vpn_clients",
                params={"wireguard_ip": f"eq.{client_ip}", "select": "user_id"},
            )
            resp.raise_for_status()
            rows = resp.json()
            if rows:
                user_id = rows[0]["user_id"]
                self._ip_cache[client_ip] = (user_id, now + self._ip_cache_ttl)
                return user_id
        except Exception as e:
            logger.debug("analytics: IP resolve failed for %s: %s", client_ip, e)

        return None

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def record(
        self,
        flow,
        blocked: bool = False,
        block_reason: Optional[str] = None,
        status_code: Optional[int] = None,
        bytes_in: int = 0,
        bytes_out: int = 0,
        duration_ms: Optional[int] = None,
    ) -> None:
        """Enqueue a traffic event. Never blocks the proxy."""
        if not self._enabled:
            return

        host = flow.request.pretty_host or ""
        client_ip = flow.client_conn.peername[0] if flow.client_conn and flow.client_conn.peername else None
        user_id = self._resolve_user_id(client_ip) if client_ip else None

        if not user_id:
            return  # unknown VPN client, skip

        content_type = None
        if flow.response and flow.response.headers:
            content_type = flow.response.headers.get("content-type", "")

        event = {
            "user_id": user_id,
            "host": host,
            "path": (flow.request.path or "")[:2048],
            "method": flow.request.method,
            "status_code": status_code,
            "content_type": content_type,
            "bytes_in": bytes_in,
            "bytes_out": bytes_out,
            "app_category": categorize_host(host),
            "blocked": blocked,
            "block_reason": block_reason,
            "client_ip": client_ip,
            "duration_ms": duration_ms,
        }

        with self._lock:
            self._buffer.append(event)
            if len(self._buffer) >= self._flush_size:
                self._flush_locked()

    def shutdown(self) -> None:
        """Flush remaining events and close the HTTP client."""
        if self._timer:
            self._timer.cancel()
        with self._lock:
            self._flush_locked()
        if self._enabled:
            self._client.close()

    # ------------------------------------------------------------------
    # Internal flush
    # ------------------------------------------------------------------

    def _start_timer(self) -> None:
        self._timer = threading.Timer(self._flush_interval, self._timer_flush)
        self._timer.daemon = True
        self._timer.start()

    def _timer_flush(self) -> None:
        with self._lock:
            self._flush_locked()
        self._start_timer()

    def _flush_locked(self) -> None:
        """Send buffered events to Supabase. Must be called with self._lock held."""
        if not self._buffer:
            return

        batch = self._buffer[:]
        self._buffer.clear()

        try:
            resp = self._client.post("/rest/v1/traffic_events", json=batch)
            resp.raise_for_status()
            logger.info("analytics: flushed %d events", len(batch))
        except Exception as e:
            logger.error("analytics: flush failed (%d events): %s", len(batch), e)
            # Re-add failed events (capped to prevent unbounded growth)
            if len(self._buffer) < self._flush_size * 5:
                self._buffer.extend(batch)
