# Bubble – VPN traffic filtering (WireGuard + mitmproxy)

Filter VPN traffic on the server using:

1. **Application-layer (mitmproxy)** – Host, `Content-Type`, `Content-Length`, kill-before-body (e.g. block Instagram Reels / large video while allowing DMs).
2. **Packet-level (nftables)** – Drop inner packets by size on the WireGuard interface (optional).

You already have WireGuard set up; this adds the proxy and optional packet filter on the same server.

## Quick start (application-layer proxy)

```bash
# On the VPN server
cd /path/to/bubble
cp config.example.env .env
# Edit .env if you want a different port or interface
pip install -r requirements.txt
chmod +x scripts/*.sh
./scripts/run_proxy.sh
```

- **mitmweb** (default) opens a web UI; **mitmproxy** is TUI; **mitmdump** is headless; **transparent** for transparent proxying (use with `setup_transparent_redirect.sh`):
  - `./scripts/run_proxy.sh web`   → mitmweb
  - `./scripts/run_proxy.sh proxy` → mitmproxy
  - `./scripts/run_proxy.sh dump`  → mitmdump
  - `./scripts/run_proxy.sh transparent` → mitmdump in transparent mode

On first run, mitmproxy creates its CA under `~/.mitmproxy`. Clients must **install that CA** and use the server as their HTTP(S) proxy (see [Client setup](#client-setup)).

## Client setup (proxy + CA)

1. **Proxy URL**  
   Set the proxy to the VPN server’s WireGuard IP and port, e.g. `http://10.0.0.1:8080` (use your server’s `Address` from the WireGuard config).

2. **Install the CA**  
   On the server, after starting the proxy once, get the CA path:
   ```bash
   ./scripts/export_ca.sh
   ```
   Copy the PEM file to the client (e.g. `mitmproxy-dashboard-ca.pem` or `mitmproxy-ca.pem`) and add it to the system/browser trust store so HTTPS works without certificate errors.

3. **Use the VPN**  
   Connect to WireGuard first, then set `HTTP_PROXY` and `HTTPS_PROXY` to the proxy URL. Only traffic that goes through the proxy is filtered (apps that respect the system proxy).

## Optional: packet-level filter (nftables)

To drop inner packets larger than a given size on the WireGuard interface (e.g. to cap jumbos or enforce a size policy without using the proxy):

```bash
# On the VPN server, as root
echo "PACKET_MAX_BYTES=9000" >> .env   # 0 = disabled
echo "WG_INTERFACE=wg0" >> .env        # your WireGuard interface name
sudo ./scripts/setup_packet_filter.sh enable
```

- **disable:** `sudo ./scripts/setup_packet_filter.sh disable`
- **status:** `sudo ./scripts/setup_packet_filter.sh status`

Use a value **above** your MTU (e.g. 1500) so you don’t drop normal traffic; `9000` is a common choice for “no jumbos.”

## Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `PROXY_LISTEN_HOST` | mitmproxy bind address | `0.0.0.0` |
| `PROXY_LISTEN_PORT` | mitmproxy port | `8080` |
| `PROXY_MODE` | `web`, `proxy`, `dump`, or `transparent` | `web` |
| `PACKET_MAX_BYTES` | Drop inner packets larger than this (bytes); `0` = off | `0` |
| `WG_INTERFACE` | WireGuard interface for packet filter / redirect | `wg0` |
| `VPN_SUBNET` | Client subnet for transparent redirect (e.g. `10.0.0.0/24`) | (unset) |

Copy `config.example.env` to `.env` and edit as needed. Changing `.env` and restarting the proxy or re-running the packet-filter script applies new values (no need to edit firewall rules by hand).

## Restart behavior (systemd)

So the proxy and packet filter survive reboots and WireGuard restarts:

1. **Proxy:** Copy `systemd/bubble-proxy.service` to `/etc/systemd/system/`. Create user `bubble`, deploy the repo to `/opt/bubble` (or set `BUBBLE_ROOT` in `/etc/default/bubble`), then:
   ```bash
   sudo systemctl daemon-reload && sudo systemctl enable --now bubble-proxy
   ```
2. **Packet filter:** Copy `systemd/bubble-packet-filter.service` to `/etc/systemd/system/`. Set `PACKET_MAX_BYTES` and `WG_INTERFACE` in `/opt/bubble/.env`, then:
   ```bash
   sudo systemctl daemon-reload && sudo systemctl enable bubble-packet-filter
   sudo systemctl start bubble-packet-filter
   ```
   The oneshot reapplies nftables rules on boot.

## Addon (VeilHeuristicBlocker)

`veil_logic.py` implements:

- **Target hosts:** `instagram`, `fbcdn` (so the rest of the internet is unchanged).
- **Block:** (1) Response `Content-Type` containing `video`, (2) Response `Content-Length` &gt; 1.2 MB.
- **When:** At response headers, so the connection is killed before the body is downloaded.

You can change the threshold or domains in `veil_logic.py` and add more addons in the same script.

## Transparent proxy (optional)

To force all HTTP(S) from VPN clients through the proxy without setting the proxy on each device:

1. **Redirect** VPN client traffic: set `VPN_SUBNET` (e.g. `10.0.0.0/24`) in `.env`, then `sudo ./scripts/setup_transparent_redirect.sh enable`.
2. Run the proxy in transparent mode: `./scripts/run_proxy.sh transparent` (or set `PROXY_MODE=transparent` in `.env`).
3. Clients still must install the proxy CA for TLS to succeed.
4. **Disable redirect:** `sudo ./scripts/setup_transparent_redirect.sh disable`.

## Security notes

- The mitmproxy CA allows the server to decrypt HTTPS. Restrict access to the proxy (e.g. bind to the WireGuard interface IP only) and protect the CA.
- Run mitmproxy as a non-root user when possible; use a dedicated user and `--listen-host` to the WG interface IP if you don’t need to listen on all interfaces.

## License

Use and modify as you like.
