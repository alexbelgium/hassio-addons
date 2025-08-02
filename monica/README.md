# Home assistant add-on: Monica

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmonica%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmonica%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fmonica%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/monica/stats.png)

## About

[Monica](https://www.monicahq.com/) is a Personal Relationship Manager (PRM) that helps you organize your social life and keep track of your relationships with friends, family, and colleagues. It's like a CRM, but for your personal life.

Key features:
- Track conversations, activities, and important dates
- Store contact information and relationship details
- Set reminders for birthdays, anniversaries, and follow-ups
- Document gifts given and received
- Track debts and favors
- Organize notes and memories about people
- Journal functionality
- Gift ideas tracking
- Multiple database options (SQLite, MariaDB, MySQL)

This addon is based on the official [Monica](https://github.com/monicahq/monica) application.

## Configuration

Webui can be found at `<your-ip>:8181`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `database` | list | `sqlite` | Database type (sqlite/MariaDB_addon/Mysql_external) |
| `APP_KEY` | str | | Application encryption key (auto-generated if empty) |
| `DB_DATABASE` | str | | Database name (for external MySQL/MariaDB) |
| `DB_HOST` | str | | Database hostname (for external MySQL/MariaDB) |
| `DB_USERNAME` | str | | Database username (for external MySQL/MariaDB) |
| `DB_PASSWORD` | str | | Database password (for external MySQL/MariaDB) |
| `DB_PORT` | int | | Database port (for external MySQL/MariaDB) |
| `MAIL_MAILER` | str | `log` | Mail driver (smtp/log/sendmail) |
| `MAIL_HOST` | str | | SMTP server hostname |
| `MAIL_PORT` | str | | SMTP server port |
| `MAIL_USERNAME` | str | | SMTP username |
| `MAIL_PASSWORD` | str | | SMTP password |
| `MAIL_ENCRYPTION` | str | | SMTP encryption (tls/ssl) |
| `MAIL_FROM_ADDRESS` | str | | From email address |
| `MAIL_FROM_NAME` | str | | From email name |

### Example Configuration

```yaml
database: "sqlite"
APP_KEY: ""  # Will be auto-generated
MAIL_MAILER: "smtp"
MAIL_HOST: "smtp.gmail.com"
MAIL_PORT: "587"
MAIL_USERNAME: "your-email@gmail.com"
MAIL_PASSWORD: "your-app-password"
MAIL_ENCRYPTION: "tls"
MAIL_FROM_ADDRESS: "your-email@gmail.com"
MAIL_FROM_NAME: "Monica"
```

### Database Configuration

**SQLite (Default):**
- No additional configuration required
- Data stored in addon directory
- Suitable for single-user setups

**MariaDB Addon:**
- Set `database` to `MariaDB_addon`
- Requires MariaDB addon to be installed and running
- Addon will auto-configure database connection

**External MySQL/MariaDB:**
- Set `database` to `Mysql_external`
- Configure all `DB_*` options with your database details

### Email Configuration

Configure SMTP settings to enable:
- Password reset emails
- Invitation emails
- Notification emails
- Reminder emails

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Configure database and email settings as needed.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI to set up your Monica account.

## First Setup

After installation and startup:

1. Open the webUI at `<your-ip>:8181`
2. Create your first user account
3. Complete the setup wizard
4. Start adding your contacts and relationships

## Support

Create an issue on github, or ask on the [home assistant community forum](https://community.home-assistant.io/)

For more information about Monica, visit: https://www.monicahq.com/

[repository]: https://github.com/alexbelgium/hassio-addons
