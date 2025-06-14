# Home Assistant Add-on: TeslaMate ABRP

TeslaMate ABRP integration for Home Assistant.

## About

This add-on provides integration between TeslaMate and A Better Route Planner (ABRP). It allows you to send your Tesla vehicle data from TeslaMate to ABRP for better route planning and battery predictions.

## Installation

1. Add this repository to your Home Assistant instance
2. Install the TeslaMate ABRP add-on
3. Configure the add-on with your ABRP tokens and MQTT details
4. Start the add-on

## Configuration

Example add-on configuration:

```yaml
abrp_token: your_abrp_api_token
abrp_user_token: your_abrp_user_token
mqtt_host: core-mosquitto
mqtt_port: 1883
mqtt_username: your_mqtt_username
mqtt_password: your_mqtt_password
```

### Option: `abrp_token` (required)

The API token from ABRP.

### Option: `abrp_user_token` (required)

Your ABRP user token.

### Option: `mqtt_host` (required)

The hostname of your MQTT broker.

### Option: `mqtt_port` (required)

The port of your MQTT broker.

### Option: `mqtt_username` (optional)

The username for your MQTT broker.

### Option: `mqtt_password` (optional)

The password for your MQTT broker.
