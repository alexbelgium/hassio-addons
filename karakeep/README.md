# Home assistant add-on: Karakeep

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, Home Assistant changes, and testing on real hardware takes a lot of time (and some money). I use around 5–10 of my >110 addons so regularly I install test machines (and purchase some test services such as VPNs) that I do not use myself, in order to troubleshoot and improve the addons.

If this add-on saves you time or makes your setup easier, I would be very grateful for your support.

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fkarakeep%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fkarakeep%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone who has starred my repo!_

[![Stargazers repo roster](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

---

## About

[Karakeep](https://karakeep.app/) is a bookmark-everything app with a touch of AI for data hoarders.  
It stores pages, screenshots, files, and metadata with fast full-text and semantic search powered by **Meilisearch**.

This add-on is based on the official Karakeep Docker image.

This Home Assistant add-on integrates Karakeep in a **Supervisor-native way**:
- Internal services (Meilisearch, Chromium, cache, paths) are pre-wired and hidden from the UI
- Secrets are **auto-generated and persisted**
- Only meaningful user settings are exposed

---

## Secrets & Security

Two secrets are required for Karakeep to work securely:

- `NEXTAUTH_SECRET`
- `MEILI_MASTER_KEY`

If you leave them empty, the add-on will:
- Generate strong cryptographic secrets automatically
- Store them permanently in the add-on options
- Reuse them across restarts and upgrades

You do **not** need to manage them manually.

---

## Configuration

Only **safe, meaningful options** are exposed.  
All infrastructure (Meilisearch, Chromium, cache, paths, analytics, etc.) is managed automatically by the add-on.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `NEXTAUTH_SECRET` | password | *(auto)* | Authentication secret (auto-generated if empty). |
| `NEXTAUTH_URL` | str | | Public URL used by NextAuth (optional). |
| `DISABLE_SIGNUPS` | bool | `false` | Disable new user signups. |
| `MAX_ASSET_SIZE_MB` | int | `4` | Maximum asset upload size. |
| `OPENAI_API_KEY` | password | | OpenAI API key for AI features. |
| `OCR_LANGS` | str | | OCR languages (comma separated). |
| `INFERENCE_LANG` | str | | Language used for AI inference. |
| `CRAWLER_DOWNLOAD_BANNER_IMAGE` | bool | `true` | Download banner image. |
| `CRAWLER_STORE_SCREENSHOT` | bool | `true` | Store page screenshots. |
| `CRAWLER_FULL_PAGE_SCREENSHOT` | bool | `true` | Capture full-page screenshots. |
| `CRAWLER_FULL_PAGE_ARCHIVE` | bool | `true` | Store full-page archive. |
| `CRAWLER_ENABLE_ADBLOCKER` | bool | `true` | Enable ad blocking. |
| `CRAWLER_VIDEO_DOWNLOAD` | bool | `false` | Enable video downloads. |
| `TZ` | str | `Etc/UTC` | Timezone. |

---

## Installation

1. Add my Home Assistant add-ons repository  
   [![Add repository][repository-badge]][repository-url]

2. Install **Karakeep**
3. Click **Save**
4. Start the add-on (secrets are auto-generated)
5. Open the Web UI and complete onboarding

---

## Support

Create an issue on GitHub if you need help.

[repository]: https://github.com/alexbelgium/hassio-addons
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons
