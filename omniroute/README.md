# Home Assistant add-on: OmniRoute

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons.

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomniroute%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomniroute%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fomniroute%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/omniroute/stats.png)

## About

[OmniRoute](https://github.com/cheaper-inference/OmniRoute) is an open-source, self-hosted AI inference gateway and proxy providing a unified OpenAI-compatible endpoint with intelligent fallbacks, load balancing, quota pooling, token compression, and routing across 350+ AI providers.

Key features:

- **Unified OpenAI-Compatible Gateway**: Drop-in replacement supporting `/v1/chat/completions`, native `/v1/responses`, vision, and tool calling.
- **Smart Fallbacks & Quotas**: Seamlessly retries alternative providers or fallback models in milliseconds on rate limits, errors, or quota exhaustion.
- **Context & Token Compression**: Built-in prompt and context compression engines to reduce token consumption and costs.
- **IDE & Assistant Ready**: Integrates seamlessly with Cursor, Claude Code, Cline, Roo Code, Aider, OpenCode, VS Code, and other developer tools.
- **Management Web UI**: Local dashboard to configure providers, API keys, fallback routes, quota tracking, and view real-time latency and call logs.
- **Home Assistant Ingress**: Direct access from the Home Assistant sidebar and Open Web UI without leaving your dashboard.

## Installation

1. Add this repository to your Home Assistant instance:
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
2. Install the **OmniRoute** add-on.
3. Configure the add-on options (e.g. set an `INITIAL_PASSWORD` for the admin web UI).
4. Start the add-on.
5. Click **Open Web UI** to access via Home Assistant Ingress, or browse to `http://<homeassistant-ip>:20128`.

## Configuration

Web UI is accessible via Home Assistant Ingress. Direct network access and API gateway are exposed on port **20128**.

### Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `INITIAL_PASSWORD` | str | `""` | Initial password for the administrator account on first setup. If empty, the default or auto-generated password is used. |
| `REQUIRE_API_KEY` | bool | `true` | When true, proxy requests to `/v1` require a valid API key configured in OmniRoute. |
| `OMNIROUTE_MEMORY_MB` | int | `1024` | Maximum Node.js V8 old space memory in megabytes for the inference gateway. |
| `TZ` | str | `Europe/Paris` | Timezone for the container. |
| `PUID` | int | `0` | User ID for file permissions in `/config`. |
| `PGID` | int | `0` | Group ID for file permissions in `/config`. |
| `env_vars` | list | `[]` | Arbitrary environment variables passed into OmniRoute. |

### Connecting Developer Tools

Configure your coding assistants to connect to the OmniRoute gateway:

- **Base URL**: `http://<homeassistant-ip>:20128/v1`
- **API Key**: The API key generated in the OmniRoute dashboard (under API Keys)
