## &#9888; Open Request : [✨ [REQUEST] Birdnet-Go (opened 2024-05-07)](https://github.com/alexbelgium/hassio-addons/issues/1385) by [@matthew73210](https://github.com/matthew73210)
## &#9888; Open Issue : [🐛 [Birdnet-go] Queue is full! (opened 2024-06-24)](https://github.com/alexbelgium/hassio-addons/issues/1449) by [@thor0215](https://github.com/thor0215)
# Home assistant add-on: Birdnet-Go

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-go%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-go%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fbirdnet-go%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/birdnet-go/stats.png)

## About

---

[BirdNET-Go](https://github.com/tphakala/birdnet-go/tree/main) is an AI solution for continuous avian monitoring and identification developed by @tphakala

This addon is based on their docker image.

## Configuration

Install, then start the addon a first time. Webui can be found at <http://homeassistant:8080>.
You'll need a microphone : either use one connected to HA or the audio stream of a rstp camera.

The audio clips folder can be stored on an external or SMB drive by mounting it from the addon options, then specifying the path instead of "clips/". For example, "/mnt/NAS/Birdnet/"

Options can be configured through three ways :

- Addon options

```yaml
ALSA_CARD : number of the card (0 or 1 usually), see https://github.com/tphakala/birdnet-go/blob/main/doc/installation.md#deciding-alsa_card-value
TZ: Etc/UTC specify a timezone to use, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
COMMAND : realtime --rtsp url # allows to provide arguments to birdnet-go
```

- Config.yaml
Additional variables can be configured using the config.yaml file found in /config/db21ed7f_birdnet-go/config.yaml using the Filebrowser addon

- Config_env.yaml
Additional environment variables can be configured there

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Integration with HA

Not yet available

### Birdnet-Go Events Sensor

Your Home Assistant must be setup with MQTT and Birdnet-Go MQTT integration must be enabled. Modify the Birdnet-Go config.yaml file to enable MQTT. If you are using the Mosquitto Broker addon, you will see a log message during the Birdnet-Go startup showing the internal MQTT server details needed for configuration similar to below.
```
Birdnet-Go log snipped showing MQTT details:
/etc/cont-init.d/33-mqtt.sh: executing
---
MQTT addon is active on your system! Add the MQTT details below to the Birdnet-go config.yaml :
MQTT user : addons
MQTT password : Ri5ahV1aipeiw0aelerooteixai5ohtoeNg6oo3mo0thi5te0phiezuge4Phoore
MQTT broker : tcp://core-mosquitto:1883
---

Edit this section of config.yaml found in addon_configs/db21ed7f_birdnet-go/:
    mqtt:
        enabled: true # true to enable MQTT
        broker: tcp://core-mosquitto:1883 # MQTT (tcp://host:port)
        topic: birdnet # MQTT topic
        username: addons # MQTT username
        password: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx # MQTT password
```

Then create a new template sensor using the configuration below.

```
- trigger:
    - platform: mqtt
      topic: "birdnet"
    - platform: time
      at: "00:00:00"
      id: reset
  sensor:
    - unique_id: c893533c-3c06-4ebe-a5bb-da833da0a947
      name: BirdNET-Go Events
      state: >
        {% if trigger.id == 'reset' %}
          {{ now() }}
        {% else %}
          {{ today_at(trigger.payload_json.Time) }}
        {% endif %}
      attributes:
        bird_events: >
          {% if trigger.id == 'reset' %}
            {{ [] }}
          {% else %}
            {% set time = trigger.payload_json.Time %}
            {% set name = trigger.payload_json.CommonName %}
            {% set confidence = trigger.payload_json.Confidence|round(2) * 100 ~ '%' %}
            {% set current = this.attributes.get('bird_events', []) %}
            {% set new = dict(time=time, name=name, confidence=confidence) %}
            {{ current + [new] }}
          {% endif %}
```

### Birdnet-Go Dashboard Cards

There are two versions listed below. One will link the Bird Name to Wikipedia the other one will link to All About Birds. You will need to modify the Confidence link to match your Home Assistant setup.

![Birdnet-go Markdown Card](https://github.com/thor0215/hassio-addons/blob/master/birdnet-go/images/ha_birdnet_markdown_card.png?raw=true)

```
type: markdown
title: Birdnet (Wikipedia)
content: >-
  Time|&nbsp;&nbsp;Bird Name|Number Today| &nbsp;&nbsp;&nbsp;Max
  [Confidence](http://ip_address_of_HA:8080/)

  :---|:---|:---:|:---:

  {%- set t = now() %}

  {%- set bird_list = state_attr('sensor.birdnet_go_events','bird_events') |
  sort(attribute='time', reverse=true) | map(attribute='name') | unique | list
  %}

  {%- set bird_objects = state_attr('sensor.birdnet_go_events','bird_events') |
  sort(attribute='time', reverse=true) %}

  {%- for thisbird in bird_list or [] %}

  {%- set ubird = ((bird_objects | selectattr("name", "equalto", thisbird)) |
  list)[0] %}

  {%- set ubird_count = ((bird_objects | selectattr("name", "equalto",
  thisbird)) | list) | length %}

  {%- set ubird_max_confidence = ((bird_objects | selectattr("name", "equalto",
  thisbird)) | map(attribute='confidence') | map('replace', '%', '') |
  map('float') | max | round(0)) %}

  {%- if ubird_max_confidence > 70 %}

  {{ubird.time}}
  |&nbsp;&nbsp;[{{ubird.name}}](https://en.wikipedia.org/wiki/{{ubird.name |
  replace(' ', '_')}}) | {{ubird_count}} | {{ ubird_max_confidence }} %

  {%- endif %}

  {%- endfor %}
card_mod:
  style:
    $: |
      .card-header {
        display: flex !important;
        align-items: center;
      }
      .card-header:before {
        content: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADQAAAA0CAYAAADFeBvrAAAAAXNSR0IArs4c6QAABIRJREFUaEO9Wo1Z3DAMlTeBSXpMAkwCTAI3CXSSu06SRrGdyLZkPfuAfB+lvZOl9/RrOw20PYGIlvhX80FkKm34Esc2+HWITOaeBNbEzMqX6Kbf4sV2EqHvMDmnY26VFoOoaT5Cc3E1EhygpYhoqwYJHV7wKi7mGQAUccyAroPQDbbnlw44CCF+1FCSrjxRAb1L5X0Fdf+emADqplyWDUSntWm9ENEzEY2Rmg9h6RRAj0tIaGQyr+nn7JKqjff6ezMDQeRKIfcJlXozIebIxCIpwPbvTaJqsDrYPlPa5aAxqTekUCDOiCJAZiTlPonoVOnskiqI/DArUesA7ShSZKzAB0cKtoQK6sMWdt2FiO4aW3H5D5M6MHpo1ZQLFGipOk8guixMyNb4SoHe3E17x/subI9NM1j7odZqqN5L84z6QDMmywmcnAHGjHPYhEC0OJvTSsX7auwJAHvvzqjDDU+B6M8Sm01O56+1+fDP3/QbMCli2+VdtqmXtVi4VpDHI8UEeK6dnDnG0X4jClf/ABphpTOeu3dmWY4OR2l/nCS4D0TXUvO2Qg5okbKmNk7BByTqiRDi8E2Gvcp1lD3h1b8GBE3bGpRKKpVNEeS9ywENhI3orduOmQTikslgjHyBRoNBKNFrWbqglHgzKS5ypKHk5bymnHmBrrQQ12b3Gdn6NGmHVZP0iumorIprhcnzU9Xa9hmPBf7ePL6MEtLTDsxX1bXHWgYpI1DUbFW5TIo3xrxmJ8eqZgg1nlNi4GWGdqLgo8gDLTtAPiFf+u16s5xae1w3TijQHS1bt7P2de1NXGZsRfL4PM8djs4j0VLs7pWmwZE6r8earyVFapzQnt/hNXtvKuPEoon1RVRkOkCEDIMXitG6/Um3rKyoo45TiutG7BVbZBAho5spRauVxpj/O9L+HNrvthstMIhtLtXSSJOALRze9PaH+w7mlpThxnBRitWffmOpysXPM8p99pSDPVYKzuwcKlCe5e37MjrakvSZWkOeidTv39dW2d3OIHpcl8fdwYeuqz1bV4RACIE+aQkn9IzigzZd3mkE4gWUMBAJZX0Yn/0ojol36PQVcHvm6Aw9HDPc0Vtkmru5IYOgsN+iDUVlhPrWjEuSKt6d7hV9J/9UDcodtzECc1K10ThqqB+plsxAZAdEVTKdplZ6xH9pvKnyI7OrHYBeQvkgCs9H7pd6IK29ti3wRTJmGhmmIASblXyuyYe6gmajBjCnzqGktRMZHLFsogItdzC+d4sbTeHd/bXsmIldjUaItzO8A6jfNHRbRmF/+0eD6CsQnddLxe4RGuyCZo+zCD0KQkywPcz1/0NFvhjh3/+0ewA0nUYJboTA6GrE5F30dfSlsrRbYwAxNTOD7+ramh/XBjjyO5Xa9HtNAY9dpiOLG4074ApEJFMsCEE+rISgNQiiWx0g59AwqJ/I0+9wlL9TgFyrDkO9cwP6irRN8oKs5/w95UpBbxkArBLJbwrgYTaZBWZTmKFktWFPl/W93sv62vS2bc5h5WpR0+8x6OzYhpYqOP8DUq58TJ+vR7cAAAAASUVORK5CYII=");
        height: 52px;
        width: 42px;
        margin-top: 0px;
        padding-left: 0px;
        padding-right: 18px;
      }

```

## Common issues

Not yet available

## Support

Create an issue on github

---

![illustration](https://raw.githubusercontent.com/tphakala/birdnet-go/main/doc/BirdNET-Go-dashboard.webp)
