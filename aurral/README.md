# Home assistant add-on: Aurral

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faurral%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faurral%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faurral%2Fconfig.yaml)

## About

---

[Aurral](https://github.com/lklynet/aurral) is a self-hosted music discovery, request management, flows, and playlist importing app for Lidarr with library-aware recommendations.
This addon is based on the docker image https://github.com/lklynet/aurral

## Configuration

Webui can be found at <http://homeassistant:PORT> or through the sidebar using Ingress.

### Options

| Option | Default | Description |
|---|---|---|
| `download_folder` | `/share/aurral/downloads` | Path where Aurral writes flow downloads. Must be under `/share`. |
| `data_folder` | `/share/aurral/data` | Path for Aurral's database and persistent config. Must be under `/share`. |

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the `download_folder` and `data_folder` options to your preferred paths.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and complete onboarding.

## Support

Create an issue on github
