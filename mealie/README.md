## &#9888; Open Issue : [🐛 [Mealie] After updating Mealie to version 3.0.0 ingress not working (opened 2025-07-12)](https://github.com/alexbelgium/hassio-addons/issues/1948) by [@djtail](https://github.com/djtail)
## &#9888; Open Issue : [🐛 [Mealie] Recipe import from websites no longer working after 3.x upgrade (opened 2025-07-16)](https://github.com/alexbelgium/hassio-addons/issues/1962) by [@donverse](https://github.com/donverse)
## &#9888; Open Issue : [🐛  Mealie unable to login after upgrade to 3.x (opened 2025-07-16)](https://github.com/alexbelgium/hassio-addons/issues/1964) by [@motionist](https://github.com/motionist)
## &#9888; Open Issue : [🐛 [Mealie] Meal Planner view wont show most custom date ranges (opened 2025-07-25)](https://github.com/alexbelgium/hassio-addons/issues/1979) by [@jack5mikemotown](https://github.com/jack5mikemotown)
# Hass.io Add-ons: Mealie

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmealie%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

Warning : armv7 only supported up to version 0.4.3! It won't be updated with later versions

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/mealie/stats.png)

## About

Mealie is a self hosted recipe manager and meal planner with a RestAPI backend and a reactive frontend application built in Vue for a pleasant user experience for the whole family.
This addon for mealie 1.0 is based on the combined [docker image](https://hub.docker.com/r/hendrix04/mealie-combined) from hendrix04.
This addon is based on the [docker image](https://hub.docker.com/r/hkotel/mealie) from hay-kot.

## Configuration

Webui can be found at <http://homeassistant:PORT> or through the sidebar using Ingress.
Configurations can be done through the app webUI, except for the following options.

- Start the addon. Wait a while and check the log for any errors.
- Default credentials:
  - Username: changeme@example.com
  - Password: MyPassword

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `PGID` | int | `1000` | Group ID for file permissions |
| `PUID` | int | `1000` | User ID for file permissions |
| `ssl` | bool | `false` | Enable HTTPS for the web interface |
| `certfile` | str | `fullchain.pem` | SSL certificate file (must be in /ssl) |
| `keyfile` | str | `privkey.pem` | SSL key file (must be in /ssl) |
| `BASE_URL` | str | | Optional external base URL |
| `DATA_DIR` | str | `/config` | Data directory path |
| `ALLOW_SIGNUP` | bool | `true` | Allow new user signup |

### Example Configuration

```yaml
PGID: 1000
PUID: 1000
ssl: false
certfile: "fullchain.pem"
keyfile: "privkey.pem"
BASE_URL: "https://mealie.mydomain.com"
DATA_DIR: "/config"
ALLOW_SIGNUP: false
```

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

You can add environment variables by creating `/homeassistant/addons_config/xxx-mealie/config.yaml`.

The complete list of options can be found here: https://nightly.mealie.io/documentation/getting-started/installation/backend-config/

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
