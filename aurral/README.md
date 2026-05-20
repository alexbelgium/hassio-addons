# Aurral

[![Source][source-shield]][source]
![Supports aarch64][aarch64-shield]
![Supports amd64][amd64-shield]

Self-hosted music discovery, request management, flows, and playlist importing
for Lidarr — with library-aware recommendations and Navidrome integration.

## Installation

1. Add **alexbelgium's add-on repository** to Home Assistant:
   [![Add repository][repo-badge]][repo-url]
2. Go to **Settings → Add-ons → Add-on Store**, find **Aurral**, and click **Install**.
3. Set the `download_folder` and `data_folder` options (see below), then click **Start**.

## Configuration

All options are set in the **Configuration** tab of the add-on UI.

| Option | Default | Description |
|---|---|---|
| `download_folder` | `/share/aurral/downloads` | Path where Aurral writes flow downloads and Navidrome playlists. Must be under `/share`. |
| `data_folder` | `/share/aurral/data` | Path for Aurral's database and persistent config. Must be under `/share`. |
| `PUID` | `1000` | User ID to run as — match your host directory ownership. |
| `PGID` | `1000` | Group ID to run as. |
| `TRUST_PROXY` | `true` | Set `true` when behind HA ingress or a reverse proxy. |
| `TZ` | *(empty)* | Your timezone, e.g. `Australia/Melbourne`. Leave blank to inherit from HA. |
| `LIDARR_INSECURE` | `false` | Allow self-signed TLS on your Lidarr instance. |
| `AUTH_PROXY_ENABLED` | `false` | Enable reverse-proxy SSO auth. |
| `AUTH_PROXY_HEADER` | *(empty)* | Header carrying the authenticated username, e.g. `X-Forwarded-User`. |
| `AUTH_PROXY_TRUSTED_IPS` | *(empty)* | Comma-separated IPs trusted to send the auth header. |
| `env_vars` | `[]` | Extra environment variables passed directly to Aurral. |

## Volume Mapping

| Option | Container path | Purpose |
|---|---|---|
| `download_folder` | `/app/downloads` | Flow output, Navidrome playlists |
| `data_folder` | `/app/backend/data` | Database, settings |
| *(built-in)* `/media` | `/media` | HA media library (read) |

## Ports

| Port | Description |
|---|---|
| `3001/tcp` | Aurral Web UI (also available via HA Ingress sidebar) |

## Requirements

- **Lidarr** reachable from your HA host
- **Last.fm API key** (free) for recommendations and metadata
- Optional: **Navidrome** for flow/playlist library integration

## More Information

Full documentation, flows guide, and Spotify import helper:
[github.com/lklynet/aurral][source]

[source-shield]: https://img.shields.io/badge/source-lklynet%2Faurral-blue
[source]: https://github.com/lklynet/aurral
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[repo-badge]: https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg
[repo-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons
