
## ngx-1.6.0-ls1 (28-03-2022)
- Update to latest version from linuxserver/docker-paperless-ngx
- Major change : switch to paperless NGX
- Add codenotary sign
- Cleanup: config base folder changed to /config/addons_config (thanks @bruvv)
- MultiOCR: in OCRLANG field use comma separated value. Ex: fra,deu (working)
- Manual install pikepdf
- New standardized logic for Dockerfile build and packages installation
- Allow !secrets in config.yaml (see Home Assistant documentation)

## 1.5.0 (27-11-2021)

- Update to latest version from linuxserver/docker-paperless-ng
- Add config.yaml configurable options (see readme)
- Initial build
