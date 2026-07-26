 
## 26.04.2.4.1 (2026-07-26)
- Fix version numbering: releases on CollaboraOnline/online are now Helm charts only, which had renumbered the addon from 25.4.9.2 down to 1.3.0 and hid updates. The version is tracked from the collabora/code Docker Hub tags again
- `server_name` is now passed to Collabora, fixing `Your browser has been unable to connect to the Collabora server` behind a reverse proxy
- `domain1` was never passed to Collabora at all (the script read a `domain` option that does not exist, and recent Collabora releases dropped that variable). It is now deprecated and applied as `server_name`
- `aliasgroup*` values are normalised: unescaped, escaped and double-escaped dots all produce the correct regex, and the value handed to Collabora is printed in the log
- Added `ssl_termination`, needed when `ssl` is false but Collabora is reached over https through a reverse proxy
- Added `aliasgroup2` and `aliasgroup3` for additional Nextcloud servers
- `cert_domain` is now a string (it is a certificate common name) and is passed to Collabora
- Documented the above, and corrected the README which asked for two backslashes where Collabora expects one
 
## 1.3.0 (2026-07-16)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
 
## 1.2.2 (2026-07-04)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
 
## 1.2.1 (2026-06-27)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)
 
## 1.2.0 (2026-06-23)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.9.2 (2026-03-14)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

## 25.4.9 (2026-02-14)
- Update to latest version from CollaboraOnline/online (changelog : https://github.com/CollaboraOnline/online/releases)

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
