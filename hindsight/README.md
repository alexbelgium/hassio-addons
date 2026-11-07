# Home Assistant add-on: Hindsight

I maintain this and other Home Assistant add-ons in my free time: keeping up with upstream changes, HA changes, and testing on real hardware takes a lot of time (and some money). I use around 5-10 of my >110 addons so regularly I install test machines (and purchase some test services such as vpn) that I don't use myself to troubleshoot and improve the addons.

If this add-on saves you time or makes your setup easier, I would be very grateful for your support!

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Addon informations

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fhindsight%2Fconfig.yaml)
![Ingress](https://img.shields.io/badge/dynamic/yaml?label=Ingress&query=%24.ingress&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fhindsight%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Fhindsight%2Fconfig.yaml)

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/9c6cf10bdbba45ecb202d7f579b5be0e)](https://www.codacy.com/gh/alexbelgium/hassio-addons/dashboard?utm_source=github.com&utm_medium=referral&utm_content=alexbelgium/hassio-addons&utm_campaign=Badge_Grade)
[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.github/stars2.svg)](https://github.com/alexbelgium/hassio-addons/stargazers)

![downloads evolution](https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/hindsight/stats.png)

## About

[Hindsight](https://github.com/vectorize-io/hindsight) is an open-source, self-hosted agent memory system that replaces RAG and Knowledge Graphs with state-of-the-art accuracy. Hindsight equips AI agents with human-like memory that retains, recalls, and reflects on experiences over time.

Key features:

- **Human-Like Memory Operations**: Retain, recall, and reflect on past interactions and documents with high precision and cross-session coherence.
- **Self-Hosted Embedded Storage**: Bundles embedded pg0 (PostgreSQL) data storage mapped to Home Assistant persistent storage with zero external database configuration required.
- **Control Plane Web UI**: Visual dashboard to browse memory banks, inspect stored memories, view entities, and experiment with recall queries.
- **Dataplane REST API**: Fast API exposed on port `8888` for integration with Python, TypeScript, LangChain, LlamaIndex, or custom agent frameworks.
- **Home Assistant Ingress**: One-click access to the Control Plane Web UI directly from the Home Assistant sidebar.

## Installation

1. Add this repository to your Home Assistant instance:
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
2. Install the **Hindsight** add-on.
3. Configure the add-on options (e.g. set your LLM provider and API key).
4. Start the add-on.
5. Click **Open Web UI** to access via Home Assistant Ingress. Direct access on `http://<homeassistant-ip>:9999` is optional (enable port 9999 in the add-on's Network configuration first).

## Configuration

Control Plane Web UI is accessible via Home Assistant Ingress. The Hindsight Dataplane API is exposed on port **8888**.

### Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `HINDSIGHT_API_LLM_PROVIDER` | str | `openai` | LLM provider used for memory consolidation and reflection (e.g. `openai`, `anthropic`, `ollama`, `gemini`). |
| `HINDSIGHT_API_LLM_API_KEY` | password | `""` | API key for the chosen LLM provider. Leave empty if using a local provider without auth. |
| `HINDSIGHT_API_LLM_MODEL` | str | `gpt-4o-mini` | LLM model identifier (e.g. `gpt-4o-mini`, `claude-3-5-haiku-20241022`). |
| `HINDSIGHT_API_LLM_BASE_URL` | str | `""` | Custom API base URL when using local models or custom OpenAI-compatible proxies (e.g. `http://homeassistant.local:11434/v1`). |
| `TZ` | str | `Europe/Paris` | Timezone for the container. |
| `PUID` | int | `0` | User ID for file permissions in `/config`. |
| `PGID` | int | `0` | Group ID for file permissions in `/config`. |
| `env_vars` | list | `[]` | Arbitrary environment variables passed to Hindsight. |

### Connecting Agents & SDKs

Configure your agent frameworks or SDKs to communicate with Hindsight:

- **Dataplane API URL**: `http://<homeassistant-ip>:8888`
- **Control Plane URL**: Ingress or `http://<homeassistant-ip>:9999`
