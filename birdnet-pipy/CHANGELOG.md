## 0.6.6-4 (2026-05-02)
- Fix nginx startup: wait for the upstream API on `127.0.0.1:5002` before starting nginx, instead of the prior `sleep 5` workaround. Under s6-overlay all `services.d/*` services start concurrently, so nginx could begin accepting requests before `core.api` had bound its port — `/api/`, `/socket.io/`, and `/internal/auth` would then return 502, and that 502 could be cached by an upstream service worker / edge cache (e.g. behind Cloudflare-fronted HA), leaving the UI stuck blank. Uses `bashio::net.wait_for` to match the pattern in sister addons (`bazarr`, `jellyfin`, `radarr`).
## 0.6.6-3 (23-04-2026)
- Minor bugs fixed
## 0.6.6-2 (23-04-2026)
- Minor bugs fixed

## 0.6.6 (2026-04-21)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.6.4 (2026-04-18)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.6.3-3 (2026-04-17)
- Enable Core API access (`homeassistant_api: true`) so the addon can call HA Core's `update.install` service. Required for in-app self-update — Supervisor blocks `/store/addons/<self>/update`, so the backend routes through Core.

## 0.6.3-2 (2026-04-15)
- Remove the `TZ` add-on option. Application timezone is now auto-derived in the Web UI from the station location (latitude/longitude) via `timezonefinder`, so a separately-configured container `TZ` only ever duplicated — and occasionally conflicted with — the UI-derived zone. All app-facing timestamps (dashboard, API responses, database) and Python service stdout (`api`/`main`/`birdnet`) already honor the UI-derived zone via the logging formatter; the frontend log viewer also re-converts Icecast timestamps on read. Net effect in the HA addon log pane: Python logs keep their local-time timestamps; only Icecast's raw stdout now prints in UTC — an intentional trade for a single source of truth. Deletes the now-redundant `rootfs/etc/cont-init.d/02-timezone.sh` added in 0.5.6-2.
- Clean up the options YAML in DOCS.md and README.md. Removed `RECORDING_MODE` and `RTSP_URL` — these were documented as addon options but never wired: the app reads them from `user_settings.json` (configured via the Web UI), not from env vars. Also dropped `http_stream` from the list of modes (only `pulseaudio` and `rtsp` remain in `backend/config/constants.py`). Moved `STREAM_BITRATE` under an `env_vars:` example since it's honored by `start-icecast.sh` but has never been a first-class option in the schema.

## 0.6.3 (2026-04-13)
- Simplify ingress nginx to a single `<base href>` rewrite. Upstream now declares `<base href="/">` in `index.html` with Vite `base: './'` and uses relative paths for all internal URLs (built assets, axios `baseURL`, socket.io `path`). The previous seven `sub_filter` rules (href/src/`/api`/`/socket.io`) are no longer needed — one `<base href>` replacement is sufficient.
- Removes incidental brittleness from byte-level `sub_filter` matches in minified JS bundles (the old `/stream/` rule had inadvertently double-prefixed the literal `api.get("/stream/config")` string).
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.6.2-2 (2026-04-11)
- Minor bugs fixed

## 0.6.2 (2026-04-11)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
- Fix Icecast crashing on startup due to log directory permissions (502 Bad Gateway on Live Feed)
- Fix Live Feed broken in ingress mode — stream config request was double-prefixed by sub_filter

## 0.6.1 (2026-04-06)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.6.0 (2026-04-04)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.5.8 (2026-03-26)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.5.7 (2026-03-14)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.5.6-2 (2026-03-11)
- Add container timezone management: TZ option now properly configures the container timezone (symlinks /etc/localtime, writes /etc/timezone, exports to s6 environment)
- Change default timezone from Etc/UTC to Europe/Paris

## 0.5.6 (2026-03-07)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.5.5-2 (2026-03-04)
- Minor bugs fixed

## 0.5.5 (2026-03-02)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.5.4-3 (2026-02-26)
- Minor bugs fixed
## 0.5.4-2 (2026-02-23)
- Fix Icecast service failing to connect to PulseAudio on HAOS by respecting PULSE_SERVER env var and setting up socket symlink and auth cookie for icecast2 user

## 0.5.4 (2026-02-21)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.5.0-6 (2026-02-15)
- Minor bugs fixed
## 0.5.0-5 (2026-02-15)
- Minor bugs fixed
## 0.5.0-4 (2026-02-15)
- Disable nginx service when ingress is not active

## 0.5.0-3 (2026-02-15)
- Fix nginx startup without ingress by removing templated resolver dependency

## 0.5.0-2 (2026-02-14)
- Skip ingress nginx configuration when ingress is not active (empty/invalid ingress port)

## 0.5.0 (2026-02-14)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.4.0 (2026-02-07)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.3.2-6 (2026-02-01)
- Minor bugs fixed
## 0.3.2-5 (2026-02-01)
- Minor bugs fixed
## 0.3.2-4 (2026-01-31)
- Minor bugs fixed
## 0.3.2-2 (2026-01-31)
- Minor bugs fixed

## 0.3.2-3 (2026-01-30)
- Build frontend with /birdnet/ base path and serve under /birdnet/ for ingress compatibility.
## 0.3.2 (2026-01-30)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

# Changelog

## 0.1.0

- Initial BirdNET-PiPy add-on with ingress support.
