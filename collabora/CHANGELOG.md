
## 25.4.8.1 (2026-01-30)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.7 (2026-01-16)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.8 (2025-12-20)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.7.3 (2025-12-13)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "25.4.7" (2025-11-01)
- Minor bugs fixed

## 25.4.7 (2025-11-01)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.6 (2025-10-04)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
## 25.4.5-12 (2025-09-16)
- Minor bugs fixed
## 25.4.5-11 (2025-08-28)
- Minor bugs fixed
## 25.4.5-10 (2025-08-28)
- Minor bugs fixed
## 25.4.5-7 (2025-08-29)
- Avoid generating default SSL certificate when custom certificates are provided
## 25.4.5-6 (2025-08-28)
- Add option to use own SSL certificates
## 25.4.5-5 (2025-08-27)
- Minor bugs fixed
## 25.4.5-4 (2025-08-27)
- Minor bugs fixed
## 25.4.5-3 (2025-08-25)
- Minor bugs fixed
## 25.4.5-2 (2025-08-25)
- Minor bugs fixed

## 25.4.5 (2025-08-23)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.4 (2025-08-09)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
## 25.04.4.2.2-6 (2025-08-06)
- Minor bugs fixed
## 25.04.4.2.2-5 (2025-08-05)
- Expose additional Collabora environment options
- Persist coolwsd.xml in /config and symlink original path
## 25.04.4.2.2-4 (2025-08-05)
- Minor bugs fixed
## 25.04.4.2.2-3 (2025-08-05)
- Minor bugs fixed
## 25.04.4.2.2-2 (2025-08-04)
- Minor bugs fixed
## 25.04.4.2.2 (2025-08-03)

- Run Collabora as the non-root `cool` user via ha_entrypoint to fix startup failure
- Set ha_entrypoint as container entrypoint and default to `/usr/bin/env`

## 25.04.4.2.1 (2025-08-02)

- Initial release
- Start Collabora Online via service and expose domain/credential options for Nextcloud integration
- Remove unused auto-app installer to prevent build failure
