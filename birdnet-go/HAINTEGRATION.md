# BirdNET-Go Addon: Home Assistant Integration

BirdNET-Go can be integrated with Home Assistant using a MQTT Broker.

## MQTT Configuration

Your Home Assistant must be setup with MQTT and BirdNET-Go MQTT integration must be enabled. Modify the BirdNET-Go config.yaml file to enable MQTT. If you are using the Mosquitto Broker addon, you will see a log message during the BirdNET-Go startup showing the internal MQTT server details needed for configuration similar to below.

```text
BirdNET-Go log snipped showing MQTT details:
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

## BirdNET-Go MQTT Sensors

Add the [MQTT sensor](https://www.home-assistant.io/integrations/sensor.mqtt/) yaml configuration below to your Home Assistant configuration.yaml file. Reload the configuration and once BirdNET-Go publishes a new finding to MQTT the new BirdNET-Go sensors should show that latest finding data.

```yaml
mqtt:
  sensor:
    - name: "Birdnet-Go"
      state_topic: "birdnet"
      value_template: "{{ today_at(value_json.Time) }}"
      json_attributes_topic: "birdnet"
      json_attributes_template: "{{ value_json | tojson }}"
    - name: "Birdnet-Go Bird Image Url"
      state_topic: "birdnet"
      value_template: "{{ value_json.BirdImage.URL }}"
    - name: "Birdnet-Go Clip Name"
      state_topic: "birdnet"
      value_template: "{{ value_json.ClipName }}"
    - name: "Birdnet-Go Common Name"
      state_topic: "birdnet"
      value_template: "{{ value_json.CommonName }}"
    - name: "Birdnet-Go Confidence"
      state_topic: "birdnet"
      value_template: "{{ (value_json.Confidence | float * 100) | round(2) }}"
      unit_of_measurement: "%"
    - name: "Birdnet-Go Date"
      state_topic: "birdnet"
      value_template: "{{ value_json.Date }}"
    - name: "Birdnet-Go ProcessingTime"
      state_topic: "birdnet"
      value_template: "{{ (value_json.ProcessingTime | float / 1000000000 ) | round(4) }}"
      unit_of_measurement: "s"
    - name: "Birdnet-Go Scientific Name"
      state_topic: "birdnet"
      value_template: "{{ value_json.ScientificName }}"
    - name: "Birdnet-Go Sensitivity"
      state_topic: "birdnet"
      value_template: "{{ value_json.Sensitivity }}"
    - name: "Birdnet-Go Source"
      state_topic: "birdnet"
      value_template: "{{ value_json.Source }}"
    - name: "Birdnet-Go Species Code"
      state_topic: "birdnet"
      value_template: "{{ value_json.SpeciesCode }}"
    - name: "Birdnet-Go Threshold"
      state_topic: "birdnet"
      value_template: "{{ value_json.Threshold }}"
    - name: "Birdnet-Go Time"
      state_topic: "birdnet"
      value_template: "{{ today_at(value_json.Time) }}"
```

![BirdNET-go MQTT](./images/ha_birdnet_mqtt_sensor.png)

## BirdNET-Go Events Sensor[^1]

Then create a new template sensor using the configuration below.

```yaml
- trigger:
    - platform: mqtt
      topic: "birdnet"
      id: birdnet
    - platform: time
      at: "00:00:00"
      id: reset
  sensor:
    - unique_id: c893533c-3c06-4ebe-a5bb-da833da0a947
      name: BirdNET-Go Events
      state: >
        {% if trigger.id == 'reset' %}
          {{ now() }}
        {% elif trigger.id == 'birdnet' %}
          {{ today_at(trigger.payload_json.Time) }}
        {% endif %}
      attributes:
        bird_events: >
          {% if trigger.id == 'reset' %}
            {{ [] }}
          {% elif trigger.id == 'birdnet' %}
            {% set time = trigger.payload_json.Time %}
            {% set name = trigger.payload_json.CommonName %}
            {% set confidence = trigger.payload_json.Confidence|round(2) * 100 ~ '%' %}
            {% set current = this.attributes.get('bird_events', []) %}
            {% set new = dict(time=time, name=name, confidence=confidence) %}
            {{ current + [new] }}
          {% endif %}
