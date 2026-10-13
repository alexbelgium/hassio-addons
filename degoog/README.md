# Home Assistant Add-on: Degoog

Self-hosted search aggregator: one query, results from many search engines, with themes and a
plugin store.

[Degoog](https://github.com/degoog-org/degoog) works like SearXNG: it sends your search to the
engines you pick and merges what they return. Engines, plugins, themes and autocomplete
providers are installed from its built-in store.

## About

- Results from many engines at once, merged into one page
- Engines, plugins, themes and transports installed from git-based store repositories
- Bangs, shortcuts, autocomplete and an optional local result indexer
- Works as your browser's default search engine (OpenSearch)

## Installation

1. Add this repository to Home Assistant.
2. Install the **Degoog** add-on.
3. Set `DEGOOG_SETTINGS_PASSWORDS` (see below), then start the add-on.
4. Open it from the sidebar (ingress), or at `http://homeassistant:4444`.
5. Go to **Settings → Store** and install at least one search engine: a fresh install has none,
   so searches return no web results until you do.

## Configuration

| Option | Description |
|--------|-------------|
| `DEGOOG_SETTINGS_PASSWORDS` | Password for the settings and admin pages. Several passwords can be given, comma separated. If empty, Degoog generates a new one-off password at every start and prints it in the add-on log. |
| `PUID` / `PGID` | User Degoog runs as, and owner of its data directory. Defaults to `0` (root). |
| `TZ` | Timezone, e.g. `Europe/Paris`. |
| `env_vars` | Extra environment variables passed to Degoog, e.g. `DEGOOG_PUBLIC_INSTANCE` or `DEGOOG_I18N`. See the [upstream list](https://degoog-org.github.io/docs/environment-variables.html) and the [wiki](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2). |

The add-on sets `DEGOOG_BASE_URL`, `DEGOOG_DATA_DIR`, `DEGOOG_PORT` and `DEGOOG_BIND_ADDRESS`
itself, because ingress, the direct port and the health check are built around them: setting
them in `env_vars` has no effect.

## Ingress, direct access and search-engine use

Degoog serves every page under a base path. The add-on sets that base path to the Home Assistant
ingress path, so ingress needs no rewriting, and the bundled nginx maps port `4444` onto the same
path. As a result, pages opened on port `4444` show an address such as
`http://homeassistant:4444/api/hassio_ingress/<token>/search?q=...`. That is expected, and the
short form keeps working too.

To use Degoog as your browser's search engine, use the direct port, not the Home Assistant
sidebar url, for example `http://homeassistant:4444/search?q=%s`. Ingress urls only work inside
a logged-in Home Assistant session.

Behind nginx every client appears to Degoog as `127.0.0.1`, so its per-IP rate limits apply to
all users together. Its bot trap never bans private addresses, so this cannot lock you out. If
you put the add-on behind your own reverse proxy and want per-client limits, add
`DEGOOG_DISTRUST_PROXY=0` in `env_vars`. Degoog then trusts the `X-Forwarded-For` header, which
clients can forge, so only do this when port `4444` is reachable only through your proxy.

## Data

Settings, installed extensions and the index database live in `/config` inside the add-on.
Home Assistant maps that to this add-on's own configuration directory,
`/addon_configs/<repository_id>_degoog`, and it is included in add-on backups. It is the
equivalent of the upstream `./data:/app/data` compose volume, so the contents of an existing
`data` folder can be copied in as is.

## Support

- [Degoog upstream project](https://github.com/degoog-org/degoog)
- [Add-on repository issues](https://github.com/alexbelgium/hassio-addons/issues)
