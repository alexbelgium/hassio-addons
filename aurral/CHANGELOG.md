# Changelog

## 1.76.17-2

- Fix regression: call `node` directly from s6 run script instead of going
  through the upstream `docker-entrypoint.sh` wrapper, which was running
  a `chown -R` on `/app/backend/data` before our symlink was in place and
  could fail on HA-mounted paths
- Remove redundant `ENTRYPOINT`/`CMD` from Dockerfile (s6 owns startup)
- Remove passthrough `docker-entrypoint.sh` override (no longer needed)
- Pre-create `weekly-flow` subdirectory in run script

## 1.76.17-1

- Pin to upstream 1.76.17
- Fix AppArmor profile: add `/config/aurral/** rwk` for addon_config writes
- Remove ingress / sidebar button (upstream CSP blocks iframe embedding)

## 1.76.12-1

- Initial release wrapping upstream ghcr.io/lklynet/aurral
- Persistent data via `addon_config` map (`/config/data`)
- User-configurable `download_folder` (default `/share/aurral/downloads`)
