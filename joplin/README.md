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

[Joplin Server](https://github.com/laurent22/joplin) is a free, open source note taking and to-do synchronization application, which can handle a large number of notes organized into notebooks. With this server you can sync all your notes across all your devices. Joplin supports end-to-end encryption, markdown editing, web clipper extensions, and synchronization with various cloud services.

This addon is based on the [docker image](https://hub.docker.com/r/etechonomy/joplin-server) from etechonomy.

Thanks to @poudenes for helping with the development!

## Configuration

Webui can be found at `<your-ip>:22300`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `APP_BASE_URL` | str | `http://your_domain:port` | Base public URL where the service will be running |
| `data_location` | str | `/config/addons_config/joplin` | Path where Joplin data is stored |
| `DB_CLIENT` | str | | Database client type (e.g., `pg` for PostgreSQL) |
| `POSTGRES_HOST` | str | | PostgreSQL server hostname |
| `POSTGRES_PORT` | int | | PostgreSQL server port |
| `POSTGRES_DATABASE` | str | | PostgreSQL database name |
| `POSTGRES_USER` | str | | PostgreSQL username |
| `POSTGRES_PASSWORD` | str | | PostgreSQL password |
| `MAILER_ENABLED` | int | | Enable email service (1=true, 0=false) |
| `MAILER_HOST` | str | | SMTP server hostname |
| `MAILER_PORT` | int | | SMTP server port |
| `MAILER_SECURITY` | str | | SMTP security (none, tls, starttls) |
| `MAILER_AUTH_USER` | str | | SMTP authentication username |
| `MAILER_AUTH_PASSWORD` | str | | SMTP authentication password |
| `MAILER_NOREPLY_NAME` | str | | Email sender name |
| `MAILER_NOREPLY_EMAIL` | str | | Email sender address |

### Example Configuration

```yaml
APP_BASE_URL: "http://192.168.1.100:22300"
data_location: "/config/addons_config/joplin"
DB_CLIENT: "pg"
POSTGRES_HOST: "core-mariadb"
POSTGRES_PORT: 3306
POSTGRES_DATABASE: "joplin"
POSTGRES_USER: "joplin"
POSTGRES_PASSWORD: "secure_password"
MAILER_ENABLED: 1
MAILER_HOST: "smtp.gmail.com"
MAILER_PORT: 587
MAILER_SECURITY: "starttls"
MAILER_AUTH_USER: "your-email@gmail.com"
MAILER_AUTH_PASSWORD: "your-app-password"
MAILER_NOREPLY_NAME: "Joplin Server"
MAILER_NOREPLY_EMAIL: "noreply@yourdomain.com"
```

### Database Setup

Joplin Server uses SQLite by default, but for production use, PostgreSQL is recommended:

1. Install and configure a PostgreSQL addon (e.g., MariaDB addon)
2. Create a database and user for Joplin
3. Configure the PostgreSQL options in the Joplin addon
4. Restart the addon

Make sure the provided database and user exist as the server will not create them automatically.

### Email Configuration

To enable email functionality for user registration and notifications:

1. Configure your SMTP server details
2. Set `MAILER_ENABLED` to `1`
3. Provide authentication credentials
4. Test the configuration by registering a new user

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Navigate to the web interface to complete the initial setup.

## Setup Steps

1. **Initial Setup**: After starting the addon, navigate to the web interface
2. **Create Admin Account**: Create your first admin user account
3. **Configure Synchronization**: Set up your Joplin clients to sync with the server
4. **Optional Database**: Consider switching to PostgreSQL for better performance
5. **Email Service**: Configure email service for user management features

## Support

Create an issue on [GitHub](https://github.com/alexbelgium/hassio-addons/issues).

[repository]: https://github.com/alexbelgium/hassio-addons
