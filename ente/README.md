# Home assistant add-on: Ente

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fente%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fente%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fente%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/ente/stats.png)

## About

---

[Ente](https://github.com/ente-io/ente) is a self-hosted, end-to-end encrypted photo and video storage solution. This addon provides a complete Ente server setup including the museum API server and MinIO S3-compatible storage backend.

Ente offers:
- End-to-end encrypted photo and video backup
- Face recognition and search
- Cross-platform mobile and desktop apps
- Automatic photo backup from mobile devices
- Album sharing with family and friends
- Full control over your data with self-hosting

This addon is based on the official Ente server: https://github.com/ente-io/ente/tree/main/server

## Configuration

---

Webui can be found at <http://homeassistant:PORT>.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `ENTE_ENDPOINT_URL` | str | `http://homeassistant.local:8280` | The URL where Ente API will be accessible |
| `MINIO_ROOT_USER` | str | `minioadmin` | MinIO root username |
| `MINIO_ROOT_PASSWORD` | str | `minioadmin` | MinIO root password |
| `MINIO_DATA_LOCATION` | str | `/config/minio-data` | Path where MinIO stores data |
| `DB_PASSWORD` | str | `ente` | Database password for internal PostgreSQL |
| `DISABLE_WEB_UI` | bool | `true` | Disable the web UI (use mobile/desktop apps) |
| `USE_EXTERNAL_DB` | bool | `false` | Use external PostgreSQL database |
| `TZ` | str | `Europe/Paris` | Timezone setting |

### External Database Configuration

If you want to use an external PostgreSQL database, set `USE_EXTERNAL_DB: true` and configure:

| Option | Type | Description |
|--------|------|-------------|
| `DB_HOSTNAME` | str | PostgreSQL server hostname |
| `DB_PORT` | int | PostgreSQL server port (default: 5432) |
| `DB_USERNAME` | str | PostgreSQL username |
| `DB_DATABASE_NAME` | str | PostgreSQL database name |

### Example Configuration

```yaml
ENTE_ENDPOINT_URL: "http://homeassistant.local:8280"
MINIO_ROOT_USER: "myuser"
MINIO_ROOT_PASSWORD: "mypassword"
MINIO_DATA_LOCATION: "/config/ente-storage"
DB_PASSWORD: "securepassword"
DISABLE_WEB_UI: false
TZ: "America/New_York"
```

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Mounting Drives

This addon supports mounting both local drives and remote SMB shares:

- **Local drives**: See [Mounting Local Drives in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-Local-Drives-in-Addons)
- **Remote shares**: See [Mounting Remote Shares in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Mounting-remote-shares-in-Addons)

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## First Time Setup

---

After starting the addon for the first time:

1. Download the Ente mobile app from:
   - [iOS App Store](https://apps.apple.com/app/ente-photos/id1542026904)
   - [Google Play Store](https://play.google.com/store/apps/details?id=io.ente.photos)
   - [F-Droid](https://f-droid.org/packages/io.ente.photos.fdroid/)

2. During app setup, select "Use custom server" and enter your addon URL: `http://your-homeassistant-ip:8280`

3. Create a new account using the mobile app

4. **Important**: Subscription codes cannot be sent by email for self-hosted instances. Check the addon logs for verification codes:
   ```
   Verification code: xxxxxx
   ```

5. Use the verification code from the logs to complete account setup

## Ports

The addon exposes three ports:

- **8300** (3000/tcp): Ente web UI (if enabled)
- **8280** (8080/tcp): Ente API server (museum) - Main endpoint for apps
- **8320** (3200/tcp): MinIO S3 endpoint (for storage backend)

## Data Storage

By default, photos and videos are stored in `/config/minio-data`. You can change this location using the `MINIO_DATA_LOCATION` option or mount external storage for larger capacity.

The addon includes:
- PostgreSQL database for metadata
- MinIO S3-compatible storage for actual photos/videos
- Ente museum API server for client communication

## Backup Recommendations

For data safety, regularly backup:
- `/config/minio-data` (or your custom storage location) - Contains all photos/videos
- PostgreSQL database (handled automatically by the addon)
- Addon configuration

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons