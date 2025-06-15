# Home Assistant Add-on: Uptime Kuma

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fuptime-kuma%2Fconfig.json)
![Ingress](https://img.shields.io/badge/-INGRESS-success)
![AMD64][amd64-shield]
![ARM64][arm64-shield]
![ARMV7][armv7-shield]
![Last update][update-badge]

[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg?style=flat
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg?style=flat
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg?style=flat
[update-badge]: https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update
[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white
[lint-badge]: https://github.com/alexbelgium/hassio-addons/workflows/Weekly%20Linting/badge.svg
[build-badge]: https://github.com/alexbelgium/hassio-addons/workflows/Build/badge.svg

## About

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a modern self-hosted monitoring tool inspired by "Uptime Robot".

This add-on is based on the upstream project: [louislam/uptime-kuma](https://github.com/louislam/uptime-kuma).

## Features

- 🔍 Monitor uptime for HTTP(s) / TCP / HTTP(s) Keyword / Ping / DNS Record / Push / Steam Game Server / Docker Containers
- 📊 Beautiful status pages with public or private availability
- 📱 Notifications via 90+ notification services
- 🔒 Powerful SSL/TLS monitoring with certificate expiry notifications
- 🌍 Multi-language support
- 🎯 Ping Chart for each service
- 🔐 Two-Factor Authentication (2FA)
- 🏃 Low resource usage and efficient monitoring
- ⚡ Install with 1-click
- 🔍 Clean and modern interface

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fuptime-kuma%2Fconfig.json)
![Ingress](https://img.shields.io/badge/-INGRESS-success)
![AMD64][amd64-shield]
![ARM64][arm64-shield]
![ARMV7][armv7-shield]
![Last update][update-badge]

[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg?style=flat
[arm64-shield]: https://img.shields.io/badge/arm64-yes-green.svg?style=flat
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg?style=flat
[update-badge]: https://img.shields.io/github/last-commit/alexbelgium/hassio-addons?label=last%20update
[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white
[lint-badge]: https://github.com/alexbelgium/hassio-addons/workflows/Weekly%20Linting/badge.svg
[build-badge]: https://github.com/alexbelgium/hassio-addons/workflows/Build/badge.svg

## Installation

1. Click the Home Assistant My button below to open the add-on on your Home Assistant instance:

   [![Add repository on my Home Assistant][repository-badge]][repository-url]

2. Click on the "INSTALL" button to install the add-on
3. Start the "Uptime Kuma" add-on
4. Click on the "OPEN WEB UI" button to open Uptime Kuma

## Configuration

Example add-on configuration:

```yaml
ssl: false
local_storage: true
```

### Option: `ssl`

Enables/Disables SSL (HTTPS) on the web interface.

### Option: `local_storage`

Enables local storage by creating a folder named `uptime-kuma` in the `addons_config` directory.

## Support

Got questions?

You have several ways to get them answered:

- The [Home Assistant Discord Chat Server][discord].
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

You could also [open an issue here][issue].

[![Add repository on my Home Assistant][repository-badge]][repository-url]

[discord]: https://discord.gg/c5DvZ4e
[forum]: https://community.home-assistant.io
[issue]: https://github.com/alexbelgium/hassio-addons/issues
[reddit]: https://reddit.com/r/homeassistant
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons
