# Home assistant add-on: Social to Mealie

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsocial_to_mealie%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsocial_to_mealie%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fsocial_to_mealie%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/social_to_mealie/stats.png)

## About

[Social to Mealie](https://github.com/GerardPolloRebozado/social-to-mealie) lets you import recipes from social media videos directly into your Mealie instance.

This addon is based on the docker image https://github.com/GerardPolloRebozado/social-to-mealie

## Installation

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.

## Configuration

Webui can be found at <http://homeassistant:3000>.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `OPENAI_URL` | str | `https://api.openai.com/v1` | URL for the OpenAI-compatible endpoint |
| `OPENAI_API_KEY` | str | `` | API key for the OpenAI-compatible provider |
| `TRANSCRIPTION_MODEL` | str | `whisper-1` | Whisper model to use for transcription |
| `TEXT_MODEL` | str | `gpt-4o-mini` | Text model used to build the recipe |
| `MEALIE_URL` | str | `https://mealie.example.com` | URL of your Mealie instance |
| `MEALIE_API_KEY` | str | `` | API key for Mealie |
| `MEALIE_GROUP_NAME` | str | `home` | Optional Mealie group name |
| `EXTRA_PROMPT` | str | `` | Additional instructions for the AI |
| `YTDLP_VERSION` | str | `latest` | yt-dlp version to download at startup |
| `COOKIES` | str | `` | Optional cookies string for yt-dlp |
| `env_vars` | list | `[]` | Additional environment variables to export |

### Example Configuration

```yaml
OPENAI_URL: https://api.openai.com/v1
OPENAI_API_KEY: sk-...
TRANSCRIPTION_MODEL: whisper-1
TEXT_MODEL: gpt-4o-mini
MEALIE_URL: https://mealie.example.com
MEALIE_API_KEY: ey...
MEALIE_GROUP_NAME: home
EXTRA_PROMPT: ""
YTDLP_VERSION: latest
COOKIES: ""
env_vars: []
```

### Notes

- Mealie 1.9.0+ with an AI provider configured is required.
- yt-dlp can be pre-downloaded by setting `YTDLP_VERSION` (for example `latest` or `2025.11.01`).
- Provide the cookies string if you need to access protected social media content with yt-dlp.
