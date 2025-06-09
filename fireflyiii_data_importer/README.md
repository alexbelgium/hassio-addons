# Home assistant add-on: Fireflyiii data importer

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_data_importer%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_data_importer%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffireflyiii_data_importer%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/fireflyiii_data_importer/stats.png)

## About

["Firefly III"](https://www.firefly-iii.org) is a (self-hosted) manager for your personal finances. It can help you keep track of your expenses and income, so you can spend less and save more. The data importer is built to help you import transactions into Firefly III. It is separated from Firefly III for security and maintenance reasons.

This addon is based on the docker image https://hub.docker.com/r/fireflyiii/data-importer

## Configuration

Read official documentation for information how to set the variables: https://docs.firefly-iii.org/data-importer.

Configurations can be added in the /addon_configs/xxx-fireflyiii_data_importer/configurations folder according to :https://docs.firefly-iii.org/data-importer/help/config/

An auto import can be made by adding files in /addon_configs/xxx-fireflyiii_data_importer/import_files according to : https://docs.firefly-iii.org/data-importer/usage/command_line/

Options can be configured through two ways :

- Addon options

```yaml
"CONFIG_LOCATION": location of the config.yaml # Sets the location of the config.yaml (see below)
"FIREFLY_III_ACCESS_TOKEN": required to access Firefly
"FIREFLY_III_CLIENT_ID": alternative way to access Firefly
"FIREFLY_III_URL": your url, either local (docker IP), or external (public IP)
"NORDIGEN_ID": your Nordigen Client ID
"NORDIGEN_KEY": your Nordigen Client Secret
"SPECTRE_APP_ID": your Spectre / Salt Edge Client ID
"SPECTRE_SECRET": your Spectre / Salt Edge Client secret
"Updates": hourly|daily|weekly # Sets an automatic upload of files set in /config/addons_config/fireflyiii_data_importer/import_files
"silent": true # suppresses debug messages
```

- Config.yaml (advanced usage)

Additional variables can be set as ENV variables by adding them in the config.yaml in the location defined in your addon options according to this guide : https://github.com/alexbelgium/hassio-addons/wiki/Add%E2%80%90ons-feature-:-add-env-variables

The complete list of ENV variables can be seen here : https://github.com/firefly-iii/data-importer/blob/main/.env.example

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
