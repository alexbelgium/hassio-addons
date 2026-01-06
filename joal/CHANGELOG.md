## 2.1.37-3 (06-01-2026)
- Minor bugs fixed

## 2.1.37-2 (05-01-2026)
- Align configuration mapping with addon_config and homeassistant_config
- Migrate legacy /homeassistant/addons_config/joal data to the addon config folder

## 2.1.37 (23-12-2025)
- Update to latest version from anthonyraymond/joal (changelog : https://github.com/anthonyraymond/joal/releases)
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 2.1.36 (04-11-2023)

- Update to latest version from anthonyraymond/joal

## 2.1.34 (27-05-2023)

- Update to latest version from anthonyraymond/joal
- Implemented healthcheck

## 2.1.33 (01-12-2022)

- Update to latest version from anthonyraymond/joal
- WARNING : update to supervisor 2022.11 before installing

## 2.1.32 (05-11-2022)

- Update to latest version from anthonyraymond/joal

## 2.1.31 (04-08-2022)

- Update to latest version from anthonyraymond/joal

## 2.1.30 (19-04-2022)

- Update to latest version from anthonyraymond/joal
- Add codenotary sign

## 2.1.29 (23-12-2021)

- Update to latest version from anthonyraymond/joal

## 2.1.28 (14-12-2021)

- Update to latest version from anthonyraymond/joal
- New standardized logic for Dockerfile build and packages installation

## 2.1.27 (17-11-2021)

- Update to latest version from anthonyraymond/joal

## 2.1.26 (18-07-2021)

- Update to latest version from anthonyraymond/joal
- config exposed in /config/joal

## 2.1.24

- Update to latest version from anthonyraymond/joal
- Add ingress
- Add option for auto stop after x time
- Add option for setting a custom path
- Add option for setting a custom secret key
