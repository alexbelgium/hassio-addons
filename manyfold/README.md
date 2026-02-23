# Manyfold Home Assistant Add-on

This add-on wraps `ghcr.io/manyfold3d/manyfold-solo` for Home Assistant OS with persistent storage and configurable host-backed media paths.

Documentation: [manyfold.app/get-started](https://manyfold.app/get-started/)

## Features

- Runs Manyfold on port `3214`.
- Persists app data, database, cache, and settings under `/config` (`addon_config`).
- Uses a configurable library path on Home Assistant host storage.
- Refuses startup if configured paths resolve outside `/share`, `/media`, or `/config`.
- No external PostgreSQL or Redis required.
- Supports `amd64` and `aarch64`.
- Includes a baseline AppArmor profile.

## Default paths

- Library path: `/share/manyfold/models`
- Thumbnails path: `/config/thumbnails`

## Installation

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
2. Refresh Add-on Store and install **Manyfold**.
3. Configure options (defaults are safe for first run):
   - `library_path`: `/share/manyfold/models`
   - `secret_key_base`: leave blank to auto-generate
   - `puid` / `pgid`: set to a non-root UID/GID (see "Fix root warning (PUID/PGID)" below)
   - optionally tune worker/thread and upload limits in "Small server tuning" below
4. Start the add-on.
5. Open `http://<HA_IP>:3214`.

Before first start, ensure your library folder exists on the host:

```bash
mkdir -p /share/manyfold/models
```

Local development alternative on the HA host:

1. Copy `manyfold/` to `/addons/manyfold`.
2. In Add-on Store menu (`...`), click `Check for updates`.
3. Install and run **Manyfold** from local add-ons.

## Library/index workflow

1. Drop STL/3MF/etc into `/share/manyfold/models` on the host.
2. In Manyfold UI, configure a library that points to the same container path.
3. Thumbnails and indexing artifacts persist in `/config/thumbnails`.

## Options

- `secret_key_base`: App secret. Auto-generated and persisted at `/config/secret_key_base` when empty.
- `puid` / `pgid`: Ownership applied to writable mapped directories (`/config` paths).
- `multiuser`: Toggle Manyfold multiuser mode.
- `library_path`: Scanned/indexed path.
- `thumbnails_path`: Persistent thumbnails/index artifacts (must be under `/config`).
- `log_level`: `info`, `debug`, `warn`, `error`.
- `web_concurrency`: Puma worker process count.
- `rails_max_threads`: Max threads per Puma worker.
- `default_worker_concurrency`: Sidekiq default queue concurrency.
- `performance_worker_concurrency`: Sidekiq performance queue concurrency.
- `max_file_upload_size`: Max uploaded archive size in bytes.
- `max_file_extract_size`: Max extracted archive size in bytes.

## Small server tuning

For low-memory HAOS hosts, start with:

```yaml
web_concurrency: 1
rails_max_threads: 5
default_worker_concurrency: 2
performance_worker_concurrency: 1
max_file_upload_size: 268435456
max_file_extract_size: 536870912
```

Then restart the add-on and increase gradually only if needed.

## Fix root warning (PUID/PGID)

If Manyfold shows:

`Manyfold is running as root, which is a security risk.`

set `puid` and `pgid` in the add-on Configuration tab to a non-root UID/GID.

Example:

```yaml
puid: 1000
pgid: 1000
```

How to find the correct values in Home Assistant:

1. Open the **Terminal & SSH** add-on (or SSH into the HA host).
2. If you know the target Linux user name, run:

```bash
id <username>
```

Use the `uid=` value for `puid` and `gid=` value for `pgid`.

If you do not have a specific username, use the owner of the Manyfold folders:

```bash
stat -c '%u %g' /share/manyfold/models
```

Set `puid`/`pgid` to those numbers.

After changing values:

1. Save add-on Configuration.
2. Restart the Manyfold add-on.
3. Check logs for `puid:pgid=<uid>:<gid>` and confirm the warning is gone.

## Validation behavior

- Startup fails if `library_path` or `thumbnails_path` resolve outside mapped storage roots.
- `thumbnails_path` must resolve under `/config` to guarantee persistence.
- Startup fails if `library_path` is not readable.

## Notes

- This baseline avoids Home Assistant ingress and keeps direct port access.
- If `puid`/`pgid` change, restart the add-on to re-apply ownership to mapped directories.