```

### BirdNET-Go Dashboard Cards

There are two versions listed below. The first example will link the Bird Name to Wikipedia. The other example will link to All About Birds. You will need to modify the Confidence link to match your Home Assistant setup.

![BirdNET-go Markdown Card Wikipedia](./images/ha_birdnet_markdown_card_wikipedia.png)

```yaml
type: markdown
title: BirdNET (Wikipedia)
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
        content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='%23000' d='m23 11.5l-3.05-1.13c-.26-1.15-.91-1.81-.91-1.81a4.19 4.19 0 0 0-5.93 0l-1.48 1.48L5 3c-1 4 0 8 2.45 11.22L2 19.5s8.89 2 14.07-2.05c2.76-2.16 3.38-3.42 3.77-4.75zm-5.29.22c-.39.39-1.03.39-1.42 0a.996.996 0 0 1 0-1.41c.39-.39 1.03-.39 1.42 0s.39 1.02 0 1.41'/%3E%3C/svg%3E");
        height: 42px;
        width: 42px;
        margin-top: 0px;
        padding-left: 0px;
        padding-right: 14px;
      }
      @media (prefers-color-scheme: dark) {
        .card-header:before {
          content: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24'%3E%3Cpath fill='%23E1E1E1' d='m23 11.5l-3.05-1.13c-.26-1.15-.91-1.81-.91-1.81a4.19 4.19 0 0 0-5.93 0l-1.48 1.48L5 3c-1 4 0 8 2.45 11.22L2 19.5s8.89 2 14.07-2.05c2.76-2.16 3.38-3.42 3.77-4.75zm-5.29.22c-.39.39-1.03.39-1.42 0a.996.996 0 0 1 0-1.41c.39-.39 1.03-.39 1.42 0s.39 1.02 0 1.41'/%3E%3C/svg%3E");
          height: 42px;
          width: 42px;
          margin-top: 0px;
          padding-left: 0px;
          padding-right: 14px;
        }
      }
