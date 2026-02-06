# NetBird Server (monolithic)

This add-on runs the NetBird self-hosted server stack in a single container (Management + Signal + Dashboard + Coturn; Relay optional). It does **not** use Home Assistant ingress. Access the Dashboard directly via the configured port.

NetBird relies on gRPC. If you place the Management/Signal endpoints behind a reverse proxy, it **must** support HTTP/2 + gRPC proxying. See the NetBird reverse-proxy guide for supported configurations: <https://docs.netbird.io/selfhosted/reverse-proxy>.

The NetBird self-hosted guide includes up-to-date port requirements and legacy port notes: <https://docs.netbird.io/selfhosted/selfhosted-guide>.

The Dashboard container requires the `NETBIRD_MGMT_API_ENDPOINT` environment variable (the add-on injects this automatically) as described in the NetBird dashboard README: <https://github.com/netbirdio/dashboard#readme>.

## Quick start

1. Install the add-on.
2. Configure your Identity Provider (IdP) and set the required `auth_*` options (or edit the generated `management.json`).
3. Start the add-on and verify all services are running in the log output.
4. Access the dashboard at `http://<HA_HOST>:<dashboard_port>`.

> **Tip:** If you are using your own reverse proxy, set `external_base_url` to the public URL and keep TLS termination in your proxy.

## Configuration

### Required options
- `data_dir`: Where NetBird stores persistent data. Default: `/config/netbird`.
- `auth_authority`, `auth_client_id`, `auth_audience`, `auth_jwt_certs`, `auth_oidc_configuration_endpoint`: OIDC values used by the Management service and Dashboard.

### Optional options
- `disable_dashboard`: Disable the dashboard service entirely.
- `enable_relay`: Enable the NetBird relay service (requires `relay_exposed_address` and `relay_auth_secret`).
- `turn_external_ip`: Public IP to advertise when Coturn is behind NAT.
- `allow_legacy_ports`: Keep legacy port exposure for pre-v0.29 agents (see NetBird docs).

### Generated configuration
On first start, the add-on creates:
- `management.json` in `$data_dir/management/`
- `turnserver.conf` in `$data_dir/turn/`

If you need advanced settings, stop the add-on and edit these files. The add-on will keep your edits on restart.

## Ports

Default ports exposed by this add-on:

- `33073/tcp`: Management API (HTTP/gRPC)
- `10000/tcp`: Signal gRPC
- `8080/tcp`: Dashboard
- `3478/udp`: Coturn STUN/TURN
- `33080/tcp`: Relay (optional)

If you have legacy (< v0.29) clients, review the legacy port notes in the NetBird self-hosted guide and ensure your firewall/forwarding rules are compatible.

## Logs

Use `log_level: debug` for more verbose logging.

## Notes

- This add-on does **not** handle TLS certificates. Place it behind your existing reverse proxy if you need HTTPS.
- Coturn requires a UDP relay port range (defaults to `49152-65535`). Ensure this range is allowed in your firewall when using TURN relaying.
