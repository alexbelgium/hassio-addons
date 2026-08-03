## 2.1.37-4 (2026-01-08)
- Automatic login with ingress
- Align configuration mapping with addon_config and homeassistant_config
- Migrate legacy /homeassistant/addons_config/joal data to the addon config folder

## 2.1.37 (2025-12-23)
- Update to latest version from anthonyraymond/joal (changelog : https://github.com/anthonyraymond/joal/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.1.36 (2023-11-04)

- Update to latest version from anthonyraymond/joal

## 2.1.34 (2023-05-27)

- Update to latest version from anthonyraymond/joal
- Implemented healthcheck

## 2.1.33 (2022-12-01)

- Update to latest version from anthonyraymond/joal
- WARNING : update to supervisor 2022.11 before installing

## 2.1.32 (2022-11-05)

- Update to latest version from anthonyraymond/joal

## 2.1.31 (2022-08-04)

- Update to latest version from anthonyraymond/joal

## 2.1.30 (2022-04-19)

- Update to latest version from anthonyraymond/joal
- Add codenotary sign

## 2.1.29 (2021-12-23)

- Update to latest version from anthonyraymond/joal

## 2.1.28 (2021-12-14)

- Update to latest version from anthonyraymond/joal
- New standardized logic for Dockerfile build and packages installation

## 2.1.27 (2021-11-17)

- Update to latest version from anthonyraymond/joal

## 2.1.26 (2021-07-18)

- Update to latest version from anthonyraymond/joal
- config exposed in /config/joal

## 2.1.24

- Update to latest version from anthonyraymond/joal
- Add ingress
- Add option for auto stop after x time
- Add option for setting a custom path
- Add option for setting a custom secret key
