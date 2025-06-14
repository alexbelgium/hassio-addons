# Home Assistant Add-on: TeslaMate

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fteslamate%2Fconfig.json)
![Ingress](https://img.shields.io/badge/-INGRESS-success)
![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]
![Supports armv7 Architecture][armv7-shield]

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate-PayPal-blue.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg

[TeslaMate](https://github.com/teslamate-org/teslamate) is a powerful data logger for Tesla vehicles.

## About

TeslaMate is a sophisticated self-hosted data logger for your Tesla vehicles. It records your vehicles' data and provides a beautiful web interface to analyze all the collected data.

![TeslaMate screenshot](https://raw.githubusercontent.com/teslamate-org/teslamate/main/website/static/screenshots/drive.png)

## Features

- Automatic data collection from your Tesla vehicle
- Beautiful web interface to analyze the collected data
- Geo-fencing capabilities
- Sleep mode detection
- Integrated MQTT support
- Efficiency and degradation statistics
- Charging history and statistics
- Support for multiple vehicles
- Programmable API

## Installation

1. Click the Home Assistant My button below to add the TeslaMate repository to your Home Assistant instance:

   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https://github.com/alexbelgium/hassio-addons)

2. Install the TeslaMate add-on.
3. Configure your database settings.
4. Start the add-on.
5. Click on the "OPEN WEB UI" button to open TeslaMate.

## Configuration

Example add-on configuration:

```yaml
database_host: core-postgres
database_name: teslamate
database_user: teslamate
database_pass: mysecretpassword
mqtt_host: core-mosquitto
mqtt_username: mqtt_user
mqtt_password: mqtt_password
timezone: Europe/Brussels
language: en
log_level: info
disable_mqtt: false
```

### Option: `database_host`

The hostname of your PostgreSQL server.

### Option: `database_name`

The name of the PostgreSQL database.

### Option: `database_user`

The username for the PostgreSQL database.

### Option: `database_pass`

The password for the PostgreSQL database.

### Option: `mqtt_host`

The hostname of your MQTT broker.

### Option: `mqtt_username`

The username for the MQTT broker.

### Option: `mqtt_password`

The password for the MQTT broker.

### Option: `timezone`

The timezone for TeslaMate.

### Option: `language`

The language for the TeslaMate interface.

### Option: `log_level`

The log level for TeslaMate (debug/info/warning/error).

### Option: `disable_mqtt`

Disable MQTT functionality.

### Option: `disable_sleep_mode`

Disable sleep mode detection.

### Option: `enable_send_push_notifications`

Enable push notifications.

### Option: `disable_api_access`

Disable API access.

## Support

Got questions?

You have several options to get them answered:

- The [Home Assistant Discord Chat Server][discord].
- The Home Assistant [Community Forum][forum].
- Join the [Reddit subreddit][reddit] in [/r/homeassistant][reddit]

[discord]: https://discord.gg/c5DvZ4e
[forum]: https://community.home-assistant.io
[reddit]: https://reddit.com/r/homeassistant
[release-shield]: https://img.shields.io/badge/version-1.28.1-blue.svg
[project-stage-shield]: https://img.shields.io/badge/project%20stage-production%20ready-brightgreen.svg
[maintenance-shield]: https://img.shields.io/maintenance/yes/2025.svg
