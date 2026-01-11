# Home assistant add-on: Karakeep

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fkarakeep%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fkarakeep%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fkarakeep%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

[Karakeep](https://karakeep.app/) is a bookmark-everything app with a touch of AI for the data hoarders out there. It stores content, screenshots, and metadata with search powered by Meilisearch.

This addon is based on the [official Karakeep Docker image](https://github.com/karakeep-app/karakeep).

## Configuration

Webui can be found at `<your-ip>:3000`.

### Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `NEXTAUTH_SECRET` | password | | Secret key for authentication (auto-generated if left blank). |
| `NEXTAUTH_URL` | str | | Public URL used by NextAuth (optional). |
| `DISABLE_SIGNUPS` | bool | `false` | Disable new account signups. |
| `MAX_ASSET_SIZE_MB` | int | `4` | Max asset upload size. |
| `OCR_LANGS` | str | | OCR language codes (comma-separated). |
| `OCR_CONFIDENCE_THRESHOLD` | int | | OCR confidence threshold (0-100). |
| `OPENAI_BASE_URL` | str | | Custom OpenAI base URL. |
| `OPENAI_API_KEY` | password | | OpenAI API key. |
| `OLLAMA_BASE_URL` | str | | Ollama base URL. |
| `INFERENCE_TEXT_MODEL` | str | | Text inference model name. |
| `INFERENCE_IMAGE_MODEL` | str | | Image inference model name. |
| `EMBEDDING_TEXT_MODEL` | str | | Embedding model name. |
| `INFERENCE_CONTEXT_LENGTH` | int | | Inference context length. |
| `INFERENCE_LANG` | str | | Language used for inference. |
| `INFERENCE_JOB_TIMEOUT_SEC` | int | | Timeout for inference jobs. |
| `CRAWLER_DOWNLOAD_BANNER_IMAGE` | bool | `true` | Download banner image during crawl. |
| `CRAWLER_STORE_SCREENSHOT` | bool | `false` | Store screenshot during crawl. |
| `CRAWLER_FULL_PAGE_SCREENSHOT` | bool | `false` | Capture full-page screenshots. |
| `CRAWLER_FULL_PAGE_ARCHIVE` | bool | `false` | Store full-page archive. |
| `CRAWLER_JOB_TIMEOUT_SEC` | int | | Crawler job timeout. |
| `CRAWLER_NAVIGATE_TIMEOUT_SEC` | int | | Navigation timeout. |
| `CRAWLER_VIDEO_DOWNLOAD` | bool | | Enable video downloads. |
| `CRAWLER_VIDEO_DOWNLOAD_MAX_SIZE` | int | | Max video size (MB). |
| `CRAWLER_VIDEO_DOWNLOAD_TIMEOUT_SEC` | int | | Video download timeout. |
| `CRAWLER_ENABLE_ADBLOCKER` | bool | `true` | Enable ad blocking in the crawler. |
| `CHROME_EXTENSIONS_DIR` | str | `/share/karakeep/extensions` | Host-mounted extensions directory for headless Chromium. |
| `MEILI_MASTER_KEY` | password | | Meilisearch master key (auto-generated if left blank). |
| `MEILI_ADDR` | str | | Meilisearch URL. |
| `BROWSER_WEB_URL` | str | | Chromium remote debugging URL. |
| `DATA_DIR` | str | | Data directory (leave default). |
| `TZ` | str | `Etc/UTC` | Timezone. |

### Extensions for headless Chromium

This add-on loads extensions in headless Chromium with the `--headless=new` flag. To use the included defaults:

1. Create these folders on the host (via the `/share` mount):
   - `/share/karakeep/extensions/i-dont-care-about-cookies`
   - `/share/karakeep/extensions/ublock-origin`
2. Unzip each extension into its corresponding folder.
3. Restart the add-on.

You can override the base folder with the `CHROME_EXTENSIONS_DIR` option. Any missing extension folder is skipped at runtime.

### Custom Scripts and Environment Variables

This addon supports custom scripts and environment variables through the `addon_config` mapping:

- **Custom scripts**: See [Running Custom Scripts in Addons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- **env_vars option**: Use the add-on `env_vars` option to pass extra environment variables (uppercase or lowercase names). See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## Installation

The installation of this add-on is pretty straightforward and not different in
comparison to installing any other Hass.io add-on.

1. [Add my Hass.io add-ons repository][repository] to your Hass.io instance. [![Add repository on my Home Assistant][repository-badge]][repository-url]
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Start the add-on (secrets are auto-generated if left blank).
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and complete the onboarding.

## Support

Create an issue on GitHub if you need support.

[repository]: https://github.com/alexbelgium/hassio-addons
[repository-badge]: https://img.shields.io/badge/Add%20repository%20to%20my-Home%20Assistant-41BDF5?logo=home-assistant&style=for-the-badge
[repository-url]: https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons
