
# Home assistant add-on: addons updater


I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/addons_updater/stats.png)

## About

This script allows to automatically update addons based on upstream new releases. This is only an helper tool for developers. End users don’t need that to update their addons - they are automatically alerted by HA when an update is available

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Configure the add-on to your preferences, see below
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## Configuration

No webUI. Configuration is set in 2 ways.

### Updater.json

In the addon folder of your repository (where is located you config.json), create a "updater.json" file.
This file will be used by the addon to fetch the addon upstream informations.
Only addons with an updater.json file will be updated.
Here is [an example](https://github.com/alexbelgium/hassio-addons/blob/master/arpspoof/updater.json).

You can add the following tags in the file :

- github_fulltag: true is for example "v3.0.1-ls67" false is "3.0.1"
- github_beta: true/false ; should it look only for releases or prereleases ok
- github_havingasset : true if there is a requirement that a release has binaries and not just source
- github_tagfilter: filter a text in the release name
- github_exclude: exclude a text in the release name
- last_update: automatically populated, date of last upstream update
- repository: 'name/repo' coming from github
- paused: true # Pauses the updates
- slug: the slug name from your addon
- source: dockerhub/github,gitlab,bitbucket,pip,hg,sf,website-feed,local,helm_chart,wiki,system,wp,codeberg (Codeberg is supported via its Gitea API, which is configured automatically)
- upstream_repo: name/repo, example is 'linuxserver/docker-emby'
- upstream_version: automatically populated, corresponds to the current upstream version referenced in the addon
- dockerhub_by_date: in dockerhub, uses the last_update date instead of the version
- dockerhub_list_size: in dockerhub, how many containers to consider for latest version

### Addon version numbering

The `version` written in the addon `config.yaml` is the one Home Assistant compares to decide whether an update is available. Home Assistant hides the update when it can order both versions and the new one is not strictly newer (`1.2.3` -> `1.2.3-2` is a semver pre-release, so it is *older*), and it cannot order tags such as `version-bf9e0b4f` or `ubuntu-2026-06-01` at all.

The addon version is therefore derived from the upstream tag:

- a tag Home Assistant can order and that is newer is used as it is
- `1.2.3-4` and `1.2.3+4` become `1.2.3.4`
- a pre-release marker becomes a section of its own, so the number it carries keeps ordering the addon: `5.0.0b5` -> `5.0.0.5`
- a tag it cannot order keeps every number it carries, in order: `v26.2-ls256` -> `v26.2.256`, `nightly-2.6.1.5509-ls8` -> `2.6.1.5509.8`, `4.16-r0-ls94` -> `4.16.0.94`, `ubuntu-2026-07-28` -> `2026.07.28`. Words holding no number, an architecture, and anything else such as a commit hash are left out
- a tag holding no number at all (`version-bf9e0b4f`, `sts`) increments the current addon version (`1.37` -> `1.38`), or uses the date when there is nothing to increment (`2026.08.01`, then `2026.08.01.1` for a second update the same day)

`updater.json` always keeps the raw upstream tag, so the next run still compares upstream with upstream and a single upstream release never triggers two addon updates. The raw tag is also kept in the Dockerfile and the build files, and is added to the changelog entry when it differs from the addon version.

These rules are checked by `python3 /usr/bin/ha_version.py --selftest`, which can be run from a terminal in the addon container.

### Addon configuration

Here you define the values that will allow the addon to connect to your repository.

```yaml
repository: 'name/repo' coming from github
gituser: your github username
gitapi: your github api token(classic) https://github.com/settings/tokens
gitmail: your github email
date_iso8601: true # use ISO8601 dates (YYYY-MM-DD) instead of DD-MM-YYYY
verbose: 'false'
```

Example:

```yaml
repository: alexbelgium/hassio-addons
gituser: your github username
gitapi: your github api token
gitmail: your github email
date_iso8601: true
verbose: "false"
```

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `app_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: Use the add-on `env_vars` option and see [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon) for details.

[repository]: https://github.com/alexbelgium/hassio-addons
