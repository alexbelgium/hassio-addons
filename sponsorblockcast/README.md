## &#9888; Open Issue : [🐛 [sponsorblockcast] title (opened 2025-08-22)](https://github.com/alexbelgium/hassio-addons/issues/2055) by [@glyph-se](https://github.com/glyph-se)

# Home assistant add-on: CastSponsorSkip

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

![Version](https://img.shields.io/badge/dynamic/json?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsponsorblockcast%2Fconfig.json)
![Ingress](https://img.shields.io/badge/dynamic/json?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsponsorblockcast%2Fconfig.json)
![Arch](https://img.shields.io/badge/dynamic/json?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsponsorblockcast%2Fconfig.json)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20(no%20paypal)-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee%20with%20Paypal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/sponsorblockcast/stats.png)

## About

CastSponsorSkip is a Go program that skips sponsored YouTube content and skippable ads on all local Chromecasts, using the SponsorBlock API. It was inspired by CastBlock but written from scratch to avoid some of its pitfalls (see Differences from CastBlock).

This app is developed by @gabe565 in the [CastSponsorSkip repository](https://github.com/gabe565/CastSponsorSkip).

Feedback from @diamant-x :
> Special attention that it only works when casting to a chromecast a youtube video. It mostly removes manual interaction, can't magically skip ads when they are forced to be viewed.
> Also, it doesn't seem to work when playing on an android tv through native youtube app, which would be a great addition, or on a smartphone.

## Configuration

This addon has no web interface - all configuration is done through addon options.
The addon automatically discovers local Chromecast devices and monitors YouTube playback to skip sponsored content.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `CSS_CATEGORIES` | str | `sponsor, intro, outro, selfpromo` | SponsorBlock categories to skip (comma-separated) |
| `CSS_DISCOVER_INTERVAL` | str | `5m` | Interval to restart the DNS discovery client |
| `CSS_DEVICES` | str | `[]` | Comma-separated list of device addresses; disables discovery |
| `CSS_MUTE_ADS` | bool | `true` | Mutes the device while an ad is playing |
| `CSS_PAUSED_INTERVAL` | str | `1m` | Poll interval when the Cast device is paused |
| `CSS_PLAYING_INTERVAL` | str | `500ms` | Poll interval when the Cast device is playing |
| `CSS_SKIP_SPONSORS` | bool | `true` | Toggle SponsorBlock segment skipping; if disabled only YouTube ads are skipped |
| `CSS_YOUTUBE_API_KEY` | str | `` | YouTube API key for fallback video identification |

### Example Configuration

```yaml
CSS_CATEGORIES: "sponsor, intro, outro, selfpromo, interaction"
CSS_MUTE_ADS: false
CSS_PAUSED_INTERVAL: "30s"
CSS_PLAYING_INTERVAL: "500ms"
CSS_SKIP_SPONSORS: false
CSS_DEVICES: "192.168.1.100,192.168.1.101"
```

### Custom Scripts and Environment Variables

This addon supports custom script execution and environment variable injection:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **Environment variables**: See [Add Environment Variables to your Addon](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon)

### Additional Resources

For detailed configuration options, see [CastSponsorSkip](https://github.com/gabe565/CastSponsorSkip).

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance.
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Carefully configure the add-on to your preferences, see the official documentation for for that.

## Support and issues

Addon : here
App : [CastSponsorSkip](https://github.com/gabe565/CastSponsorSkip)

[repository]: https://github.com/alexbelgium/hassio-addons
