## &#9888; Open Request : [✨ [REQUEST] Mealie Ingress Support (opened 2023-11-05)](https://github.com/alexbelgium/hassio-addons/issues/1061) by [@minmaxat](https://github.com/minmaxat)
# Hass.io Add-ons: Mealie

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

Warning : armv7 only supported up to version 0.4.3! It won't be updated with later versions

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/mealie/stats.png)

## About

Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family.
This addon for mealie 1.0 is based on the combined [docker image](https://hub.docker.com/r/hendrix04/mealie-combined) from hendrix04.
This addon is based on the [docker image](https://hub.docker.com/r/hkotel/mealie) from hay-kot.

## Configuration

- Start the addon. Wait a while and check the log for any errors.
- Open yourdomain.com:9925 (where ":9925" is the port configured in the addon).
- Default
  - Username: changeme@email.com
  - Password: MyPassword

Options can be configured through two ways :

- Addon options

```yaml
    "BASE_URL": Optional, external base url
    "PGID": user ID
    "PUID": "group ID
    "certfile": fullchain.pem #ssl certificate, must be located in /ssl
    "keyfile": privkey.pem #sslkeyfile, must be located in /ssl
    "ssl": ssl: true/false
    "ALLOW_SIGNUP": Allow signup of users
```

- Config.yaml
  Additional options can be configured using the config.yaml file found in /config/addons_config/mealie/config.yaml

The complete list of options can be seen here : https://nightly.mealie.io/documentation/getting-started/installation/backend-config/

## Integration with HA

### Detailed infos (Thanks @michelangelonz)

Create a restful sensor

```yaml
sensor:
  - platform: rest
    resource: "http://###.###.#.#:9090/api/groups/mealplans/today"
    method: GET
    name: Mealie todays meal
    headers:
      Authorization: Bearer <put  auth here>
    value_template: "{{ value_json.value }}"
    json_attributes_path: $..recipe
    json_attributes:
      - name
      - id
      - totalTime
      - prepTime
      - performTime
      - description
      - slug
```

Create template sensors from attributes

```yaml
- name: TodaysDinner
  unique_id: sensor.TodaysDinner
  state: "{{ state_attr('sensor.mealie_todays_meal', 'name') }}"
- name: TodaysDinnerDescription
  unique_id: sensor.DinnerDescription
  state: "{{ state_attr('sensor.mealie_todays_meal', 'description') }}"
- name: TodaysDinnerSlug
  unique_id: sensor.DinnerSlug
  state: "{{ state_attr('sensor.mealie_todays_meal', 'slug') }}"
- name: TodaysDinnerID
  unique_id: sensor.DinnerID
  state: "{{ state_attr('sensor.mealie_todays_meal', 'id') }}"
```

Add a generic camera for image
http://###.###.#.#:9090/api/media/recipes/{{ state_attr('sensor.mealie_todays_meal', 'id') }}/images/min-original.webp

### Global infos

Read here : https://hay-kot.github.io/mealie/documentation/community-guide/home-assistant/

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

[repository]: https://github.com/alexbelgium/hassio-addons
