 
## 1.26.3 (2026-08-13)
- Update to latest version from gotson/komga (changelog : https://github.com/gotson/komga/releases)
## 1.26.1.4 (12-08-2026)
- Minor bugs fixed
## 1.26.1.3 (2026-08-12)

- Fix : 401 errors after a successful login through ingress. Komga scopes its session cookies to its servlet context path (`Path=/komga`), which the browser never sends back from the ingress url, so every request after the login was anonymous. Nginx now rewrites the cookie path onto the ingress entry

## 1.26.1.2 (2026-08-12)

- Fix : local disks (`localdisks`) and SMB shares failed to mount with `cannot mount /dev/sdX read-only`. Without an `apparmor.txt` the add-on ran under Docker's default AppArmor profile, which denies `mount` and raw block device access. Ships the same profile as the other add-ons that mount disks

## 1.26.1.1 (2026-08-11)

- Bound the nginx readiness probes (`--connect-timeout` / `--max-time`) so a stalled connection cannot hang the wait, and log a warning when Komga has not answered within 15 minutes

## 1.26.1 (2026-08-11)

- Initial release, based on gotson/komga ([changelog](https://github.com/gotson/komga/releases))
- Ingress support : Komga is served on the `/komga` servlet context path, nginx prefixes it back with the ingress entry
- Supports local disks and SMB network shares for libraries (`localdisks` / `networkdisks` options)
- Supports extra environment variables via the `env_vars` option, see the [documentation](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2)
