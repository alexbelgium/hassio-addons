## 17.4-10 (15-07-2025)
- Allow for non standard user

## 17.4-9 (24-06-2025)

- Fix healthcheck to run with correct user and database

## 17.4-8 (23-06-2025)

- Version 5, 6 and 7 had an issue : you need to restore prior to version 45 then update to 46 again. If you don't have a backup please create an issue in the github repo

## 17.4-4 (31-05-2025)

- Minor bugs fixed

## 17.4-3 (30-05-2025)

- Minor bugs fixed

## 17.4-1 (30-05-2025)

- Minor bugs fixed

## 15.7-43 (30-05-2025)

- Minor bugs fixed

## 15.7-41 (30-05-2025)

- BREAKING CHANGE : please backup your database before updating
- Automatically restarts immich addons after upgrade
- Describe list of databases and extensions in log
- Improve upgrade system for postgres and extensions
- Drop vectors from postgres database (not needed)
- Switch to new image supporting both vector.rs and VectorChord to support immich https://github.com/immich-app/immich/releases/tag/v1.133.0

## 15.7-29 (15-02-2025)

- Minor bugs fixed

## 15.7-28 (15-02-2025)

- Minor bugs fixed

## 15.7-27 (15-02-2025)

- Major update, please backup first
- Automatic handling of upgrades
- Restore clean shutdown

## 15.7-16 (22-01-2025)

- Minor bugs fixed

## 15.7-14 (15-01-2025)

- Minor bugs fixed

## 15.7-13 (15-01-2025)

- Redirect logs to addons log
- Removed vector.rs installation script, it is now part of the upstream entrypoint

## 15.7-7 (03-01-2025)

- Fix vector.rs not found at startup

## 15.7-4 (05-12-2024)

- Fix env error
- Fix database shutdown
- Upgrade postgres to 15.7
- Update pgvector to v0.3.0

## 15.5-7 (24-02-2024)

- Update pgvector to 0.2.0

## 15.5-6 (03-02-2024)

- Fix : use custom postgres username

## 15.5-5 (03-02-2024)

- Revert vector to 0.1.11 as only version supported by immich

## 15.5-4 (31-01-2024)

- &#9888; PLEASE BACKUP before updating! Non reversible changes
- &#9888; WARNING : addition of pgvecto.rs extension, potentially breaking change ! Be sure to backup prior to update
- &#9888; Database location changed from /data to /addon_configs/xxx-postgres : no expected user impact other that all configuration files will also be located in this folder accessible with addons such as Filebrowser

## 15.5 (11-11-2023)

- Update to latest version from postgres

## 15.4 (09-09-2023)

- Update to latest version from postgres

## 15.3-11 (08-09-2023)

- Minor bugs fixed

## 15.3-10 (08-09-2023)

- Minor bugs fixed

## 15.3-9 (08-09-2023)

- Minor bugs fixed

## 15.3-7 (07-09-2023)

- Minor bugs fixed

## 15.3-6 (07-09-2023)

- Minor bugs fixed

## 15.3-5 (07-09-2023)

- Minor bugs fixed

## 15.3-2 (07-09-2023)

- Minor bugs fixed
- Ensure postgres.conf persistcene

## 15.3

- Initial release
- Removed useless webui button
