
# Home assistant add-on: Epic Games Free

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fepicgamesfree%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fepicgamesfree%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fepicgamesfree%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/epicgamesfree/stats.png)

## About

[Epic Games Store Weekly Free Games](https://github.com/claabs/epicgames-freegames-node) : automatically login and redeem promotional free games from the Epic Games Store. Handles multiple accounts, 2FA, captcha bypass, captcha notifications, and scheduled runs.
This addon is based on the docker image https://hub.docker.com/r/charlocharlie/epicgames-freegames

## Configuration

There are no addon options available through the Home Assistant interface. All configuration is done via JSON files.

### Configuration Files

Configuration files are stored in `/config/addons_config/epicgamesfree/`:

- **config.json**: Main configuration file
- **cookies.json**: Authentication cookies (optional)

If these files don't exist, they will be created at first boot with default settings.

### Basic Configuration

Create `/config/addons_config/epicgamesfree/config.json`:

```json
{
  "accounts": [
    {
      "email": "your-epic-email@example.com", 
      "password": "your-password",
      "totp": "OPTIONAL_2FA_SECRET"
    }
  ],
  "intervalHours": 24,
  "onlyWeekly": false,
  "searchStrategy": "purchase",
  "browserNavigationTimeout": 300000,
  "notifications": {
    "email": {
      "smtpHost": "smtp.gmail.com",
      "smtpPort": 587,
      "emailSenderAddress": "notifications@example.com",
      "emailSenderName": "Epic Games Free",
      "emailRecipientAddress": "recipient@example.com",
      "secure": false,
      "auth": {
        "user": "notifications@example.com",
        "pass": "your-app-password"
      }
    }
  }
}
```

### Configuration Options

| Option | Type | Description |
|--------|------|-------------|
| `accounts` | array | List of Epic Games accounts |
| `intervalHours` | number | Check interval in hours (default: 24) |
| `onlyWeekly` | boolean | Only claim weekly free games |
| `searchStrategy` | string | Search strategy: "purchase" or "claim" |
| `browserNavigationTimeout` | number | Browser timeout in milliseconds |
| `notifications` | object | Notification settings (email, webhook, etc.) |

### Account Configuration

For each account in the `accounts` array:

```json
{
  "email": "account@example.com",
  "password": "password",
  "totp": "TOTP_SECRET",
  "onlyWeekly": true
}
```

### Notification Methods

#### Email Notifications
```json
"notifications": {
  "email": {
    "smtpHost": "smtp.gmail.com",
    "smtpPort": 587,
    "emailSenderAddress": "sender@example.com",
    "emailRecipientAddress": "recipient@example.com",
    "secure": false,
    "auth": {
      "user": "sender@example.com",
      "pass": "app-password"
    }
  }
}
```

#### Webhook Notifications
```json
"notifications": {
  "webhook": {
    "url": "https://your-webhook-url.com",
    "events": ["purchase-success", "already-owned"]
  }
}
```

### Important Notes

- **Automatic Redemption**: Due to Epic Games' improved automation detection, automatic redemption is no longer possible
- **Notification System**: The addon now sends redemption links via your preferred notification method instead of automatically claiming games
- **2FA Support**: TOTP (Time-based One-Time Password) is supported for accounts with two-factor authentication
- **Multiple Accounts**: You can configure multiple Epic Games accounts

### Cookie Import (Optional)

You can import browser cookies to avoid login issues. Create `/config/addons_config/epicgamesfree/cookies.json`:

For detailed cookie import instructions, see: https://github.com/claabs/epicgames-freegames-node#cookie-import

### Troubleshooting

#### Timeout Errors
Add the following to your config.json:
```json
"browserNavigationTimeout": 300000
```

#### Login Issues
1. Check your credentials are correct
2. Verify 2FA/TOTP configuration if enabled
3. Consider importing browser cookies
4. Check the addon logs for specific error messages

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

### Timeout error

Please try adding `"browserNavigationTimeout": 300000,` to your config.json (https://github.com/alexbelgium/hassio-addons/issues/675#issuecomment-1407675351)

### Other errors

Create an issue on github

[repository]: https://github.com/alexbelgium/hassio-addons
