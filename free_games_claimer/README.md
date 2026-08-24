# Home Assistant add-on: Free Games Claimer

I maintain this and other Home Assistant add-ons in my free time. Keeping up
with upstream changes, Home Assistant changes, and testing on real hardware
takes a significant amount of time.

[![Buy me a coffee][donation-badge]](https://www.buymeacoffee.com/alexbelgium)
[![Donate via PayPal][paypal-badge]](https://www.paypal.com/donate/?hosted_button_id=DZFULJZTP3UQA)

## Add-on information

![Version](https://img.shields.io/badge/dynamic/yaml?label=Version&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffree_games_claimer%2Fconfig.yaml)
![Arch](https://img.shields.io/badge/dynamic/yaml?color=success&label=Arch&query=%24.arch&url=https%3A%2F%2Fraw.githubusercontent.com%2Falexbelgium%2Fhassio-addons%2Fmaster%2Ffree_games_claimer%2Fconfig.yaml)

[![GitHub Super-Linter](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/weekly-supelinter.yaml?label=Lint%20code%20base)](https://github.com/alexbelgium/hassio-addons/actions/workflows/weekly-supelinter.yaml)
[![Builder](https://img.shields.io/github/actions/workflow/status/alexbelgium/hassio-addons/onpush_builder.yaml?label=Builder)](https://github.com/alexbelgium/hassio-addons/actions/workflows/onpush_builder.yaml)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white
[paypal-badge]: https://img.shields.io/badge/Donate%20via%20PayPal-0070BA?logo=paypal&style=flat&logoColor=white

## About

This add-on is based on
[Free Games Claimer Remaster](https://github.com/P-Adamiec/Free-Games-Claimer-Remaster).
It can claim free games from:

- Epic Games Store, including its weekly free mobile game
- Fab, Epic's asset marketplace (`fab`)
- Amazon Prime Gaming
- GOG
- Steam
- Ubisoft giveaways (`ubisoft`)
- AliExpress daily coin check-in (`aliexpress`)
- GamerPower-supported stores, when explicitly enabled

For compatibility with previous add-on releases, the default store selection
remains Epic Games, Prime Gaming, and GOG. The other stores are enabled by
adding them to `STORES`, for example `epic,prime,gog,fab,ubisoft`, and each
needs its own credentials in `config.env`.

## Web interface

The noVNC interface remains available on port `6080`:

```text
http://homeassistant:6080
```

It can be used for initial sign-in, CAPTCHA handling, or other manual browser
interaction. Set `VNC_PASSWORD` in `config.env` to protect the VNC session.

## Add-on options

| Option | Default | Description |
|--------|---------|-------------|
| `CONFIG_LOCATION` | `/config/config.env` | Persistent environment configuration file |
| `RUN_ONCE` | `true` | Run all selected claimers once, then stop the add-on as previous releases did |
| `STORES` | empty | Optional comma-separated override, such as `epic,prime,gog,steam` |
| `CMD_ARGUMENTS` | `node epic-games ; node prime-gaming ; node gog` | Deprecated compatibility option; recognized legacy command names are converted to `STORES` |
| `env_vars` | `[]` | Additional environment variables passed to the add-on |

### Run modes

With `RUN_ONCE: true`, the add-on performs one claiming pass and stops. This is
the default and preserves the behavior of the former vogler-based add-on.

With `RUN_ONCE: false`, the remaster remains running and uses its internal
scheduler. Set `SCHEDULER_HOURS` in `config.env` to control the interval.

## Environment configuration

The add-on keeps its configuration in `CONFIG_LOCATION`, which defaults to
`/config/config.env`. From Home Assistant this is stored in the add-on's
private `addon_configs` directory and can be edited with a compatible file
browser add-on.

A template is created on first start. Common examples are:

```env
# Preserve the former default selection
STORES=epic,prime,gog

# Epic Games
EG_EMAIL=your-email@example.com
EG_PASSWORD=your-password
EG_OTPKEY=

# Amazon Prime Gaming
PG_EMAIL=your-amazon-email@example.com
PG_PASSWORD=your-password
PG_OTPKEY=

# GOG
GOG_EMAIL=your-gog-email@example.com
GOG_PASSWORD=your-password

# Optional Steam support
STEAM_USERNAME=your-steam-username
STEAM_PASSWORD=your-password

# Optional notifications
NOTIFY=tgram://bot-token/chat-id
# DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
```

Upstream's release-update notification (`NOTIFY_UPDATES`) is disabled by the
add-on, because it advises running `docker compose pull` while the add-on is
actually updated through the Home Assistant add-on store. Setting
`NOTIFY_UPDATES=true` in `config.env` re-enables it.

Existing variables such as `EG_EMAIL`, `EG_PASSWORD`, `PG_EMAIL`,
`PG_PASSWORD`, `PG_OTPKEY`, `GOG_EMAIL`, `GOG_PASSWORD`, `SHOW`, `WIDTH`,
`HEIGHT`, `TIMEOUT`, `LOGIN_TIMEOUT`, `DRYRUN`, and `NOTIFY` remain compatible.
See the
[upstream configuration reference](https://github.com/P-Adamiec/Free-Games-Claimer-Remaster#configuration)
for all available settings.

## Upgrade from version 1.8

Version 2.0 changes the application engine from
`vogler/free-games-claimer` (Node.js, Playwright, and Firefox) to
`P-Adamiec/Free-Games-Claimer-Remaster` (Python, nodriver, and Chromium).
The add-on performs the following migration automatically on first start:

1. The existing `config.env` remains at the same configured location.
2. Legacy `epic-games.json`, `prime-gaming.json`, and `gog.json` claim history
   is imported into the remaster SQLite database at `/data/fgc.db`.
3. Existing database rows are detected and are not duplicated if migration is
   retried.
4. A pre-migration database backup is created when an existing `fgc.db` is
   present.
5. All old files remain under `/data/data` for rollback or manual recovery.

Browser sessions cannot be converted because the old add-on used a shared
Firefox profile while the remaster uses separate Chromium profiles per store.
Credentials remain available through `config.env`, but accounts that require
interactive authentication may need a one-time login through noVNC after the
upgrade. The old Firefox profile is retained and is never deleted.

The external noVNC port remains `6080`, although the standalone remaster image
normally uses port `7080`.

## Upstream update policy

The image is built from the upstream release named by `ARG BUILD_UPSTREAM` in
the Dockerfile, downloaded as the matching `v<version>` source tarball. The
repository updater tracks upstream releases and bumps that value, the add-on
version and `CHANGELOG.md` together, so a new upstream release reaches the
add-on without a manual edit while the image contents still never change
without a version bump.

Upstream's development tags (`v1.7d` and similar) carry no GitHub release and
are filtered out through `"github_exclude": "d"` in `updater.json`.

The add-on version does not track the upstream version. The add-on uses a `2.x`
series while upstream is on `1.x`, and Home Assistant only offers an update
when the new version sorts strictly higher, so the updater increments the
add-on version (`2.1.0` to `2.1.1`) instead of publishing a lower-sorting
upstream number. The upstream release actually installed is recorded in
`upstream_version` in `updater.json`, in the `io.hass.upstream` image label,
and in the add-on's startup banner.

## Installation

1. Add this add-on repository to the Home Assistant add-on store.
2. Install **Free Games Claimer**.
3. Configure the add-on options as needed.
4. Start the add-on and review its log.
5. Open noVNC if an account needs manual authentication.

[![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)

## Custom scripts and environment variables

- [Running custom scripts in add-ons](https://github.com/alexbelgium/hassio-addons/wiki/Running-custom-scripts-in-Addons)
- [Passing environment variables to an add-on](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2)

## Support

Open an issue in the
[add-on repository](https://github.com/alexbelgium/hassio-addons/issues).
