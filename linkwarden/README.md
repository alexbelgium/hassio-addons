# Home assistant add-on: linkwarden

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Flinkwarden%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/linkwarden/stats.png)

## About

---

[linkwarden](https://linkwarden.app/) is a collaborative bookmark manager to collect, organize, and preserve webpages and articles.
This addon is based on their docker image.

## Configuration

Install, then start the addon a first time
Webui can be found at <http://homeassistant:3000>.
You'll need to create a new user at startup.

Options can be configured through two ways :

- Addon options

```yaml
"NEXTAUTH_SECRET": mandatory, must be filled at start
"NEXTAUTH_URL": optional, only if linkwarden is kept externally
"STORAGE_FOLDER": optional, is /config/library by default
"DATABASE_URL": optional, if kept blank an internal database will be used. If an external database is used, modify according to this design postgresql://postgres:homeassistant@localhost:5432/linkwarden
```

- Config.yaml
All other options can be configured using the config.yaml file found in /config/db21ed7f_filebrowser/config.yaml using the Filebrowser addon.

The complete list of options can be seen here : https://docs.linkwarden.app/self-hosting/environment-variables

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

Use the [linkwarden integration](https://www.home-assistant.io/integrations/linkwarden/)

You can use the following snippets to check and set the alternate speeds (the HA integration above is not needed for this)

```bash
shell_command:
  toggle_torrent_speed: curl -X POST https://<YOUR HA IP>:8081/api/v2/transfer/toggleSpeedLimitsMode -k
sensor:
  - platform: command_line
    name: get_torrent_speed
    command: curl https://<YOUR HA IP>:8081/api/v2/transfer/speedLimitsMode -k
```

If you're not using the SSL option, you can skip the -k parameter and use http instead of https in the URL

These lines will expose a `sensor.get_torrent_speed` that updates every 60 seconds and returns 1 if the alternate speed mode is enabled, 0 otherwise, and a `shell_command.toggle_torrent_speed` that you can call as a Service in your automations

## Common issues

<details>
  <summary>### ipv6 issues with openvpn (@happycoo)</summary>
Add this code to your .ovpn config

```bash
# don't route lan through vpn
route 192.168.1.0 255.255.255.0 net_gateway

# deactivate ipv6
pull-filter ignore "dhcp-option DNS6"
pull-filter ignore "tun-ipv6"
pull-filter ignore "ifconfig-ipv6"
```
</details>

<details>
  <summary>### Monitored folders (@FaliseDotCom)</summary>

- go to config\addons_config\linkwarden
- find (or create) the file watched_folders.json
- paste or adjust to the following:

```json
{
    "folder/to/watch": {
        "add_torrent_params": {
            "category": "",
            "content_layout": "Original",
            "download_limit": -1,
            "download_path": "[folder/for/INCOMPLETE_downloads]",
            "operating_mode": "AutoManaged",
            "ratio_limit": -2,
            "save_path": "[folder/for/COMPLETED_downloads]",
            "seeding_time_limit": -2,
            "skip_checking": false,
            "stopped": false,
            "tags": [
            ],
            "upload_limit": -1,
            "use_auto_tmm": false,
            "use_download_path": true
        },
        "recursive": false
    }
}
```
</details>

<details>
  <summary>### nginx error code (@Nanianmichaels)</summary>

> [cont-init.d] 30-nginx.sh: executing...
> [cont-init.d] 30-nginx.sh: exited 1.

Wait a couple minutes and restart addon, it could be a temporary unavailability of github

### Local mount with invalid argument (@antonio1475)

> [cont-init.d] 00-local_mounts.sh: executing...
> Local Disks mounting...
> mount: mounting /dev/sda1 on /mnt/sda1 failed: Invalid argument
> [19:19:44] FATAL: Unable to mount local drives! Please check the name.
> [cont-init.d] 00-local_mounts.sh: exited 0.

Try to mount by putting the partition label in the "localdisks" options instead of the hardware name
</details>

<details>
  <summary>### Loss of metadata fetching with openvpn after several days (@almico)</summary>

Add `ping-restart 60` to your config.ovpn
</details>

<details>
  <summary>### Downloads info are empty on small scale window (@aviadlevy)</summary>

When my window size width is lower than 960 pixels my downloads are empty.
Solution is to reset the Vuetorrent settings.
</details>

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-linkwarden/279247)

---

![illustration](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/linkwarden/illustration.png)
