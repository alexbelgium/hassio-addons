# Home Assistant Add-on: Maintainerr

_"Looks and smells like Overseerr, does the opposite."_

Maintainerr is a rule-based media management tool for your Plex, Jellyfin, or Emby ecosystem. It creates smart collections based on configurable rules (watched status, age, ratings, ...) and can optionally delete unwatched content to keep your library clean.

## About

Maintainerr integrates with:
- **Plex / Jellyfin / Emby** — media server
- **Sonarr / Radarr** — to remove media files
- **Overseerr / Jellyseerr** — to reset requests
- **Tautulli** — for advanced watch statistics

## Installation

1. Add the repository to Home Assistant.
2. Install the **Maintainerr** add-on.
3. Start the add-on.
4. Open the Web UI on port `6246`.

## Configuration

| Option | Description |
|--------|-------------|
| `TZ` | Timezone (e.g. `Europe/Paris`). Defaults to `Europe/London`. |
| `env_vars` | Extra environment variables passed to the container. |

### Available extra env vars

| Variable | Default | Description |
|----------|---------|-------------|
| `UI_PORT` | `6246` | Change the listening port |
| `BASE_PATH` | _(empty)_ | Serve under a URL subpath |

## Data

Persistent data (database, configuration) is stored in the HA addon config directory and survives add-on updates and reinstalls.

## Support

- [Maintainerr upstream project](https://github.com/maintainerr/maintainerr)
- [Addon repository issues](https://github.com/alexbelgium/hassio-addons/issues)
