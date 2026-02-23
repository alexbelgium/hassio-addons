
## v1.30.1 (2026-02-23)
- Update to latest version from Starosdev/scrutiny (changelog : https://github.com/Starosdev/scrutiny/releases)

## v1.28.0 (2026-02-21)
- Update to latest version from Starosdev/scrutiny (changelog : https://github.com/Starosdev/scrutiny/releases)

## v1.23.3 (2026-02-14)
- Update to latest version from Starosdev/scrutiny (changelog : https://github.com/Starosdev/scrutiny/releases)
## v1.23.2-2 (08-02-2026)
- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## v1.23.2 (2026-02-08)
- Switch upstream to https://github.com/Starosdev/scrutiny

## v0.8.1-12 (2025-08-16)
- Replace s6-based shutdown with standard command to avoid s6-svwait error

## v0.8.1-11 (2025-08-15)
- Minor bugs fixed
## v0.8.1-10 (2025-08-13)
- Disable port by default for security purposes; it can be readded from the addon options. Ingress access is not affected @soosp
- Document internal domain name for accessing the REST API without exposing the port.

## v0.8.1-9 (2024-11-14)
- Align behavior with other addons : map /addons_config/xxx-scrutiny to enable env injection or custom scripts

## v0.8.1-8 (2024-11-13)
- Minor bugs fixed
## v0.8.1-7 (2024-11-13)
- New feature : if you select "Custom" as "Updates" variable, you can define specific updates in natural language in the "Updates_custom_time" field. Example : select "Custom" as "Updates", then type a custom intervals like "5m", "2h", "1w", or "2mo" to have an update every 5 minutes, or every 2 hours, or evey week, or every 2 months

## v0.8.1-6 (2024-11-02)
- Minor bugs fixed
## v0.8.1-5 (2024-08-22)
- Minor bugs fixed
## v0.8.1-4 (2024-07-30)
- Minor bugs fixed
## v0.8.1-3 (2024-06-11)
- Minor bugs fixed
## v0.8.1-2 (2024-04-13)
- Minor bugs fixed

## v0.8.1 (2024-04-13)
- Update to latest version from analogj/scrutiny (changelog : https://github.com/analogj/scrutiny/releases)
## v0.8.0-3 (2024-03-18)
-Avoid overriding the smartctl command https://github.com/alexbelgium/hassio-addons/issues/1308

## v0.8.0-2 (2024-03-17)
- Minor bugs fixed

## v0.8.0 (2024-03-16)
- Update to latest version from analogj/scrutiny

## v0.7.3 (2024-03-02)

- Update to latest version from analogj/scrutiny

## v0.7.2 (2023-10-20)

- Update to latest version from analogj/scrutiny

## v0.7.1 (2023-04-15)

- Update to latest version from analogj/scrutiny

## v0.7.0 (2023-04-08)

- Update to latest version from analogj/scrutiny
- Implemented healthcheck

## v0.6.0 (2023-01-14)

- Update to latest version from analogj/scrutiny
- WARNING : update to supervisor 2022.11 before installing
- New options SMARTCTL_COMMAND_DEVICE_TYPE & SMARTCTL_MEGARAID_DISK_NUM (@scavara)
- New option, define COLLECTOR_API_ENDPOINT when in Collector mode
- New option "Mode" : Collector+WebUI or Collector only

## v0.5.0 (2022-08-26)

- Update to latest version from analogj/scrutiny

- BACKUP BEFORE UPDATE : major version change
- PUID/PGID, ssl values deprecated

## 2ab714f5-ls35 (2022-05-11)

- Update to latest version from linuxserver/scrutiny

## version-c397a323 (2022-05-10)

- Update to latest version from linuxserver/scrutiny

## 8e34ef8d-ls35 (2022-05-05)

- Update to latest version from linuxserver/scrutiny
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation
- Added : "/dev/nvme0"

## 0.3.13 (2021-10-26)

- Update to latest version from analogj/scrutiny
- Allow mounting of devices up to sdg2

## 0.3.12 (2021-09-29)

- Update to latest version from AnalogJ/scrutiny
- Aligned with AnalogJ namings

## fd4f0429

- New ingress icon, thanks to @ElVit
- New features, selecting of update rate with addon option
- Add banner in log
- Align to upstream

## 27b923b5-ls12

- Removed full access flag
- Improved code for local devices scanning after first installation
- Solved an issue that made a blank screen on mobile devices
- Implementation of Ingress with/without ssl

## 27b923b5-ls11

- Enables PUID/PGID options
- Daily update of values
