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
"NEXT_PUBLIC_DISABLE_REGISTRATION": If set to true, registration will be disabled.
"NEXT_PUBLIC_CREDENTIALS_ENABLED": If set to true, users will be able to login with username and password.
"STORAGE_FOLDER": optional, is /config/library by default
"DATABASE_URL": optional, if kept blank an internal database will be used. If an external database is used, modify according to this design postgresql://postgres:homeassistant@localhost:5432/linkwarden
"NEXT_PUBLIC_AUTHENTIK_ENABLED": If set to true, Authentik will be enabled and you'll need to define the variables below.
"AUTHENTIK_CUSTOM_NAME": Optionally set a custom provider name. (name on the button)
"AUTHENTIK_ISSUER": This is the "OpenID Configuration Issuer" shown in the Provider Overview. Note that you must delete the "/" at the end of the URL. Should look like: `https://authentik.my-doma.in/application/o/linkwarden`
"AUTHENTIK_CLIENT_ID": Client ID copied from the Provider Overview screen in Authentik
"AUTHENTIK_CLIENT_SECRET": Client Secret copied from the Provider Overview screen in Authentik
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

## Integration with Authentik

Follow the instruction from the Linkwarden docs page. https://docs.linkwarden.app/self-hosting/sso-oauth#authentik

## Common issues

<details>

## Support

Create an issue on github, or ask on the [home assistant thread](https://community.home-assistant.io/t/home-assistant-addon-linkwarden/279247)

---

![illustration](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/linkwarden/illustration.png)
