## 0.6.3 (2026-04-13)
- Simplify ingress nginx to a single `<base href>` rewrite. Upstream now declares `<base href="/">` in `index.html` with Vite `base: './'` and uses relative paths for all internal URLs (built assets, axios `baseURL`, socket.io `path`). The previous seven `sub_filter` rules (href/src/`/api`/`/socket.io`) are no longer needed — one `<base href>` replacement is sufficient.
- Removes incidental brittleness from byte-level `sub_filter` matches in minified JS bundles (the old `/stream/` rule had inadvertently double-prefixed the literal `api.get("/stream/config")` string).
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)

## 0.6.2-2 (11-04-2026)
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
## 0.5.5-2 (04-03-2026)
- Minor bugs fixed

## 0.5.5 (2026-03-02)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.5.4-3 (26-02-2026)
- Minor bugs fixed
## 0.5.4-2 (23-02-2026)
- Fix Icecast service failing to connect to PulseAudio on HAOS by respecting PULSE_SERVER env var and setting up socket symlink and auth cookie for icecast2 user

## 0.5.4 (2026-02-21)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.5.0-6 (15-02-2026)
- Minor bugs fixed
## 0.5.0-5 (15-02-2026)
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
## 0.3.2-6 (01-02-2026)
- Minor bugs fixed
## 0.3.2-5 (01-02-2026)
- Minor bugs fixed
## 0.3.2-4 (31-01-2026)
- Minor bugs fixed
## 0.3.2-2 (31-01-2026)
- Minor bugs fixed

## 0.3.2-3 (2026-01-30)
- Build frontend with /birdnet/ base path and serve under /birdnet/ for ingress compatibility.
## 0.3.2 (2026-01-30)
- Update to latest version from Suncuss/BirdNET-PiPy (changelog : https://github.com/Suncuss/BirdNET-PiPy/releases)
## 0.6.6 (30-01-2026)
- Minor bugs fixed
## 0.6.5 (30-01-2026)
- Minor bugs fixed
## 0.6.3 (29-01-2026)
- Minor bugs fixed
## 0.6.2 (29-01-2026)
- Use upstream nginx.conf and generate ingress config at startup
## 0.6.1 (29-01-2026)
- Minor bugs fixed
## 0.2 (29-01-2026)
- Minor bugs fixed
# Changelog

## 0.1.0

- Initial BirdNET-PiPy add-on with ingress support.
