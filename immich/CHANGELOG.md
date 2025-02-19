## 1.126.1-11 (19-02-2025)
- Minor bugs fixed
## 1.126.1-7 (16-02-2025)
- RISK OF BREAKING CHANGE : backup both immich & postgres before starting
- RISK OF BREAKING CHANGE : rewrite and improve database creation tool using addon options (overwritting manual database creation)
- SECURITY FIX : avoid hardcoding the postgres root password and change it if was already applied
- NEW FUNCTION : allow to define a library path outside of the data location. For example, if you specify /mnt/NAS/MyPictures as "library_location", and /mnt/NAS/Immich as "data_location", it will then create the whole structure in /mnt/NAS/Immich including the /mnt/NAS/Immich/library. However, this will just be a symlink to /mnt/NAS/MyPictures ; allowing people to still manage their hard drives in a more linear manner
- Ensure host is reachable before starting
- Autocorrect homeassistant.local to local ip
- Align configuration with /addon_configs
- Add gpu access

## 1.126.1 (15-02-2025)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.125.7 (01-02-2025)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.125.2 (25-01-2025)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)
## 1.124.2-2 (11-01-2025)
- Minor bugs fixed

## 1.124.2 (11-01-2025)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.123.0 (21-12-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.122.3 (14-12-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)
## 1.122.1-4 (10-12-2024)
- Fix compatibility with postgres 15 addon

## 1.122.1-3 (08-12-2024)
- Fix healthcheck (thanks @red-avtovo)

## 1.122.1-2 (08-12-2024)
- Minor bugs fixed

## 1.122.1 (07-12-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.121.0 (23-11-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.120.2 (16-11-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.120.1 (09-11-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.119.1 (02-11-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.118.2 (19-10-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.117.0 (05-10-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.116.2 (28-09-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.115.0 (14-09-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.114.0 (07-09-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.113.0 (31-08-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.112.1 (17-08-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.111.0 (03-08-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.110.0 (27-07-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.109.2 (20-07-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.108.0 (13-07-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.107.2 (06-07-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)
## 1.106.4-3 (24-06-2024)
- Minor bugs fixed
## 1.106.4-2 (15-06-2024)
- Minor bugs fixed

