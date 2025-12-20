
## 25.4.8 (20-12-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.7.3 (13-12-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## "25.4.7" (01-11-2025)
- Minor bugs fixed

## 25.4.7 (01-11-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.6 (04-10-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
## 25.4.5-12 (16-09-2025)
- Minor bugs fixed
## 25.4.5-11 (28-08-2025)
- Minor bugs fixed
## 25.4.5-10 (28-08-2025)
- Minor bugs fixed
## 25.4.5-7 (29-08-2025)
- Avoid generating default SSL certificate when custom certificates are provided
## 25.4.5-6 (28-08-2025)
- Add option to use own SSL certificates
## 25.4.5-5 (27-08-2025)
- Minor bugs fixed
## 25.4.5-4 (27-08-2025)
- Minor bugs fixed
## 25.4.5-3 (25-08-2025)
- Minor bugs fixed
## 25.4.5-2 (25-08-2025)
- Minor bugs fixed

## 25.4.5 (23-08-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.4 (09-08-2025)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
## 25.04.4.2.2-6 (06-08-2025)
- Minor bugs fixed
## 25.04.4.2.2-5 (05-08-2025)
- Expose additional Collabora environment options
- Persist coolwsd.xml in /config and symlink original path
## 25.04.4.2.2-4 (05-08-2025)
- Minor bugs fixed
## 25.04.4.2.2-3 (05-08-2025)
- Minor bugs fixed
## 25.04.4.2.2-2 (04-08-2025)
- Minor bugs fixed
## 25.04.4.2.2 (03-08-2025)

- Run Collabora as the non-root `cool` user via ha_entrypoint to fix startup failure
- Set ha_entrypoint as container entrypoint and default to `/usr/bin/env`

## 25.04.4.2.1 (02-08-2025)

- Initial release
- Start Collabora Online via service and expose domain/credential options for Nextcloud integration
- Remove unused auto-app installer to prevent build failure
