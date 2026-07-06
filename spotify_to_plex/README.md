# Home assistant add-on: Spotify to Plex


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotify_to_plex%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotify_to_plex%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fspotify_to_plex%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20Paypal-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

This addon is based on the [docker image](https://hub.docker.com/r/jjdenhertog/spotify-to-plex) from [jjdenhertog/spotify-to-plex](https://github.com/jjdenhertog/spotify-to-plex).

It keeps your Spotify playlists synced to Plex automatically: syncing any Spotify playlist (including Spotify-owned ones), supporting multiple Spotify users, scheduled automatic synchronization, smart caching and optional downloading of missing tracks via Lidarr, SLSKD or Tidal.

## Configuration

Before starting the add-on you need a Spotify developer application (https://developer.spotify.com/dashboard):

1. Create an app and note its `Client ID` and `Client Secret`.
1. In the app settings, add the redirect URI `https://jjdenhertog.github.io/spotify-to-plex/callback.html` (this is the default `SPOTIFY_API_REDIRECT_URI`; change it only if you self-host the callback page).

Fill the add-on options:

| Option | Description |
|--------|-------------|
| `SPOTIFY_API_CLIENT_ID` | Client ID of your Spotify developer application |
| `SPOTIFY_API_CLIENT_SECRET` | Client secret of your Spotify developer application |
| `SPOTIFY_API_REDIRECT_URI` | OAuth redirect URI (must match the one configured in your Spotify app) |
| `ENCRYPTION_KEY` | Key used to encrypt stored secrets. **Leave empty** to have the add-on generate a random key on first start and persist it in the add-on config folder. Provide your own only if you want to reuse an existing configuration. |

Use the add-on `env_vars` option to pass any extra upstream environment variables (for example Tidal, SLSKD, Lidarr or Plex settings). See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

The configuration and cache are stored in the add-on config folder (`/addon_configs/<slug>`), so they survive restarts and updates.

Webui can be found at `<your-ip>:9030`.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Set the required options (Spotify Client ID and Secret).
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webui, where you will finish the setup and connect your Spotify and Plex accounts.

## Support

For issues related to the add-on packaging, open an issue on [alexbelgium/hassio-addons](https://github.com/alexbelgium/hassio-addons/issues).
For issues related to the application itself, refer to the [upstream project](https://github.com/jjdenhertog/spotify-to-plex).

[repository]: https://github.com/alexbelgium/hassio-addons
