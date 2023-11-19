
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
### 1.79.1-2 (24-09-2023)
- Minor bugs fixed
- Feat : new optional settings for ML workers and timeout https://github.com/alexbelgium/hassio-addons/issues/996

## 1.79.1 (23-09-2023)
- Update to latest version from imagegenius/docker-immich
### 1.78.1-6 (22-09-2023)
- Minor bugs fixed
### 1.78.1-5 (21-09-2023)
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

### 1.57.1-jammy (27-05-2023)
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

### 1.53.0-2 (18-04-2023)

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
