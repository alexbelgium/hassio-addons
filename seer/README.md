# Home Assistant add-on: Seer

## About

This add-on packages [Seerr](https://seerr.dev/), an open-source media request and discovery manager for Jellyfin, Plex, and Emby.

This add-on is based on the existing Overseerr add-on structure, adapted for the Seerr upstream project and container image.

Upstream repositories reviewed:
- Overseerr: https://github.com/sct/overseerr
- Seerr: https://github.com/seerr-team/seerr

## Installation

1. Add this repository to Home Assistant.
2. Install **Seer**.
3. Configure options, then start the add-on.
4. Open the Web UI on port `5055`.

## Configuration

Use `env_vars` to pass extra environment variables when needed. Seer configuration is stored in `/config`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PGID` | int | `0` | Group ID for file permissions |
| `PUID` | int | `0` | User ID for file permissions |
| `TZ` | str | | Timezone (e.g. `Europe/London`) |

### Example

```yaml
env_vars: []
PGID: 0
PUID: 0
TZ: Europe/London
```

## Support

If you find a bug, open an issue in this repository.