```

![BirdNET-go Markdown Card All About Birds](./images/ha_birdnet_markdown_card_all_about_birds.png)

```yaml
type: markdown
title: BirdNET (All About Birds)
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
  |&nbsp;&nbsp;[{{ubird.name}}](https://www.allaboutbirds.org/guide/{{ubird.name
  | replace(' ', '_')}}) | {{ubird_count}} | {{ ubird_max_confidence }} %

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
            content: url("data:image/svg+xml;base64,PHN2ZyBpZD0iTGF5ZXJfMSIgZGF0YS1uYW1lPSJMYXllciAxIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyMDYuODcgMTE2LjY2Ij48ZGVmcz48c3R5bGU+LmNscy0xe2ZpbGw6I2Y0ZTUwNTt9LmNscy0ye2ZpbGw6I2UzMWUyNjt9LmNscy0ze2ZpbGw6I2ZmZjt9PC9zdHlsZT48L2RlZnM+PHBhdGggZD0iTTIwNi4zNywxNi42OHMtMTYuNDQtNC4zNC0yMi43Ni00LjljMCwwLTI1LDEzLjUtMzIsMThhMTkuMTYsMTkuMTYsMCwwLDAtOC42NywxMy44OWwzNS43MS0yNi4zMmgyOEMyMDcuMzEsMTcuMzksMjA2LjM3LDE2LjY4LDIwNi4zNywxNi42OFoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMC42MykiLz48cGF0aCBkPSJNMTQ4LjU1LDI3LjMzYzcuMzItNC45LDMyLjYyLTE4LjczLDMyLjYyLTE4LjczbDAsMEEzMC42OSwzMC42OSwwLDAsMCwxNTktLjYzYTQ0LjIzLDQ0LjIzLDAsMCwwLTIwLjcxLDVIMGMwLDMuNzEsNS42LDYuNTYsMTIuMTQsNi41Nkg1Mi4zNkw4Ni42MiwzNS4xMlY3MS4zN2MwLDE1LjczLDguMjYsMjkuNDQsMjEuNzgsMzcuMzVTMTI4LjY4LDExNiwxMzguNjMsMTE2VjQ2Ljg3QzEzOC42Myw0MC43OCwxNDAuNDcsMzIuNzMsMTQ4LjU1LDI3LjMzWk0xNjcuODcsOGEyLjUxLDIuNTEsMCwxLDEtMi41MSwyLjUxQTIuNTEsMi41MSwwLDAsMSwxNjcuODcsOFptLTI5LjEzLDEzLDE1LjY5LTguNjgsNi44OS41N0wxMzguNzQsMjUuMzZaIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDAuNjMpIi8+PHBhdGggY2xhc3M9ImNscy0xIiBkPSJNNTIuMzYsMTAuOTFIMTEwYy0xMi44OSwwLTIzLjQsMTAuMzUtMjMuNCwyNC4yMVoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMC42MykiLz48cGF0aCBjbGFzcz0iY2xzLTIiIGQ9Ik0xNzgsMTAuMzNBMzEuNzEsMzEuNzEsMCwwLDAsMTU3Ljc4LDIuOVYtLjYxbDEuMjUsMEEzMC42MywzMC42MywwLDAsMSwxODEuMTcsOC42WiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMCAwLjYzKSIvPjxwYXRoIGNsYXNzPSJjbHMtMiIgZD0iTTE3OC42MywxNy4zOWwtMjUsMTguNDNzLS4yOS0yLjcsMy40Ny01Ljc0LDI2LjUtMTguMywyNi41LTE4LjNaIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDAuNjMpIi8+PHBhdGggY2xhc3M9ImNscy0zIiBkPSJNMTI4LjE0LDY0LjQ3VjUyLjE1YzAtNS4xOC0yLjExLTguNzctNi45My0xMi4xOEwxMDAuNzksMjUuNTRhMTQuMzIsMTQuMzIsMCwwLDAsMiwyMVoiIHRyYW5zZm9ybT0idHJhbnNsYXRlKDAgMC42MykiLz48cGF0aCBjbGFzcz0iY2xzLTMiIGQ9Ik0xMjguMTQsNjQuNDdWNTIuMTVjMC01LjE4LTIuMTEtOC43Ny02LjkzLTEyLjE4TDEwMC43OSwyNS41NGExNC4zMiwxNC4zMiwwLDAsMCwyLDIxWiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMCAwLjYzKSIvPjxwYXRoIGNsYXNzPSJjbHMtMyIgZD0iTTE1MS41OSwyOS44MmM3LTQuNTQsMzItMTgsMzItMThhMTYuMjQsMTYuMjQsMCwwLDAtMi40MS0zLjE1bDAsMHMtMjUuMywxMy44My0zMi42MiwxOC43My05LjU3LDEyLjE3LTkuODcsMThsLS4wNSwxLjUxLDQuMjktMy4xNkExOS4xNiwxOS4xNiwwLDAsMSwxNTEuNTksMjkuODJaIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDAuNjMpIi8+PHBhdGggY2xhc3M9ImNscy0zIiBkPSJNMTY3Ljg3LDhhMi41MSwyLjUxLDAsMSwxLTIuNTEsMi41MUEyLjUxLDIuNTEsMCwwLDEsMTY3Ljg3LDhaIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwIDAuNjMpIi8+PHBvbHlnb24gY2xhc3M9ImNscy0zIiBwb2ludHM9IjEzOC43NCAyMS41NyAxNTQuNDMgMTIuODkgMTYxLjMyIDEzLjQ1IDEzOC43NCAyNS45OCAxMzguNzQgMjEuNTciLz48L3N2Zz4=");
            height: 20px;
            width: 60px;
            margin-top: -10px;
            padding-left: 8px;
            padding-right: 18px;
      }
```

## Footnotes

[^1]: [Displaying Birdnet-go detections](https://community.home-assistant.io/t/displaying-birdnet-go-detections/713611/22)