## 1.106.4 (15-06-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.105.1 (18-05-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.103.1 (04-05-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.102.3 (27-04-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.101.0 (06-04-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.100.0 (30-03-2024)
- Update to latest version from imagegenius/docker-immich (changelog : https://github.com/imagegenius/docker-immich/releases)

## 1.99.0 (23-03-2024)
- Update to latest version from imagegenius/docker-immich

## 1.98.2 (16-03-2024)
- Update to latest version from imagegenius/docker-immich

## 1.98.1 (09-03-2024)

- Minor bugs fixed

## 1.98.0 (09-03-2024)

- Update to latest version from imagegenius/docker-immich

## 1.97.0 (02-03-2024)

- Update to latest version from imagegenius/docker-immich

## 1.95.1 (24-02-2024)

- Update to latest version from imagegenius/docker-immich

## 1.94.1 (03-02-2024)

- Update to latest version from imagegenius/docker-immich
- &#9888; PLEASE BACKUP before updating! Non reversible changes
- &#9888; BREAKING change : dependency on the update postgres image for vector.rs support, it will not work if you do not update postgres !
- &#9888; Database location changed from /data to /addon_configs/xxx-postgres : no expected user impact other that all configuration files will also be located in this folder accessible with addons such as Filebrowser

## 1.90.2 (09-12-2023)

- Update to latest version from imagegenius/docker-immich

## 1.89.0 (02-12-2023)

- Update to latest version from imagegenius/docker-immich
## 1.88.2-3 (27-11-2023)

- Minor bugs fixed
- Fix : add REVERSE_GEOCODING_DUMP_DIRECTORY in config environment

## 1.88.2 (25-11-2023)

- Update to latest version from imagegenius/docker-immich
## 1.88.1-7 (24-11-2023)

- Minor bugs fixed
## 1.88.1-6 (23-11-2023)

- Minor bugs fixed
## 1.88.1-5 (23-11-2023)

- Minor bugs fixed
- Fixed REDIS error

## 1.88.1 (21-11-2023)

- Update to latest version from imagegenius/docker-immich

## 1.87.0 (19-11-2023)

- Update to latest version from imagegenius/docker-immich

## 1.86.0 (18-11-2023)

- Update to latest version from imagegenius/docker-immich

## 1.85.0 (11-11-2023)

- Update to latest version from imagegenius/docker-immich

## 1.84.0 (04-11-2023)

- Update to latest version from imagegenius/docker-immich

## 1.82.1 (20-10-2023)

- Update to latest version from imagegenius/docker-immich

## 1.81.1 (07-10-2023)

- Update to latest version from imagegenius/docker-immich
## 1.79.1-2 (24-09-2023)

- Minor bugs fixed
- Feat : new optional settings for ML workers and timeout https://github.com/alexbelgium/hassio-addons/issues/996

## 1.79.1 (23-09-2023)

- Update to latest version from imagegenius/docker-immich
## 1.78.1-6 (22-09-2023)

- Minor bugs fixed
## 1.78.1-5 (21-09-2023)

- Minor bugs fixed
- YOU WILL LOSE DATA : the upstream container has removed the embedded postgres (read more https://github.com/imagegenius/docker-immich/issues/90). You now need to install and configure the postgress add-on from this same repo, and reference it in the addon options. This means you will lose your current database, and will need to recreate it from scratch. Your previous database will still be exported to the file /config/addons_config/immich/old_database.gzip. However exporting it to the postgres container is quite complex and not supported.
- BREAKING CHANGE : referencing the postgres options is now required. You can either install the postgres add-on from my repo, or this one for example : https://github.com/Expaso/hassos-addons/tree/master/timescaledb
- Switch from jammy branch to latest due to deprecation

## 1.78.1 (16-09-2023)

- Update to latest version from imagegenius/docker-immich

## 1.77.0 (09-09-2023)

- Update to latest version from imagegenius/docker-immich

## 1.75.2 (27-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.75.0 (26-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.74.0 (26-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.73.0 (19-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.72.2 (12-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.71.0 (05-08-2023)

- Update to latest version from imagegenius/docker-immich

## 1.70.0 (29-07-2023)

- Update to latest version from imagegenius/docker-immich

## 1.68.0 (22-07-2023)

- Update to latest version from imagegenius/docker-immich

## 1.67.2 (15-07-2023)

- Update to latest version from imagegenius/docker-immich

## 1.66.1 (08-07-2023)

- Update to latest version from imagegenius/docker-immich
- Beware that using the built-in Postgres 14 will likely fail at some point. It is recommended to upgrade to an external Postgres 15 database. A solution is the specific addon I've built. See https://github.com/imagegenius/docker-immich/issues/90

## 1.57.1-jammy (27-05-2023)

- Minor bugs fixed
- Switch to jammy branch (new features could break but is required until a separate Postgres addon is made)

## 1.57.1 (27-05-2023)

- Update to latest version from imagegenius/docker-immich

## 1.56.1 (19-05-2023)

- Update to latest version from imagegenius/docker-immich

## 1.55.1 (13-05-2023)

- Update to latest version from imagegenius/docker-immich
- Feat : cifsdomain added

## 1.54.1 (23-04-2023)

- Update to latest version from imagegenius/docker-immich

## 1.54.0 (21-04-2023)

- Update to latest version from imagegenius/docker-immich

## 1.53.0-2 (18-04-2023)

- Minor bugs fixed
- Fix : add option `TYPESENSE_ENABLED` https://github.com/alexbelgium/hassio-addons/issues/802

## 1.53.0 (08-04-2023)

- Update to latest version from imagegenius/docker-immich

## 1.52.1 (31-03-2023)

- Update to latest version from imagegenius/docker-immich

## 1.51.2 (24-03-2023)

- Update to latest version from imagegenius/docker-immich
- Implemented healthcheck

## 1.50.1 (04-03-2023)

- Update to latest version from imagegenius/docker-immich

## 1.49.0 (25-02-2023)

- Update to latest version from imagegenius/docker-immich

## 1.47.3 (19-02-2023)

- Update to latest version from imagegenius/docker-immich

## 1.45.0 (04-02-2023)

- Update to latest version from immich-app/immich

## 1.43.1 (28-01-2023)

- Update to latest version from immich-app/immich

## 1.43.0 (28-01-2023)

- Update to latest version from immich-app/immich

## 1.42.0 (21-01-2023)

- Update to latest version from immich-app/immich

## 1.41.1 (14-01-2023)

- Update to latest version from immich-app/immich
- Initial version
