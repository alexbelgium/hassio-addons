- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 17.4-13 (2025-08-22)
- Minor bugs fixed
## 17.4-12 (2025-07-15)

- Allow for non standard user

## 17.4-9 (2025-06-24)

- Fix healthcheck to run with correct user and database

## 17.4-8 (2025-06-23)

- Version 5, 6 and 7 had an issue : you need to restore prior to version 45 then update to 46 again. If you don't have a backup please create an issue in the github repo

## 17.4-4 (2025-05-31)

- Minor bugs fixed

## 17.4-3 (2025-05-30)

- Minor bugs fixed

## 17.4-1 (2025-05-30)

- Minor bugs fixed

## 15.7-43 (2025-05-30)

- Minor bugs fixed

## 15.7-41 (2025-05-30)

- BREAKING CHANGE : please backup your database before updating
- Automatically restarts immich addons after upgrade
- Describe list of databases and extensions in log
- Improve upgrade system for postgres and extensions
- Drop vectors from postgres database (not needed)
- Switch to new image supporting both vector.rs and VectorChord to support immich https://github.com/immich-app/immich/releases/tag/v1.133.0

## 15.7-29 (2025-02-15)

- Minor bugs fixed

## 15.7-28 (2025-02-15)

- Minor bugs fixed

## 15.7-27 (2025-02-15)

- Major update, please backup first
- Automatic handling of upgrades
- Restore clean shutdown

## 15.7-16 (2025-01-22)

- Minor bugs fixed

## 15.7-14 (2025-01-15)

- Minor bugs fixed

## 15.7-13 (2025-01-15)

- Redirect logs to addons log
- Removed vector.rs installation script, it is now part of the upstream entrypoint

## 15.7-7 (2025-01-03)

- Fix vector.rs not found at startup

## 15.7-4 (2024-12-05)

- Fix env error
- Fix database shutdown
- Upgrade postgres to 15.7
- Update pgvector to v0.3.0

## 15.5-7 (2024-02-24)

- Update pgvector to 0.2.0

## 15.5-6 (2024-02-03)

- Fix : use custom postgres username

## 15.5-5 (2024-02-03)

- Revert vector to 0.1.11 as only version supported by immich

## 15.5-4 (2024-01-31)

- &#9888; PLEASE BACKUP before updating! Non reversible changes
- &#9888; WARNING : addition of pgvecto.rs extension, potentially breaking change ! Be sure to backup prior to update
- &#9888; Database location changed from /data to /addon_configs/xxx-postgres : no expected user impact other that all configuration files will also be located in this folder accessible with addons such as Filebrowser

## 15.5 (2023-11-11)

- Update to latest version from postgres

## 15.4 (2023-09-09)

- Update to latest version from postgres

## 15.3-11 (2023-09-08)

- Minor bugs fixed

## 15.3-10 (2023-09-08)

- Minor bugs fixed

## 15.3-9 (2023-09-08)

- Minor bugs fixed

## 15.3-7 (2023-09-07)

- Minor bugs fixed

## 15.3-6 (2023-09-07)

- Minor bugs fixed

## 15.3-5 (2023-09-07)

- Minor bugs fixed

## 15.3-2 (2023-09-07)

- Minor bugs fixed
- Ensure postgres.conf persistcene

## 15.3

- Initial release
- Removed useless webui button
