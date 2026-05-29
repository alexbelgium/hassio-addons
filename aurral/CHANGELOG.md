
## 1.76.40 (2026-05-30)
- Update to latest version from lklynet/aurral (changelog : https://github.com/lklynet/aurral/releases)
## 1.76.17-2 (21-05-2026)
- Minor bugs fixed
## 1.76.17-1 (21-05-2026)
- Minor bugs fixed
# Changelog

## 1.76.17-2

- Fix entrypoint: use HA-injected env vars instead of bashio (not available in upstream image)
- Restore mkdir for persistent data/download directories

## 1.76.17-1

- Add `weekly_flow_folder` option (configurable subfolder for weekly flow files)
- Fix addon config schema (`env_vars` -> `environment`)
- Add image tag for alexbelgium build pipeline

## 1.76.17

- Initial release
