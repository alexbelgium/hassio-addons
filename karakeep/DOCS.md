# Home Assistant add-on: Karakeep (all-in-one) 💾 by Fabio Garavini

The Karakeep Addon is a bookmark-everything app with a touch of AI, designed specifically for data hoarders. This addon allows you to save and organize your favorite bookmarks, with features like AI-powered search and recommendation.

## Configuration

- `NEXTAUTH_URL`: The URL of the Karakeep instance. Example `http://<homeassistant-ip>:3011`.
- `TZ`: The timezone to use for the addon. Example `Europe/Rome`.
- `DISABLE_SIGNUPS`: Whether to disable signups for new users. Defaults to `false`.
- `NEXTAUTH_SECRET`: A secret key used for authentication. Defaults to a random value.
- `MAX_ASSET_SIZE_MB`: The maximum size of assets (e.g. images) that can be uploaded. Defaults to `4`.
- `OCR_LANGS`: A comma-separated list of languages to use for optical character recognition (OCR). Defaults to `eng`.
- `OCR_CONFIDENCE_THRESHOLD`: The minimum confidence threshold for OCR results. Defaults to `50`.
- `OPENAI_API_KEY`: An API key for OpenAI. Optional.
- `OPENAI_BASE_URL`: The base URL of the OpenAI API. Optional.
- `OLLAMA_BASE_URL`: The base URL of the OLLAMA API. Optional.
- `INFERENCE_TEXT_MODEL`: The text model to use for inference. Defaults to `gpt-4o-mini`.
- `INFERENCE_IMAGE_MODEL`: The image model to use for inference. Defaults to `gpt-4o-mini`.
- `EMBEDDING_TEXT_MODEL`: The text model to use for embedding. Defaults to `text-embedding-3-small`.
- `INFERENCE_CONTEXT_LENGTH`: The length of the context to use for inference. Defaults to `2048`.
- `INFERENCE_LANG`: The language to use for inference. Defaults to `english`.
- `INFERENCE_JOB_TIMEOUT_SEC`: The timeout for inference jobs in seconds. Defaults to `30`.

More informations about other configs can be found in the [official documentation](https://docs.karakeep.app/configuration)

## Ports

The Karakeep Addon exposes the following ports:

- `3000/tcp`: The web UI port.

## Installation

To install the Karakeep Addon, follow these steps:

1. Open the Home Assistant UI and navigate to the Add-ons page.
1. Click the "Karakeep" addon.
1. Click the "Install" button.
1. (Optional) under `Configuration` set `NEXTAUTH_URL` as specified above
1. Click the "Open Web UI" button.
1. Create a new user.
1. Happy hoarding!
