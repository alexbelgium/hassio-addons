
## 2.31.0 (13-06-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)
## 2.30.1-2 (30-05-2025)
- Map internal /config to allow for custom scripts execution and variables
- Fix invalid origin

## 2.30.1 (24-05-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.30.0 (17-05-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.29.2 (26-04-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.29.0 (19-04-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.28.1 (22-03-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.27.1 (01-03-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.27.0 (21-02-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.26.1 (25-01-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.26.0 (18-01-2025)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.25.1 (21-12-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.24.1 (07-12-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.24.0 (23-11-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.23.0 (19-10-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)
## 2.22.0-3 (06-10-2024)
- WARNING : logic change for new installations. Type "empty" in the PASSWORD of the addon to reset the database and have a clean initial set-up. Used for example to restore backups

## 2.22.0 (05-10-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.21.2 (28-09-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.21.1 (14-09-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.21.0 (31-08-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.20.1 (13-04-2024)
- Update to latest version from portainer/portainer (changelog : https://github.com/portainer/portainer/releases)

## 2.20.0 (23-03-2024)
- Update to latest version from portainer/portainer

## 2.19.4-3 (11-12-2023)

- Minor bugs fixed
- When database is reset, the previous one is stored in /share/portainer_$(date +%m-%d-%Y)_$RANDOM".backup. In case of unwanted database wipe, you can therefore restore it from the portainer options

## 2.19.4 (09-12-2023)

- Update to latest version from portainer/portainer

## 2.19.3 (25-11-2023)

- Update to latest version from portainer/portainer
## 2.19.2-3 (21-11-2023)

- Minor bugs fixed

## 2.19.2 (18-11-2023)

- Update to latest version from portainer/portainer

## 2.19.1 (23-09-2023)

- Update to latest version from portainer/portainer

## 2.19.0 (09-09-2023)

- Update to latest version from portainer/portainer

## 2.18.4 (08-07-2023)

- Update to latest version from portainer/portainer

## 2.18.3 (27-05-2023)

- Update to latest version from portainer/portainer

## 2.18.2 (06-05-2023)

- Update to latest version from portainer/portainer

## 2.18.1 (21-04-2023)

- Update to latest version from portainer/portainer
- Feat : addition of Micro Editor to all addons

## 2.17.1-9 (11-03-2023)

- Minor bugs solved
- Revert : disable healthcheck (caused unhealthy status)

## 2.17.1-8 (11-03-2023)

- Minor bugs solved
- Improve healthcheck with /api/status

## 2.17.1-6 (11-03-2023)

- Implemented healthcheck
- Rollback implementation of s6-rc.d from 2.17.1-4 to 2.17.1-2 due to reported issues with addon entities reporting

## 2.17.1 (25-02-2023)

- Update to latest version from portainer/portainer

## 2.17.0 (11-02-2023)

- Update to latest version from portainer/portainer
- WARNING : update to supervisor 2022.11 before installing

## 2.16.2 (22-11-2022)

- Update to latest version from portainer/portainer

## 2.16.1 (11-11-2022)

- Update to latest version from portainer/portainer

## 2.16.0 (01-11-2022)

- Update to latest version from portainer/portainer

## 2.15.1 (17-09-2022)

- Update to latest version from portainer/portainer

## 2.15.0 (09-09-2022)

- Update to latest version from portainer/portainer

## 2.14.2 (28-07-2022)

- Update to latest version from portainer/portainer

## 2.14.1 (14-07-2022)

- Update to latest version from portainer/portainer

## 2.14.0 (30-06-2022)

- Update to latest version from portainer/portainer

## 2.13.1 (12-05-2022)

- BREAKING CHANGE : database is reset and password reset to homeassistant (new portainer stronger password requirement)
- Update to latest version from portainer/portainer

## 2.13.0 (10-05-2022)

- Update to latest version from portainer/portainer
- Add codenotary sign
- Reduce backup size (thanks @lmagyar)

## 2.11.1 (10-02-2022)

- Update to latest version from portainer/portaine@

## 2.11.0 (08-02-2022)

- Update to latest version from portainer/portainer

## 2.11.1 (08-02-2022)

- Update to latest version from portainer/portainer
- New standardized logic for Dockerfile build and packages installation
- Improve architecture detection

## 2.11.0 (09-12-2021)

- Update to latest version from portainer/portainer

## 2.9.3 (22-11-2021)

- Update to latest version from portainer/portainer

## 2.9.2 (28-10-2021)

- Update to latest version from portainer/portainer
- password: define admin password. If kept blank, will allow manual restore of previous backup put in /share

## 2.9.1 (11-10-2021)

- Update to latest version from portainer/portainer
- Enabled https access on same port as http when activating ssl

## 2.9.0 (25-09-2021)

- Update to latest version from portainer/portainer
- Enable stream mode

## 2.6.3 (28-08-2021)

- Update to latest version from portainer/portainer

## 2.6.2 (07-08-2021)

- Update to latest version from portainer/portainer

## 2.6.3 (07-08-2021)

- Update to latest version from lastversion-test-repos/portainer

## 2.6.2 (02-08-2021)

- Update to latest version from portainer/portainer

## 2.6.2 (31-07-2021)

- Update to latest version from portainer/portainer

## 2.6.2 (30-07-2021)

- Update to latest version from portainer/portainer

## 2.6.1 (10-07-2021)

- Update to latest version from portainer/portainer

## 2.6.0 (25-06-2021)

- Update to latest version from portainer/portainer

## 2.5.1 (28-05-2021)

- Update to latest version from portainer/portainer

## 2.5.0 (25-05-2021)

- Update to latest version from portainer/portainer
- Update to latest version from portainer/portainer
- ssl
- ingress with nginx
- password setting through addon option
- webui
