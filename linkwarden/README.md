
# Home assistant add-on: Linkwarden

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/linkwarden/stats.png)

## About

[Linkwarden](https://linkwarden.app/) is a collaborative bookmark manager to collect, organize, and preserve webpages and articles. It allows teams and individuals to save, categorize, and manage bookmarks with features like tags, collections, and full-text search capabilities.

This addon is based on the [official Linkwarden Docker image](https://github.com/linkwarden/linkwarden).

## Configuration

Webui can be found at `<your-ip>:3000` or through the sidebar using Ingress.
You'll need to create a new user account at startup.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `NEXTAUTH_SECRET` | str | **Required** | Secret key for NextAuth.js authentication (must be filled at start) |
| `NEXTAUTH_URL` | str | | Custom NextAuth URL (optional, only if Linkwarden is kept externally) |
| `NEXT_PUBLIC_DISABLE_REGISTRATION` | bool | `false` | Disable new user registration |
| `NEXT_PUBLIC_CREDENTIALS_ENABLED` | bool | `true` | Enable username/password login |
| `STORAGE_FOLDER` | str | `/config/library` | Directory for storing data files |
| `DATABASE_URL` | str | | External PostgreSQL database URL (leave blank for internal database) |
| `NEXT_PUBLIC_AUTHENTIK_ENABLED` | bool | `false` | Enable Authentik SSO integration |
| `AUTHENTIK_CUSTOM_NAME` | str | `Authentik` | Custom provider name for Authentik button |
| `AUTHENTIK_ISSUER` | str | | Authentik OpenID Configuration Issuer URL |
| `AUTHENTIK_CLIENT_ID` | str | | Client ID from Authentik Provider Overview |
| `AUTHENTIK_CLIENT_SECRET` | str | | Client Secret from Authentik Provider Overview |
| `NEXT_PUBLIC_OLLAMA_ENDPOINT_URL` | str | | Ollama endpoint URL for AI features |
| `OLLAMA_MODEL` | str | | Ollama model name for AI processing |

### Example Configuration

```yaml
NEXTAUTH_SECRET: "your-very-long-secret-key-here-at-least-32-characters"
NEXT_PUBLIC_DISABLE_REGISTRATION: false
NEXT_PUBLIC_CREDENTIALS_ENABLED: true
STORAGE_FOLDER: "/config/library"
DATABASE_URL: "postgresql://postgres:homeassistant@localhost:5432/linkwarden"
NEXT_PUBLIC_AUTHENTIK_ENABLED: false
AUTHENTIK_CUSTOM_NAME: "My Authentik"
AUTHENTIK_ISSUER: "https://authentik.my-domain.com/application/o/linkwarden"
AUTHENTIK_CLIENT_ID: "your-client-id"
AUTHENTIK_CLIENT_SECRET: "your-client-secret"
```

### Setup Steps

1. **First Time Setup**: After starting the addon, visit the web interface and create your first user account
2. **NEXTAUTH_SECRET**: Generate a secure random string (at least 32 characters) for the `NEXTAUTH_SECRET` option
3. **Database**: By default, Linkwarden uses an internal SQLite database. For production use, consider setting up PostgreSQL
4. **Authentication**: Configure Authentik integration if you want SSO capabilities
5. **Storage**: Bookmark data and files are stored in the configured `STORAGE_FOLDER`

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Authentik Integration

To integrate with Authentik for Single Sign-On:

1. Follow the instructions from the [Linkwarden documentation](https://docs.linkwarden.app/self-hosting/sso-oauth#authentik)
2. Set `NEXT_PUBLIC_AUTHENTIK_ENABLED` to `true`
3. Configure the Authentik-specific options with values from your Authentik Provider Overview
4. Note: Remove the trailing "/" from the `AUTHENTIK_ISSUER` URL

### Additional Configuration

For advanced configuration options, refer to the complete list of environment variables in the [Linkwarden documentation](https://docs.linkwarden.app/self-hosting/environment-variables).

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance. [![Add repository on my Home Assistant][repository-badge]][repository-url]
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the `NEXTAUTH_SECRET` option to a secure random string.
1. Configure other options as needed.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and create your first user account.

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-linkwarden/279247).

[repository]: https://github.com/alexbelgium/hassio-addons
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons

---

![illustration](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/linkwarden/illustration.png)
