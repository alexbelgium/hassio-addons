## &#9888; Open Request : [[Request] Mealie v1 (opened 2022-06-09)](https://github.com/alexbelgium/hassio-addons/issues/356) by [@Tommatheussen](https://github.com/Tommatheussen)
## Breaking change : no database migration with v1.0. Please backup your database from within Mealie before upgrading, then restore the database after upgrading. Infos here : https://hay-kot.github.io/mealie/documentation/getting-started/updating/. Something to note however about the database migration is that only the recipe data gets migrated. Not user data or other settings, and the favorite recipes are also no longer listed as such so they need to be selected again (Thanks @SeeThisIsMe)

Thanks for your help! Now I'll get a regular scheduled recipe backup sorted out ;)

# Hass.io Add-ons: Mealie

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://github.com/alexbelgium/hassio-addons/workflows/Lint%20Code%20Base/badge.svg)](https://github.com/marketplace/actions/super-linter)
[![Builder](https://github.com/alexbelgium/hassio-addons/workflows/Builder/badge.svg)](https://github.com/alexbelgium/hassio-addons/actions/workflows/builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

Warning : armv7 only supported up to version 0.4.3! It won't be updated with later versions

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family.
This addon for mealie 1.0 is based on the combined [docker image](https://hub.docker.com/r/hendrix04/mealie-combined) from hendrix04.
This addon is based on the [docker image](https://hub.docker.com/r/hkotel/mealie) from hay-kot.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration

- Start the addon. Wait a while and check the log for any errors.
- Open yourdomain.com:9925 (where ":9925" is the port configured in the addon).
- Default
  - Username: changeme@email.com
  - Password: MyPassword

```yaml
ssl: true/false
certfile: fullchain.pem #ssl certificate, must be located in /ssl
keyfile: privkey.pem #sslkeyfile, must be located in /ssl
```

## Support

If you have in issue with your installation, please be sure to checkout github.

[repository]: https://github.com/alexbelgium/hassio-addons
