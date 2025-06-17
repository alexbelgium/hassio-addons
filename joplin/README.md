## &#9888; Open Request : [✨ [REQUEST] [Joplin] Add Ingress (opened 2025-06-15)](https://github.com/alexbelgium/hassio-addons/issues/1913) by [@aluavin](https://github.com/aluavin)
# Home assistant add-on: Joplin

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fjoplin%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/joplin/stats.png)

## About

Joplin Server is a free, open source note taking and to-do Sync application, which can handle a large number of notes organised into notebooks.
With this server you can sync all your notes over all your devices.

Thanks to @poudenes for helping with the development!

Project homepage : https://github.com/laurent22/joplin

Based on the docker image : https://hub.docker.com/r/etechonomy/joplin-server

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Configuration

Webui can be found at <http://homeassistant:port>

```yaml
APP_BASE_URL: This is the base public URL where the service will be running. For example, if you want it to run from https://example.com/joplin, this is what you should set the URL to. The base URL can include the port.
```

To use an existing PostgresSQL server, set the following variables in the config:
Make sure that the provided database and user exist as the server will not create them.

```yaml
DB_CLIENT=pg
POSTGRES_PASSWORD=joplin
POSTGRES_DATABASE=joplin
POSTGRES_USER=joplin
POSTGRES_PORT=5432
POSTGRES_HOST=localhost
```

To use email service, set the follow variables in the config:

```yaml
1 = true, 0 = false
MAILER_HOST=mail.example.com
MAILER_PORT=995
MAILER_SECURITY=none, tls, starttls
MAILER_AUTH_USER=info@example.com
MAILER_AUTH_PASSWORD=your_password
MAILER_NOREPLY_NAME=from_name
MAILER_NOREPLY_EMAIL=from_email
MAILER_ENABLED=1
```

## Support

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
