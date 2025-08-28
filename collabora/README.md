# Home assistant add-on: Collabora

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fcollabora%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/collabora/stats.png)

## About

Collabora Online is a collaborative office suite based on LibreOffice technology.

## Installation

---

1. Add my add-ons repository to your Home Assistant instance or click the My link below.
1. Install the add-on.
1. Start the add-on.
1. Check the add-on logs to verify successful startup.

<a href="https://my.home-assistant.io/redirect/supervisor_addon/?addon=local_collabora" target="_blank"><img src="https://my.home-assistant.io/badges/supervisor_addon.svg" alt="Open your Home Assistant instance and show the add add-on repository dialog"/></a>

## Configuration

---

Webui can be found at `http://homeassistant:9980` or through Ingress.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `aliasgroup1` | str | | Nextcloud external domain with escaped dots using two \ (e.g. `nextcloud_domain\\.com`) |
| `domain1` | str | | Collabora external domain with escaped dots using two \ (e.g. `code_domain\\.com`) |
| `extra_params` | str | | Extra parameters passed to the Collabora start script |
| `username` | str | | Username for the Collabora admin console |
| `password` | str | | Password for the Collabora admin console |
| `dictionaries` | str | | Space-separated list of dictionary languages to install |

### Example configuration

```yaml
aliasgroup1: nextcloud_domain\.com
domain1: code_domain\.com
extra_params: ""
username: admin
password: changeme
```

### Using Collabora with Nextcloud

1. Install the Collabora add-on and configure the options above.
1. Start the add-on and expose the Collabora server to an external domain.
1. Install and configure the Nextcloud add-on.
1. Inside Nextcloud, install the **Nextcloud Office** app.
1. In Nextcloud **Administration Settings → Office**, set the Collabora server URL to `https://yourdomain:9980` and enable **Disable certificate validation**.

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Support

Create an issue on GitHub

