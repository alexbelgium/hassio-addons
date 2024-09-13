# Home assistant add-on: changedetection.io

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fchangedetection.io%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fchangedetection.io%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fchangedetection.io%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/changedetection.io/stats.png)

## About

[Changedetection.io](https://github.com/dgtlmoon/changedetection.io) provides free, open-source web page monitoring, notification and change detection.

This addon is based on the [docker image](https://github.com/linuxserver/docker-changedetection.io) from linuxserver.io.

## Configuration

### Main app

Web UI can be found at `<your-ip>:5000`, also accessible from the add-on page.

#### Sidebar shortcut

You can add a shortcut pointing to your Changedetection.io instance with the following steps:
1. Go to <kbd>⚙ Settings</kbd> > <kbd>Dashboards</kbd>
2. Click <kbd>➕ Add Dashboard</kbd> at the bottom corner
3. Select the <kbd>Webpage</kbd> option, and paste the Web UI URL you got from the add-on page.
4. Fill in the title for the sidebar item, an icon (suggestion: `mdi:vector-difference`), and a **relative URL** for that panel (e.g. `change-detection`). Lastly, confirm it.

### Configurable options

```yaml
PGID: user
GPID: user
TZ: Etc/UTC specify a timezone to use, see https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List
BASE_URL: Specify the full URL (including protocol) when running behind a reverse proxy
```

### Connect to browserless Chrome (from @RhysMcW)

In HA, use the File Editor add-on (or Filebrowser) and edit the Changedetection.io config file at `/homeassistant/addons_config/changedetection.io/config.yaml`.

Add the following line to the end of it: 
```yaml
PLAYWRIGHT_DRIVER_URL: ws://2937404c-browserless-chrome:3000/chromium?launch={"defaultViewport":{"height":720,"width":1280},"headless":false,"stealth":true}&blockAds=true
```

Remember to add a blank line at the end of the file too according to yaml requirements.

The `2937404c-browserless-chrome` hostname is displayed in the UI, on the  Browserless Chromium addon page:
![image](https://github.com/user-attachments/assets/a63514f6-027a-4361-a33f-0d8f87461279)

You can also fetch it:
* By using SSH and running `docker exec -i hassio_dns cat "/config/hosts"`
* From the CLI in HA, using arp
* You should also be able to use your HA IP address.

Then restart the Changedetection.io add-on - after that you can use the browser options in Changedetection.io.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

[repository]: https://github.com/alexbelgium/hassio-addons
