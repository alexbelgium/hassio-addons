# Home assistant add-on: Immich Power Tools

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_power_tools%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_power_tools%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fimmich_power_tools%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/immich_power_tools/stats.png)

## About

[Immich Power Tools](https://github.com/varun-raj/immich-power-tools) provides advanced tools for organizing and managing your Immich photo library. This addon extends Immich's capabilities with powerful features for photo organization, analysis, and management.

Key features:
- Advanced photo organization tools
- Batch operations for photo management
- AI-powered photo analysis and tagging
- Geographic photo mapping with Google Maps integration
- Duplicate detection and management
- Advanced search and filtering capabilities

This addon is based on the [immich-power-tools](https://github.com/varun-raj/immich-power-tools) project.

## Configuration

Webui can be found at `<your-ip>:8001`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `IMMICH_URL` | str | **Required** | Internal Immich server URL (e.g., `http://homeassistant:3001`) |
| `EXTERNAL_IMMICH_URL` | str | **Required** | External Immich server URL for browser access |
| `IMMICH_API_KEY` | str | **Required** | Immich API key for authentication |
| `DB_HOST` | str | **Required** | Database hostname (e.g., `core-mariadb` or `homeassistant`) |
| `DB_USERNAME` | str | **Required** | Database username |
| `DB_PASSWORD` | str | **Required** | Database password |
| `DB_DATABASE_NAME` | str | **Required** | Database name (usually `immich`) |
| `DB_PORT` | str | **Required** | Database port (usually `5432` for PostgreSQL) |
| `GOOGLE_MAPS_API_KEY` | str | | Google Maps API key for geographic features |
| `GEMINI_API_KEY` | str | | Google Gemini API key for AI features |

### Example Configuration

```yaml
IMMICH_URL: "http://homeassistant:3001"
EXTERNAL_IMMICH_URL: "https://your-immich-domain.com"
IMMICH_API_KEY: "your-immich-api-key-here"
DB_HOST: "core-mariadb"
DB_USERNAME: "immich"
DB_PASSWORD: "your-db-password"
DB_DATABASE_NAME: "immich"
DB_PORT: "5432"
GOOGLE_MAPS_API_KEY: "your-google-maps-api-key"
GEMINI_API_KEY: "your-gemini-api-key"
```

### Prerequisites

Before using this addon, ensure you have:

1. **Immich server running** - This addon requires a working Immich installation
2. **Database access** - You need direct access to your Immich database
3. **Immich API key** - Generate an API key from your Immich admin panel

### Getting API Keys

**Immich API Key:**
1. Open your Immich web interface
2. Go to **Administration** > **API Keys**
3. Click **Create API Key**
4. Copy the generated key

**Google Maps API Key** (optional):
1. Visit the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Maps JavaScript API
4. Create credentials (API key)

**Google Gemini API Key** (optional):
1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key for Gemini

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Configure all required database and API settings.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI to start using the power tools.

## Support

Create an issue on github, or ask on the [home assistant community forum](https://community.home-assistant.io/)

For more information about Immich Power Tools, visit: https://github.com/varun-raj/immich-power-tools

[repository]: https://github.com/alexbelgium/hassio-addons