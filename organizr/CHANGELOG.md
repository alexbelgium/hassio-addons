
## 1.601 (22-11-2025)
- Update to latest version from causefx/organizr (changelog : https://github.com/causefx/organizr/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

- WARNING : update to supervisor 2022.11 before installing
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation
- Initial build
