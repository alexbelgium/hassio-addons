
## 3.7.0 (2026-04-18)
- Update to latest version from maintainerr/maintainerr (changelog : https://github.com/maintainerr/maintainerr/releases)

## 3.5.0 (2026-04-11)
- Update to latest version from maintainerr/maintainerr (changelog : https://github.com/maintainerr/maintainerr/releases)
## 3.3.0-3 (08-04-2026)
- Minor bugs fixed
## 3.3.0-2 (06-04-2026)
- Minor bugs fixed

## 3.3.0 (2026-04-04)
- Update to latest version from maintainerr/maintainerr (changelog : https://github.com/maintainerr/maintainerr/releases)
## 3.2.0-10 (03-04-2026)
- Minor bugs fixed
## 3.2.0-9 (03-04-2026)
- Minor bugs fixed
## 3.2.0-8 (02-04-2026)
- Minor bugs fixed
## 3.2.0-7 (02-04-2026)
- Minor bugs fixed
## 3.2.0-6 (02-04-2026)
- Minor bugs fixed
## 3.2.0-5 (02-04-2026)
- Add Home Assistant ingress support with nginx reverse proxy

## 3.2.0-4 (02-04-2026)
- Minor bugs fixed

## 3.2.0-3 (2026-03-31)
- Fix addon never starts: symlink contents inside /opt/data instead of replacing the Docker VOLUME directory

## 3.2.0-2 (2026-03-31)
- Fix configuration lost after container restart by symlinking /opt/data to persistent /config directory

## 3.2.0 (2026-03-28)
- Update to latest version from maintainerr/maintainerr (changelog : https://github.com/maintainerr/maintainerr/releases)

## 3.1.0 (2026-03-14)
- Update to latest version from maintainerr/maintainerr (changelog : https://github.com/maintainerr/maintainerr/releases)
## 3.0.1

- Initial release of Maintainerr addon
- Based on upstream image `ghcr.io/maintainerr/maintainerr:3.0.1`
- Persistent data stored in HA addon config directory
- Supports amd64 and aarch64 architectures
