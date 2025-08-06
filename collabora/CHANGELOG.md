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
