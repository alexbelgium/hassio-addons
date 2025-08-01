# Home assistant add-on: whoogle-search

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwhoogle%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwhoogle%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fwhoogle%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/whoogle/stats.png)

## About

[whoogle-search](https://github.com/benbusby/whoogle-search) is a Self-hosted, ad-free, privacy-respecting metasearch engine.
This addon is based on the docker image https://hub.docker.com/r/benbusby/whoogle-search/tags

## Configuration

Webui can be found at <http://homeassistant:PORT> or through the sidebar using Ingress.
Configurations can be done through the app webUI, except for the following options.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `TZ` | str | `Europe/Amsterdam` | Timezone |
| `WHOOGLE_CONFIG_LANGUAGE` | str | `lang_en` | Interface language |
| `WHOOGLE_CONFIG_URL` | str | | Base URL for the service |
| `WHOOGLE_CONFIG_THEME` | list | | Theme (system/light/dark) |
| `WHOOGLE_CONFIG_COUNTRY` | str | | Country code for search results |
| `WHOOGLE_CONFIG_SEARCH_LANGUAGE` | str | | Search language |
| `WHOOGLE_CONFIG_BLOCK` | str | | Comma-separated list of sites to block |
| `WHOOGLE_CONFIG_SAFE` | list | | Safe search (0/1) |
| `WHOOGLE_CONFIG_ALTS` | list | | Use alternative frontends (0/1) |
| `WHOOGLE_CONFIG_NEW_TAB` | list | | Open results in new tab (0/1) |
| `WHOOGLE_CONFIG_VIEW_IMAGE` | list | | Enable view image option (0/1) |
| `WHOOGLE_CONFIG_GET_ONLY` | list | | GET requests only (0/1) |
| `WHOOGLE_CONFIG_DISABLE` | list | | Disable changing settings (0/1) |
| `WHOOGLE_AUTOCOMPLETE` | list | | Enable autocomplete (0/1) |
| `WHOOGLE_MINIMAL` | list | | Minimal mode (0/1) |
| `WHOOGLE_CSP` | list | | Content Security Policy (0/1) |
| `WHOOGLE_RESULTS_PER_PAGE` | int | | Results per page (5-100) |
| `WHOOGLE_USER` | str | | Username for authentication |
| `WHOOGLE_PASS` | password | | Password for authentication |
| `WHOOGLE_PROXY_TYPE` | str | | Proxy type |
| `WHOOGLE_PROXY_LOC` | str | | Proxy location |
| `WHOOGLE_PROXY_USER` | str | | Proxy username |
| `WHOOGLE_PROXY_PASS` | str | | Proxy password |
| `WHOOGLE_ALT_TW` | str | | Twitter alternative frontend |
| `WHOOGLE_ALT_YT` | str | | YouTube alternative frontend |
| `WHOOGLE_ALT_IG` | str | | Instagram alternative frontend |
| `WHOOGLE_ALT_RD` | str | | Reddit alternative frontend |
| `WHOOGLE_ALT_MD` | str | | Medium alternative frontend |
| `WHOOGLE_ALT_TL` | str | | TikTok alternative frontend |
| `HTTPS_ONLY` | list | | HTTPS only mode (0/1) |

### Example Configuration

```yaml
TZ: "Europe/London"
WHOOGLE_CONFIG_LANGUAGE: "lang_en"
WHOOGLE_CONFIG_URL: "https://search.mydomain.com"
WHOOGLE_CONFIG_THEME: "dark"
WHOOGLE_CONFIG_COUNTRY: "US"
WHOOGLE_CONFIG_SAFE: "0"
WHOOGLE_AUTOCOMPLETE: "1"
WHOOGLE_USER: "admin"
WHOOGLE_PASS: "secure-password"
WHOOGLE_RESULTS_PER_PAGE: 20
```

For complete environment variable documentation, see: https://github.com/benbusby/whoogle-search#environment-variables

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

## Support

Create an issue on github

## Illustration

![illustration](https://github.com/benbusby/whoogle-search/raw/main/docs/screenshot_desktop.jpg)

[repository]: https://github.com/alexbelgium/hassio-addons
