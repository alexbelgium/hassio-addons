## v0.8.1-11 (15-08-2025)
- Minor bugs fixed
## v0.8.1-10 (13-08-2025)
- Disable port by default for security purposes; it can be readded from the addon options. Ingress access is not affected @soosp
- Document internal domain name for accessing the REST API without exposing the port.

## v0.8.1-9 (14-11-2024)
- Align behavior with other addons : map /addons_config/xxx-scrutiny to enable env injection or custom scripts

## v0.8.1-8 (13-11-2024)
- Minor bugs fixed
## v0.8.1-7 (13-11-2024)
- New feature : if you select "Custom" as "Updates" variable, you can define specific updates in natural language in the "Updates_custom_time" field. Example : select "Custom" as "Updates", then type a custom intervals like "5m", "2h", "1w", or "2mo" to have an update every 5 minutes, or every 2 hours, or evey week, or every 2 months

## v0.8.1-6 (02-11-2024)
- Minor bugs fixed
## v0.8.1-5 (22-08-2024)
- Minor bugs fixed
## v0.8.1-4 (30-07-2024)
- Minor bugs fixed
## v0.8.1-3 (11-06-2024)
- Minor bugs fixed
## v0.8.1-2 (13-04-2024)
- Minor bugs fixed

## v0.8.1 (13-04-2024)
- Update to latest version from analogj/scrutiny (changelog : https://github.com/analogj/scrutiny/releases)
## v0.8.0-3 (18-03-2024)
-Avoid overriding the smartctl command https://github.com/alexbelgium/hassio-addons/issues/1308

## v0.8.0-2 (17-03-2024)
- Minor bugs fixed

## v0.8.0 (16-03-2024)
- Update to latest version from analogj/scrutiny

## v0.7.3 (02-03-2024)

- Update to latest version from analogj/scrutiny

## v0.7.2 (20-10-2023)

- Update to latest version from analogj/scrutiny

## v0.7.1 (15-04-2023)

- Update to latest version from analogj/scrutiny

## v0.7.0 (08-04-2023)

- Update to latest version from analogj/scrutiny
- Implemented healthcheck

## v0.6.0 (14-01-2023)

- Update to latest version from analogj/scrutiny
- WARNING : update to supervisor 2022.11 before installing
- New options SMARTCTL_COMMAND_DEVICE_TYPE & SMARTCTL_MEGARAID_DISK_NUM (@scavara)
- New option, define COLLECTOR_API_ENDPOINT when in Collector mode
- New option "Mode" : Collector+WebUI or Collector only

## v0.5.0 (26-08-2022)

- Update to latest version from analogj/scrutiny

- BACKUP BEFORE UPDATE : major version change
- PUID/PGID, ssl values deprecated

## 2ab714f5-ls35 (11-05-2022)

- Update to latest version from linuxserver/scrutiny

## version-c397a323 (10-05-2022)

- Update to latest version from linuxserver/scrutiny

## 8e34ef8d-ls35 (05-05-2022)

- Update to latest version from linuxserver/scrutiny
- Add codenotary sign
- New standardized logic for Dockerfile build and packages installation
- Added : "/dev/nvme0"

## 0.3.13 (26-10-2021)

- Update to latest version from analogj/scrutiny
- Allow mounting of devices up to sdg2

## 0.3.12 (29-09-2021)

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
