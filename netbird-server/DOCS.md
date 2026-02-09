# NetBird Server (quickstart)

This add-on runs the NetBird self-hosted server stack in a single container (Management + Signal + Relay/STUN + Dashboard) and ships a built-in Caddy reverse proxy, matching the official NetBird self-hosted quickstart flow. It does **not** use Home Assistant ingress.

NetBird relies on gRPC. The built-in Caddy configuration is pre-wired to proxy both HTTP and gRPC endpoints as recommended in the quickstart guide: <https://docs.netbird.io/selfhosted/selfhosted-quickstart>.

## Quick start

1. Install the add-on.
2. Set the `domain` option to your public NetBird domain (e.g., `netbird.example.com`).
3. Start the add-on and verify all services are running in the log output.
4. Access the dashboard at `https://<your-domain>` and complete the onboarding flow.

## Configuration

This add-on generates the standard quickstart configuration files in `/config/netbird` and reuses them on subsequent starts.

### Required options
- `domain`: Public domain that resolves to your Home Assistant host (e.g., `netbird.example.com`). If left at the default placeholder, the add-on will try to use the host from Home Assistant's `external_url` or `internal_url` instead.

### Dashboard environment overrides
Edit `/config/netbird/dashboard/env` to configure the dashboard UI:

- `NETBIRD_MGMT_API_ENDPOINT`: Public URL of the management API (for example, `https://netbird.example.com`).
- `NETBIRD_MGMT_GRPC_API_ENDPOINT`: Public URL for the gRPC API (typically the same as above).
- `AUTH_*`: OIDC settings for the dashboard UI (pre-filled for the embedded IdP).

### Generated configuration
On first start, the add-on creates:
- `management.json` in `/config/netbird/management/`
- `relay.env` in `/config/netbird/relay/`
- `dashboard.env` in `/config/netbird/dashboard/`
- `Caddyfile` in `/config/netbird/`

If you need advanced settings, stop the add-on and edit these files. The add-on will keep your edits on restart.

## Ports

Default ports exposed by this add-on:

- `80/tcp`: Caddy HTTP (ACME HTTP-01)
- `443/tcp`: Caddy HTTPS (Dashboard + APIs)
- `443/udp`: Caddy HTTP/3 (optional)
- `3478/udp`: Relay STUN

## Notes

- This add-on uses NetBird's embedded IdP (Dex) and matches the official quickstart layout.
- If you already run your own reverse proxy, you can disable Caddy by editing the generated `Caddyfile` or by terminating TLS upstream and forwarding requests to port 80.
