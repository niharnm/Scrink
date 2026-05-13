"""
VeilHeuristicBlocker - mitmproxy addon for application-layer filtering.

Blocks Instagram Reels by decoding the base64 ``efg`` query parameter on
CDN video requests and dropping those whose ``vencode_tag`` contains
"clips" (Reels) while allowing "story" content through.
Blocks YouTube video playback by dropping all googlevideo.com/videoplayback
requests (the CDN endpoint for all YouTube video streams).
Blocks Kalshi order placement by killing POST requests to the orders API.
Passes through TLS for hosts with certificate pinning (e.g. Cursor).
"""
import base64
import json
import os
import re
import time
from mitmproxy import http, tls
import logging

from analytics import AnalyticsClient

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class VeilHeuristicBlocker:
    PASSTHROUGH_HOSTS = {".cursor.sh", ".icloud.com", ".apple.com"}

    def __init__(self):
        self.analytics = AnalyticsClient(
            flush_interval=float(os.environ.get("ANALYTICS_FLUSH_INTERVAL", "10")),
            flush_size=int(os.environ.get("ANALYTICS_FLUSH_SIZE", "50")),
        )

    # --- Instagram Reels blocking (vencode_tag-based) ---
    # Instagram and its CDN domains (where media is served)
    INSTAGRAM_MEDIA_DOMAINS = {
        "instagram",        # keyword match (covers *.instagram.com, cdninstagram.com)
    }
    INSTAGRAM_CDN_DOMAINS = {
        "fbcdn.net",
        "fbsbx.com",
        "facebook.net",
    }

    # --- YouTube video blocking ---
    # googlevideo.com CDN domain where YouTube video chunks are served.
    YOUTUBE_CDN_DOMAIN = "googlevideo.com"
    # The path used for all YouTube video stream requests.
    YOUTUBE_VIDEOPLAYBACK_PATH = "/videoplayback"

    # --- Kalshi order blocking ---
    # Block POST requests to the Kalshi orders API to prevent placing bets.
    # Matches: /v1/users/{uuid}/orders and /trade-api/v2/portfolio/orders etc.
    KALSHI_DOMAIN = "kalshi.com"
    KALSHI_ORDERS_PATTERN = re.compile(r"/(?:v\d+/users/[^/]+/orders|trade-api/v\d+/portfolio/orders)")

    # ---- helpers ----

    def _is_googlevideo_domain(self, host: str) -> bool:
        """True for googlevideo.com or any subdomain."""
        if not host:
            return False
        h = host.lower()
        return h == self.YOUTUBE_CDN_DOMAIN or h.endswith("." + self.YOUTUBE_CDN_DOMAIN)

    def _is_videoplayback_request(self, flow: http.HTTPFlow) -> bool:
        """True if the request is a /videoplayback stream with ctier=sh (short-form video)."""
        path = flow.request.path or ""
        # path may include query string; check the path component only
        if path.split("?")[0] != self.YOUTUBE_VIDEOPLAYBACK_PATH:
            return False
        # Only block short-form video (Shorts). ctier=A is normal video; ctier=sh is Shorts.
        ctier = flow.request.query.get("ctier", "").lower()
        return ctier == "sh"

    def _is_kalshi_domain(self, host: str) -> bool:
        """True for kalshi.com or any subdomain (e.g. api.elections.kalshi.com)."""
        if not host:
            return False
        h = host.lower()
        return h == self.KALSHI_DOMAIN or h.endswith("." + self.KALSHI_DOMAIN)

    def _is_kalshi_order_post(self, flow: http.HTTPFlow) -> bool:
        """True if this is a POST to a Kalshi orders endpoint."""
        if flow.request.method.upper() != "POST":
            return False
        path = (flow.request.path or "").split("?")[0]
        return bool(self.KALSHI_ORDERS_PATTERN.search(path))

    def _is_instagram_domain(self, host: str) -> bool:
        """True for any Instagram or Instagram-CDN host."""
        if not host:
            return False
        h = host.lower()
        if any(kw in h for kw in self.INSTAGRAM_MEDIA_DOMAINS):
            return True
        return any(h == d or h.endswith("." + d) for d in self.INSTAGRAM_CDN_DOMAINS)

    def _decode_vencode_tag(self, flow: http.HTTPFlow) -> str | None:
        """Decode the base64 ``efg`` query parameter and return the vencode_tag.

        Instagram CDN video URLs carry an ``efg`` query parameter that is
        base64-encoded JSON.  The ``vencode_tag`` field inside indicates the
        content type — e.g. ``ig-xpvds.clips.…`` for Reels,
        ``ig-xpvds.story.…`` for Stories.

        Returns the vencode_tag string, or *None* if decoding fails or the
        parameter is absent.
        """
        efg_b64 = flow.request.query.get("efg", "")
        if not efg_b64:
            return None
        try:
            # The value may already be properly padded, but add padding to be safe.
            padded = efg_b64 + "=" * (-len(efg_b64) % 4)
            decoded = base64.b64decode(padded)
            data = json.loads(decoded)
            return data.get("vencode_tag")
        except Exception:
            return None

    # ---- mitmproxy hooks ----

    def tls_clienthello(self, data: tls.ClientHelloData) -> None:
        """Skip TLS interception for hosts that pin certificates."""
        sni = data.client_hello.sni or ""
        if any(sni == h.lstrip(".") or sni.endswith(h) for h in self.PASSTHROUGH_HOSTS):
            logger.info("passthrough: TLS for %s", sni)
            data.ignore_connection = True

    def request(self, flow: http.HTTPFlow) -> None:
        """Kill blocked requests before any data is fetched."""
        host = flow.request.pretty_host or ""

        # Store request start time for duration tracking
        flow.metadata["_start_time"] = time.time()

        # YouTube video playback
        if self._is_googlevideo_domain(host) and self._is_videoplayback_request(flow):
            logger.info(
                "block(yt): YouTube video from %s%s",
                host,
                (flow.request.path or "")[:80],
            )
            self.analytics.record(flow, blocked=True, block_reason="youtube_video")
            flow.kill()
            return

        # Kalshi order placement
        if self._is_kalshi_domain(host) and self._is_kalshi_order_post(flow):
            logger.info(
                "block(kalshi): POST order to %s%s",
                host,
                (flow.request.path or "")[:80],
            )
            self.analytics.record(flow, blocked=True, block_reason="kalshi_order")
            flow.kill()
            return

        # Instagram Reels & Ads — decode the efg param and block clips (reels)
        # and ads, while allowing stories through.
        if self._is_instagram_domain(host):
            vencode_tag = self._decode_vencode_tag(flow)
            if vencode_tag and ".clips." in vencode_tag:
                logger.info(
                    "block(reel): vencode_tag=%s from %s%s",
                    vencode_tag,
                    host,
                    (flow.request.path or "")[:60],
                )
                self.analytics.record(flow, blocked=True, block_reason="instagram_reel")
                flow.kill()
                return
            if vencode_tag and vencode_tag.startswith("ads_"):
                logger.info(
                    "block(ad): vencode_tag=%s from %s%s",
                    vencode_tag,
                    host,
                    (flow.request.path or "")[:60],
                )
                self.analytics.record(flow, blocked=True, block_reason="instagram_ad")
                flow.kill()
                return

    def response(self, flow: http.HTTPFlow) -> None:
        """Record allowed (non-killed) traffic after response completes."""
        if flow.response is None:
            return

        start = flow.metadata.get("_start_time")
        duration_ms = int((time.time() - start) * 1000) if start else None

        bytes_in = len(flow.request.content) if flow.request.content else 0
        bytes_out = len(flow.response.content) if flow.response.content else 0

        self.analytics.record(
            flow,
            blocked=False,
            status_code=flow.response.status_code,
            bytes_in=bytes_in,
            bytes_out=bytes_out,
            duration_ms=duration_ms,
        )


addons = [VeilHeuristicBlocker()]
