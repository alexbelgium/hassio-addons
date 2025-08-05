# Home assistant add-on: collabora

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)

## About

Collabora Online is a collaborative office suite based on LibreOffice technology.

## Installation

1. Click the Home Assistant My add-on store button below.
1. Click the "Install" button to install the add-on.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

<a href="https://my.home-assistant.io/redirect/supervisor_addon/?addon=local_collabora" target="_blank"><img src="https://my.home-assistant.io/badges/supervisor_addon.svg" alt="Open your Home Assistant instance and show the add add-on repository dialog"/></a>

## Configuration

Webui can be found at <http://homeassistant:9980> or through Ingress.

### Options

Configure the add-on to allow access from your Nextcloud instance:

- `domain`: Regex matching the Nextcloud host (for example `cloud\\.example\\.com`).
- `username` and `password`: Optional credentials for the Collabora admin console.

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Support

Create an issue on GitHub

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white
