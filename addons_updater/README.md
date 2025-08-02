
# Home assistant add-on: addons updater

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Faddons_updater%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/addons_updater/stats.png)

## About

This script allows to automatically update addons based on upstream new releases. This is only an helper tool for developers. End users don’t need that to update their addons - they are automatically alerted by HA when an update is available

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
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
- source: dockerhub/github,gitlab,bitbucket,pip,hg,sf,website-feed,local,helm_chart,wiki,system,wp
- upstream_repo: name/repo, example is 'linuxserver/docker-emby'
- upstream_version: automatically populated, corresponds to the current upstream version referenced in the addon
- dockerhub_by_date: in dockerhub, uses the last_update date instead of the version
- dockerhub_list_size: in dockerhub, how many containers to consider for latest version

### Addon configuration

Here you define the values that will allow the addon to connect to your repository.

```yaml
repository: 'name/repo' coming from github
gituser: your github username
gitapi: your github api token(classic) https://github.com/settings/tokens
gitmail: your github email
verbose: 'false'
```

Example:

```yaml
repository: alexbelgium/hassio-addons
gituser: your github username
gitapi: your github api token
gitmail: your github email
verbose: "false"
```

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

[repository]: https://github.com/alexbelgium/hassio-addons
