# Aurral

[![Source][source-shield]][source]
![Supports aarch64][aarch64-shield]
![Supports amd64][amd64-shield]

Self-hosted music discovery, request management, flows, and playlist importing
for Lidarr — with library-aware recommendations and Navidrome integration.

## Installation

1. Add **alexbelgium's add-on repository** to Home Assistant (if not already added).
2. Go to **Settings → Add-ons → Add-on Store**, find **Aurral**, and click **Install**.
3. Configure the options below, then click **Start**.

## Configuration

```yaml
# Host path (under /share) where Aurral writes flow downloads.
download_folder: /share/aurral/downloads

# Host path (under /share) for Aurral's database and persistent config.
data_folder: /share/aurral/data

# Run as this UID/GID — match your host directory ownership.
PUID: 1000
PGID: 1000

# Set true if behind HA ingress or a reverse proxy.
TRUST_PROXY: "true"

# Your timezone, e.g. Australia/Melbourne  (leave blank to inherit from HA)
TZ: ""

# Allow self-signed TLS on your Lidarr instance.
LIDARR_INSECURE: "false"

# Reverse-proxy SSO auth (optional).
AUTH_PROXY_ENABLED: "false"
AUTH_PROXY_HEADER: ""
AUTH_PROXY_TRUSTED_IPS: ""
```

## Volume Mapping

| Option | HA host path (default) | Container path | Purpose |
|---|---|---|---|
| `download_folder` | `/share/aurral/downloads` | `/app/downloads` | Flow output, Navidrome playlists |
| `data_folder` | `/share/aurral/data` | `/app/backend/data` | Database, settings |
| *(built-in)* | `/media` | `/media` | HA media library (read) |

## Ports

| Port | Description |
|---|---|
| `3001/tcp` | Aurral Web UI |

## Requirements

- **Lidarr** reachable from your HA host
- **Last.fm API key** for recommendations and metadata
- Optional: **Navidrome** for flow/playlist library integration

## More Information

Full documentation, flows guide, and Spotify import helper:
[github.com/lklynet/aurral][source]

[source-shield]: https://img.shields.io/badge/source-lklynet%2Faurral-blue
[source]: https://github.com/lklynet/aurral
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
