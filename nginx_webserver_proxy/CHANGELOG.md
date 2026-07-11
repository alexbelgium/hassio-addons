# Changelog

## 2.14.1-1 (11-07-2026)
- Persist Let's Encrypt certificates across restarts by symlinking /etc/letsencrypt to /data/letsencrypt (#2828) — thanks to @crazyrokr for reporting and suggesting the fix

## 2.14.1 (19-06-2026)
- Fix startup failure on aarch64/HAos: "/usr/bin/env: 'bash': Permission denied" (#2777)
- Add s6-overlay/env/with-contenv exec rules to AppArmor profile

## 2.14.0 (01-05-2026)
- Initial release wrapping jc21/nginx-proxy-manager:latest
- NPM Admin UI on port 81; HTTP on port 80; HTTPS on port 443
- Configurable static file server via NPM's default_host nginx config
- Supports /share, /media, /config paths; warns for /mnt; blocks dangerous system paths
- NPM state persisted via Docker volume (managed by HA Supervisor)
- Supports amd64 and aarch64
