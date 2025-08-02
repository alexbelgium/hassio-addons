# Home assistant add-on: Fireflyiii fints importer

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_fints_importer%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_fints_importer%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_fints_importer%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/fireflyiii_fints_importer/stats.png)

## About

["Firefly III"](https://www.firefly-iii.org) is a (self-hosted) manager for your personal finances. It can help you keep track of your expenses and income, so you can spend less and save more. This tool allows you to import transactions from your FinTS enabled bank into Firefly III. It comes with a web GUI that guides you through the process.

This addon is based on the docker image https://hub.docker.com/r/benkl/firefly-iii-fints-importer

## Configuration

Webui can be found at <http://homeassistant:3476>.

This tool allows you to import transactions from your FinTS enabled bank (primarily German banks) into Firefly III.

### Setup Steps

1. Ensure you have a running Firefly III instance
2. Access the web interface to configure bank connections
3. Set up import configurations for each bank account
4. Configure automatic import schedules if desired

For detailed setup documentation, see: https://github.com/bnw/firefly-iii-fints-importer

### Options

| Option | Type | Description |
|--------|------|-------------|
| `Updates` | list | Automatic import schedule (hourly, daily2, daily4, daily6, daily8, daily10, daily12, weekly) |
| `silent` | bool | Suppress debug messages |

### Example Configuration

```yaml
Updates: ["daily6"]  # Run daily at 6 AM
silent: false
```

### Automatic Import Schedule

The `Updates` option allows you to schedule automatic imports:

- `hourly`: Every hour
- `daily2`: Daily at 2:00 AM
- `daily4`: Daily at 4:00 AM
- `daily6`: Daily at 6:00 AM
- `daily8`: Daily at 8:00 AM
- `daily10`: Daily at 10:00 AM
- `daily12`: Daily at 12:00 PM
- `weekly`: Weekly (Sunday at 2:00 AM)

### Configuration Storage

Bank configurations and import settings are stored in:
`/config/addons_config/fireflyiii_fints_importer/`

For configuration file format, see: https://github.com/bnw/firefly-iii-fints-importer#storing-configurations

### FinTS Support

This importer supports German banks that use the FinTS (Financial Transaction Services) protocol. Most major German banks support FinTS for automated transaction retrieval.

## Installation

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Support

Create an issue on github

## Illustration

[repository]: https://github.com/alexbelgium/hassio-addons
