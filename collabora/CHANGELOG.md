## 25.04.4.2.3 (04-08-2025)

- Use runuser/su to drop privileges instead of s6-setuidgid

## 25.04.4.2.2 (03-08-2025)

- Run Collabora as the non-root `cool` user via ha_entrypoint to fix startup failure
- Set ha_entrypoint as container entrypoint and default to `/usr/bin/env`

## 25.04.4.2.1 (02-08-2025)

- Initial release
- Start Collabora Online via service and expose domain/credential options for Nextcloud integration
- Remove unused auto-app installer to prevent build failure
