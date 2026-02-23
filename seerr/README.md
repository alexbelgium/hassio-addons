# Home Assistant add-on: Seerr

## About

This add-on packages [Seerr](https://seerr.dev/), an open-source media request and discovery manager for Jellyfin, Plex, and Emby.

This add-on is based on the existing Overseerr add-on structure, adapted for the Seerr upstream project and container image. It supports Home Assistant Ingress via an internal NGINX reverse proxy.

Upstream repositories reviewed:
- Overseerr: https://github.com/sct/overseerr
- Seerr: https://github.com/seerr-team/seerr

## Installation

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
2. Install **Seerr**.
3. Configure options, then start the add-on.
4. Open the Web UI on port `5055` or via Home Assistant Ingress.

## Configuration

Use `env_vars` to pass extra environment variables when needed. Seerr configuration is stored in `/config`.

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

## Migration

### From Overseerr

Seerr is compatible with Overseerr's data format. To migrate your existing configuration:

1. Stop the **Overseerr** add-on.
2. Install and start the **Seerr** add-on once to create its config directory (`/addon_configs/db21ed7f_seerr/`), then stop it.
3. Open the **[Filebrowser](https://github.com/alexbelgium/hassio-addons/tree/master/filebrowser)** add-on (or any file manager with access to `/addon_configs/`).
4. Navigate to `/addon_configs/db21ed7f_overseerr/` and copy all files into `/addon_configs/db21ed7f_seerr/`.
5. Start the **Seerr** add-on. Your existing settings, users, and requests will be preserved.

---

### From Jellyseerr

Seerr is compatible with Jellyseerr's data format. To migrate your existing configuration:

1. Stop the **Jellyseerr** add-on.
2. Install and start the **Seerr** add-on once to create its config directory (`/addon_configs/db21ed7f_seerr/`), then stop it.
3. Open the **[Filebrowser](https://github.com/alexbelgium/hassio-addons/tree/master/filebrowser)** add-on (or any file manager with access to `/addon_configs/`).
4. Navigate to `/addon_configs/db21ed7f_jellyseerr/` and copy all files into `/addon_configs/db21ed7f_seerr/`.
5. Start the **Seerr** add-on. Your existing settings, users, and requests will be preserved.

---

### From Ombi

Ombi uses a different data format and there is no automated migration path to Seerr. You will need to configure Seerr from scratch:

1. Note down your Ombi configuration (media servers, users, notification settings, etc.).
2. Stop the **Ombi** add-on.
3. Install and start the **Seerr** add-on.
4. Use the Seerr web UI to reconnect your media server(s) and reconfigure your preferences.

---

## Support

If you find a bug, open an issue in this repository.
