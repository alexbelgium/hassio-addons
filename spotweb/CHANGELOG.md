- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 1.5.8-5 (2025-01-13)
- Allow non ssl servers
- Use /usr/bin/maria instead of mysql

## 1.5.8 (2024-12-21)
- Update to latest version from spotweb/spotweb (changelog : https://github.com/spotweb/spotweb/releases)

## 1.5.7 (2024-11-30)
- Update to latest version from spotweb/spotweb (changelog : https://github.com/spotweb/spotweb/releases)

## 1.5.6 (2024-11-23)
- Update to latest version from spotweb/spotweb (changelog : https://github.com/spotweb/spotweb/releases)
## 1.5.5-6 (2024-10-28)
- Minor bugs fixed
## 1.5.5-5 (2024-10-27)
- Minor bugs fixed
## 1.5.5-4 (2024-10-27)
- Minor bugs fixed
## 1.5.5-3 (2024-10-27)
- Minor bugs fixed
## 1.5.5-2 (2024-10-27)
- Minor bugs fixed

## 1.5.5 (2024-10-26)
- Update to latest version from spotweb/spotweb (changelog : https://github.com/spotweb/spotweb/releases)

## 1.5.4-10 (2023-12-04)

- Minor bugs fixed
- Fix : images not loading https://github.com/alexbelgium/hassio-addons/issues/1051

## 1.5.4-9 (2023-09-23)

- Minor bugs fixed
- Enable external port by default (9999)
- Redirect crond messages https://github.com/alexbelgium/hassio-addons/issues/999

## 1.5.4 (2023-01-07)

- Update to latest version from spotweb/spotweb

## 1.5.3 (2022-11-27)

- Update to latest version from spotweb/spotweb
- WARNING : update to supervisor 2022.11 before installing

## 1.5.2 (2022-11-08)

- Update to latest version from spotweb/spotweb
- Avoid base_url
- Corrects permissions for s6 v3
- Avoid mixed content error
- Allow import of /config/addons_config/spotweb/ownsettings.php
- Add codenotary sign
- Show cron jobs status in log
- Run check-cache at bootup

## 1.5.1 (2022-01-22)

- Update to latest version from spotweb/spotweb
- Initial version
