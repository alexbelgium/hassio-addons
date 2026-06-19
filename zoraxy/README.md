# Home assistant add-on: Zoraxy


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fzoraxy%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fzoraxy%2Fconfig.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

## About

[Zoraxy](https://github.com/tobychui/zoraxy) is a general purpose HTTP request (reverse) proxy and forwarding tool with a clean web management UI. It can be used as a modern, actively-maintained alternative to Nginx Proxy Manager: create reverse proxy hosts, manage TLS certificates (including ACME / Let's Encrypt), set up redirections, access rules, a basic web server and more.

This add-on is based on the official [docker image](https://github.com/tobychui/zoraxy/tree/main/docker) from tobychui.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the Web UI and create your administrator account.

## Configuration

The management Web UI is exposed on port `8000`. Because Zoraxy acts as a reverse
proxy that must own the standard web ports, it is **not** served through Home
Assistant ingress — open it directly:

Webui can be found at `http://homeassistant.local:8000`

The reverse proxy itself listens on ports `80` (HTTP) and `443` (HTTPS). Make
sure these ports are free on the host (e.g. not used by another proxy add-on)
and, if you want to reach your services from outside, forward them on your
router.

All configuration, the database, logs and plugins are stored persistently in the
add-on configuration folder (`/addon_configs/<slug>_zoraxy/`, exposed inside the
container as `/config`), so they survive add-on updates and restarts.

### Options

| Option      | Default | Description                                                                                  |
| ----------- | ------- | -------------------------------------------------------------------------------------------- |
| `NOAUTH`    | `false` | Disable authentication for the management interface (use with care).                          |
| `ZEROTIER`  | `false` | Enable the ZeroTier global area network controller (uses the `NET_ADMIN` capability and `/dev/net/tun`, both granted by the add-on). |
| `FASTGEOIP` | `false` | Enable high-speed GeoIP lookup (uses ~1 GB extra memory).                                      |
| `MDNS`      | `true`  | Enable mDNS service discovery.                                                                 |
| `TZ`        | -       | Timezone, e.g. `Europe/Brussels`.                                                             |
| `env_vars`  | `[]`    | Pass any additional upstream environment variable (e.g. `AUTORENEW`, `DB`, `MDNSNAME`, ...).   |

Any other upstream setting documented in the [Zoraxy docker README](https://github.com/tobychui/zoraxy/tree/main/docker) can be supplied through `env_vars`:

```yaml
env_vars:
  - name: AUTORENEW
    value: "86400"
  - name: DB
    value: "auto"
```

## Support

Create an issue on the [repository](https://github.com/alexbelgium/hassio-addons).
