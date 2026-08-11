## 1.26.1.1 (2026-08-11)

- Bound the nginx readiness probes (`--connect-timeout` / `--max-time`) so a stalled connection cannot hang the wait, and log a warning when Komga has not answered within 15 minutes

## 1.26.1 (2026-08-11)

- Initial release, based on gotson/komga ([changelog](https://github.com/gotson/komga/releases))
- Ingress support : Komga is served on the `/komga` servlet context path, nginx prefixes it back with the ingress entry
- Supports local disks and SMB network shares for libraries (`localdisks` / `networkdisks` options)
- Supports extra environment variables via the `env_vars` option, see the [documentation](https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2)
