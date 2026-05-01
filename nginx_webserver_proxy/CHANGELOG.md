# Changelog

## 2.14.0

- Initial release wrapping jc21/nginx-proxy-manager:latest
- NPM Admin UI on port 81; HTTP on port 80; HTTPS on port 443
- Configurable static file server via NPM's default_host nginx config
- Supports /share, /media, /config paths; warns for /mnt; blocks dangerous system paths
- NPM state persisted via Docker volume (managed by HA Supervisor)
- Supports amd64 and aarch64
