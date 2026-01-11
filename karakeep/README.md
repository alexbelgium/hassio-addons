
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
