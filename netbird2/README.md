# Home assistant add-on: NetBird Server 2

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons.

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon information

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetbird2%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetbird2%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetbird2%2Fconfig.json)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

## About

NetBird is a secure, WireGuard-based overlay network platform. This add-on packages the **management**, **signal**, and optional **dashboard** services in a single monolithic Home Assistant add-on (no ingress UI, no split services). It uses the upstream NetBird Docker images for the binaries and dashboard assets.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## Configuration

> **Important**: NetBird requires OIDC configuration. The add-on will generate a starter `management.json` in `/data/netbird` if one does not exist. Replace the placeholder OIDC values with your IdP configuration before connecting clients.

Example add-on options:

```json
{
  "domain": "netbird.example.com",
  "management_port": 33073,
  "signal_port": 10000,
  "dashboard_port": 33080,
  "enable_dashboard": true,
  "auth_issuer": "https://accounts.example.com/",
  "auth_audience": "netbird",
  "auth_jwt_certs": "https://accounts.example.com/jwks.json",
  "auth_oidc_configuration_endpoint": "https://accounts.example.com/.well-known/openid-configuration",
  "auth_client_id": "netbird-dashboard",
  "auth_client_secret": "your-secret",
  "ssl_cert": "/ssl/fullchain.pem",
  "ssl_key": "/ssl/privkey.pem"
}
```

### Options

| Option | Description |
| --- | --- |
| `data_path` | Persistent data directory (default: `/data/netbird`). |
| `domain` | Public hostname used for NetBird endpoints. |
| `management_port` | Management API port. |
| `signal_port` | Signal service port. |
| `dashboard_port` | Dashboard port (only used if enabled). |
| `enable_dashboard` | Start the NetBird dashboard (requires OIDC settings). |
| `management_dns_domain` | DNS suffix handed to peers. |
| `single_account_domain` | Optional single-account mode domain. |
| `disable_anonymous_metrics` | Disable anonymous metrics. |
| `disable_default_policy` | Disable the default NetBird policy on first run. |
| `auth_*` | OIDC settings for the management server and dashboard. |
| `ssl_cert`, `ssl_key` | Optional TLS certificate/key paths. |
| `env_vars` | Extra environment variables passed into NetBird processes. |

### Files and persistent data

- `/data/netbird/management.json`: management server configuration (generated on first start).
- `/data/netbird`: runtime data for NetBird components.

### Ports

- `33073/tcp`: NetBird management API.
- `10000/tcp`: NetBird signal.
- `33080/tcp`: NetBird dashboard (optional).

## Logs and status

The add-on uses s6 supervision; if any NetBird component exits, the supervisor restarts the service and logs the failure to the Home Assistant add-on log stream.

## Local build/test

```bash
# From the repository root
ha addons build netbird2
ha addons install ./netbird2
```

[repository]: https://github.com/alexbelgium/hassio-addons
