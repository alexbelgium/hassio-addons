# Changelog

## 1.76.17-1

- Bump upstream to `ghcr.io/lklynet/aurral:v1.76.17`
- Pin Docker image to versioned tag (previously used `latest`)
- Fix AppArmor profile to allow writes to `/config/aurral/**` (addon_config mount)
- Remove ingress / sidebar support (not functional)

## 1.76.12-1

- Initial Home Assistant add-on release
- Wraps upstream `ghcr.io/lklynet/aurral:v1.76.12`
- Exposes `download_folder` as a configurable path in the add-on UI
- Supports amd64 and aarch64
