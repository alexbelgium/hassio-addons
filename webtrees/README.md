# Home assistant add-on: Webtrees

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwebtrees%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwebtrees%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwebtrees%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/webtrees/stats.png)

## About

[webtrees](http://www.webtrees.net) is the web's leading online collaborative genealogy application.

This addon is based on the docker image https://github.com/NathanVaughn/webtrees-docker

## Configuration

Webui can be found at <http://homeassistant:PORT>.

The name and password are defined through the startup wizard.

Options can be configured through two ways :

- Addon options

```yaml
LANG: "en-US" # Default language for webtrees
BASE_URL: "http://192.168.178.69" # The url with which you access webtrees
DB_TYPE: "sqlite" # Your database type : sqlite for automatic configuration, or external for manual config
CONFIG_LOCATION: location of the config.yaml (see below)
localdisks: sda1 #put the hardware name of your drive to mount separated by commas, or its label. ex. sda1, sdb1, MYNAS...
networkdisks: "//SERVER/SHARE" # optional, list of smb servers to mount, separated by commas
cifsusername: "username" # optional, smb username, same for all smb shares
cifspassword: "password" # optional, smb password
trusted_headers: single address, or a range of addresses in CIDR format
base_url_portless: base url without port
```

- Config.yaml

Custom env variables can be added to the config.yaml file referenced in the addon options. Folder containing this is not a part of root/config directory (where HA's configuration.yaml is), but /root/addon_configs ([HA documentation](https://developers.home-assistant.io/blog/2023/11/06/public-addon-config/)). Full env variables can be found here : https://github.com/linuxserver/docker-paperless-ng. It must be entered in a valid yaml format, that is verified at launch of the addon.

## Installation

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Remote access

It is possible to expose this add-on for external access (for family and friends).
This can be done for free, and without exposing your network to the outside.
One of the solutions for this is a [Cloudflare tunnel](https://github.com/brenner-tobias/addon-cloudflared). There’s plenty of materials on how to do this on the forum and on YouTube, together with securing it with additional rules and Google email verification.
Here are the considerations for configuring the integrations:

Webtrees config

```yaml
BASE_URL: httpS://your_tunnel_domain_name.example.com
# This is the external URL you'll be accessing the page with.
# Even though the base configuration of the add-on doesn't use SSL, when using Cloudflare it's important the base_url has https
# This is because when tunnel is running, Cloudflare will apply its own SSL to connection.
# If base_url has http://, this will cause a mismatch and some blocks will not load correctly
ssl: false #disabled, Cloudflare takes care of this
base_url_portless: true #must be enabled

#rest is standard
DATA_LOCATION: /config/data
certfile: fullchain.pem
keyfile: privkey.pem
```

Cloudflared config

```yaml
external_hostname: "" #none, to keep HA accessible only through Nabu Casa, but can be used to do both
additional_hosts:
  - hostname: your_tunnel_domain_name.example.com #notice that it's the same as in webtrees config
    service: http://your_HA_IP:9999 #notice that here it's http and with port, despite webtrees being configured portless
tunnel_name: Your_tunnel_name
```

## Support

Create an issue on github

## Illustration

![illustration](https://installatron.infomaniak.com/installatron//images/ss2_webtrees.jpg)
