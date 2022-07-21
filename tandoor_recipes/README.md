# Hass.io Add-ons: Tandoor recipes

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftandoor_recipes%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftandoor_recipes%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ftandoor_recipes%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

## About

[Tandoor recipes](https://github.com/TandoorRecipes/recipes) is meant for people with a collection of recipes they want to share with family and friends or simply store them in a nicely organized way. A basic permission system exists but this application is not meant to be run as a public page.

## Configuration

Please check Tandoor Recipes documentation : https://docs.tandoor.dev/install/docker/

```yaml
    "SECRET_KEY": "str",
    "DB_TYPE": "list(sqlite|postgresql_external|mariadb_addon)" # Mariadb is automatically configured is the addon is installed, sqlite does not need configuration
    "ALLOWED_HOSTS": "str?",
    "POSTGRES_HOST": "str?", # Needed for postgresql_external
    "POSTGRES_PORT": "str?", # Needed for postgresql_external
    "POSTGRES_USER": "str?", # Needed for postgresql_external
    "POSTGRES_PASSWORD": "str?", # Needed for postgresql_external
    "POSTGRES_DB": "str?" # Needed for postgresql_external
```

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Support

If you have in issue with your installation, please be sure to checkout github.

## Screenshot

![image](https://github.com/TandoorRecipes/recipes/raw/develop/docs/preview.png)

[repository]: https://github.com/alexbelgium/hassio-addons
