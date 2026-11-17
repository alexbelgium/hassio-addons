## 1.0.0.3 (2026-11-17)
- Fix the network interface autodetection, which ran only when interface_name was already set instead of when it was empty

- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

- Implemented healthcheck
- WARNING : update to supervisor 2022.11 before installing
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation

## 1.0.0 (2021-12-07)

- Update to latest version from t0mer/Arpspoof-Docker
- Initial release
