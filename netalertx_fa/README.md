# Home assistant add-on: NetAlertX Full Access

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetalertx_fa%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetalertx_fa%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fnetalertx_fa%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/netalertx_fa/stats.png)

## About

[NetAlertX](https://github.com/jokob-sk/NetAlertX) is a WIFI / LAN scanner, intruder, and presence detector that helps you monitor your network for new devices and potential security threats.

**This is the Full Access version** that provides additional privileges and network access capabilities compared to the standard NetAlertX addon.

Key features:
- Network device discovery and monitoring
- Presence detection for known devices
- Intrusion detection for unknown devices
- Web-based dashboard for network visualization
- MQTT integration for Home Assistant
- Network scanning with enhanced privileges

## Configuration

Webui can be found at `<your-ip>:20211` or through the sidebar using Ingress.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `TZ` | str | `Europe/Berlin` | Timezone (e.g., `Europe/London`) |
| `APP_CONF_OVERRIDE` | str | | Additional app configuration overrides |

### Example Configuration

```yaml
TZ: "Europe/London"
APP_CONF_OVERRIDE: "SCAN_SUBNETS=['192.168.1.0/24']"
```

### MQTT Integration

This addon supports MQTT integration and will automatically connect to your Home Assistant MQTT broker if available. NetAlertX can publish device presence information to MQTT topics for integration with Home Assistant automations.

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI to configure your network scanning preferences.

## Full Access vs Standard Version

This **Full Access** version provides:
- `full_access: true` - Complete system access
- `host_network: true` - Direct host network access
- Enhanced privileges (`SYS_ADMIN`, `NET_ADMIN`, `NET_RAW`)
- `udev: true` - Hardware device access

Use this version if you need enhanced network scanning capabilities or if the standard NetAlertX addon doesn't provide sufficient network access for your setup.

## Support

Create an issue on github, or ask on the [home assistant community forum](https://community.home-assistant.io/)

[repository]: https://github.com/alexbelgium/hassio-addons