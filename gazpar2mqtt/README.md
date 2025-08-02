# Home assistant add-on: gazpar2mqtt

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fgazpar2mqtt%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fgazpar2mqtt%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fgazpar2mqtt%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/gazpar2mqtt/stats.png)

## About

Python script to fetch GRDF data and publish data to a mqtt broker.
See its github for all informations : https://github.com/yukulehe/gazpar2mqtt

## Configuration

This addon fetches gas consumption data from GRDF (French gas utility) and publishes it to MQTT for Home Assistant integration.

### Setup Steps

1. Create a GRDF account at https://monespace.grdf.fr/
2. Configure your GRDF credentials in the config.yaml file
3. Set up MQTT connection details
4. Monitor data retrieval in the addon logs

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CONFIG_LOCATION` | str | `/config/gazpar2mqtt/config.yaml` | Path to configuration file |
| `TZ` | str | `Europe/Paris` | Timezone (e.g., `Europe/London`) |
| `mqtt_autodiscover` | bool | `true` | Enable MQTT autodiscovery |
| `verbose` | bool | `true` | Enable verbose logging |

### Example Configuration

```yaml
CONFIG_LOCATION: "/config/gazpar2mqtt/config.yaml"
TZ: "Europe/Paris"
mqtt_autodiscover: true
verbose: false
```

### Configuration File

The main configuration is done via `/config/gazpar2mqtt/config.yaml`. This file contains:
- GRDF account credentials
- MQTT broker settings
- Data retrieval intervals
- Device configurations

### Required Configuration in config.yaml

```yaml
# GRDF Credentials
grdf:
  username: "your-grdf-username"
  password: "your-grdf-password"

# MQTT Settings
mqtt:
  host: "homeassistant.local"
  port: 1883
  username: "mqtt-user"
  password: "mqtt-password"
  topic_prefix: "gazpar"

# Optional: Update frequency
update_frequency: 3600  # seconds
```

For complete configuration options, see: https://github.com/yukulehe/gazpar2mqtt

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

[repository]: https://github.com/alexbelgium/hassio-addons
