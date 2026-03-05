# Home Assistant Add-on: Cleanuparr

Automatically removes stuck, stalled, and unwanted downloads from your \*arr applications (Sonarr, Radarr, Lidarr, Readarr, Whisparr) and download clients (qBittorrent, Deluge, Transmission, NZBGet, SABnzbd).

## About

Cleanuparr monitors your download queues and applies configurable rules to:
- Remove stalled or stuck downloads
- Clean up unwanted files
- Notify via Apprise (Discord, Telegram, Slack, email, and 60+ more)

Integrations supported:
- **\*arr**: Sonarr, Radarr, Lidarr, Readarr, Whisparr
- **Download clients**: qBittorrent, Deluge, Transmission, NZBGet, SABnzbd

## Installation

1. Add the repository to Home Assistant.
2. Install the **Cleanuparr** add-on.
3. Start the add-on.
4. Open the Web UI on port `11011`.

## Configuration

| Option | Description |
|--------|-------------|
| `TZ` | Timezone (e.g. `Europe/Paris`). Defaults to `Europe/London`. |
| `PUID` | User ID to run the process as. Defaults to `0` (root). |
| `PGID` | Group ID to run the process as. Defaults to `0` (root). |
| `env_vars` | Extra environment variables passed to the container. |

## Data

Persistent configuration is stored in the HA addon config directory and survives add-on updates and reinstalls.

## Support

- [Cleanuparr upstream project](https://github.com/Cleanuparr/Cleanuparr)
- [Addon repository issues](https://github.com/alexbelgium/hassio-addons/issues)
