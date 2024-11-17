# Home assistant add-on: Scrutiny

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fscrutiny%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fscrutiny%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fscrutiny%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/scrutiny/stats.png)

## About

---

[Scrutiny](https://github.com/AnalogJ/scrutiny) is a Hard Drive Health Dashboard & Monitoring solution, merging manufacturer provided S.M.A.R.T metrics with real-world failure rates. This addon is based on the [docker image](https://hub.docker.com/r/linuxserver/scrutiny) from [linuxserver.io](https://www.linuxserver.io/).

Features :

- SMART monitoring
- Automatic addition of local drives
- Hourly updates
- Ingress
- Automatic upstream updates

## Configuration

---

Webui can be found at <http://homeassistant:8080>, or through Ingress.
It automatically mounts all local drives.

Enable full access only if you are encountering issues. SMART access should work without full access in all other scenarios.

```yaml
Updates: Hourly, Daily, Weekly
Updates_custom_time : if you select "Custom" as "Updates" variable, you can define specific updates in natural language in the "Updates_custom_time" field. Example : select "Custom" as "Updates", then type a custom intervals like "5m", "2h", "1w", or "2mo" to have an update every 5 minutes, or every 2 hours, or evey week, or every 2 months
TZ: timezone
Mode: Collector+WebUI or Collector only
```

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. [Add my Hass.io add-ons repository][repository] to your home assistant instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI (Ingress based) and adapt the software options

# Integration in home assistant

---

Integration with HA can be done with the [rest platform](https://www.home-assistant.io/integrations/rest) in configuration.yaml.

Two types of api endpoints are available:

- Summary data : http://YOURIP:ADDONPORT/api/summary
- Detailed data : http://YOURIP:ADDONPORT/api/device/WWN/details

For the detailed data, wmn can be found for each hdd within the scrutiny app. For example: http://192.168.178.23:8086/api/device/0x50014ee606c14537/details

Example to get data from the first hdd.

```yaml
rest:
  - verify_ssl: false
    scan_interval: 60
    resource: http://192.168.178.4:8086/api/device/0x57c35481f82a7a9c/details
    sensor:
      - name: "HDD - WWN"
        value_template: "{{ value_json.data.smart_results[0].device_wwn }}"
      - name: "HDD - Last Update"
        value_template: "{{ value_json.data.smart_results[0].date }}"
        device_class: timestamp
      - name: "HDD - Temperature"
        value_template: "{{ value_json.data.smart_results[0].temp }}"
        device_class: temperature
        unit_of_measurement: "°C"
        state_class: measurement
      - name: "HDD - Power Cycles"
        value_template: "{{ value_json.data.smart_results[0].power_cycle_count }}"
      - name: "HDD - Power Hours"
        value_template: "{{ value_json.data.smart_results[0].power_on_hours }}"
      - name: "HDD - Protocol"
        value_template: "{{ value_json.data.smart_results[0].device_protocol }}"
      - name: "HDD - Reallocated Sectors Count"
        value_template: '{{ value_json.data.smart_results[0].attrs["5"].raw_value }}'
      - name: "HDD - Reallocation Event Count"
        value_template: '{{ value_json.data.smart_results[0].attrs["196"].raw_value }}'
      - name: "HDD - Current Pending Sector Count"
        value_template: '{{ value_json.data.smart_results[0].attrs["197"].raw_value }}'
      - name: "HDD - (Offline) Uncorrectable Sector Count"
        value_template: '{{ value_json.data.smart_results[0].attrs["198"].raw_value }}'
    binary_sensor:
      - name: "HDD - SMART Status"
        value_template: "{{ 1 if value_json.data.smart_results[0].Status in [1, 2] else 0 }}"
        device_class: problem
```

## Illustration

---

![Illustration](https://github.com/AnalogJ/scrutiny/raw/master/docs/dashboard.png)

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-scrutiny-smart-dashboard/295747)

https://github.com/alexbelgium/hassio-addons

[repository]: https://github.com/alexbelgium/hassio-addons
