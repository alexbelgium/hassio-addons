 
## 2.10.8 (2026-09-26)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.10.7 (2026-09-24)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.10.6.1 (2026-09-23)
- Fix ingress: the add-on declared `ingress: true` without `ingress_port`, so Home
  Assistant proxied the sidebar entry and "Open Web UI" to the default port 8099,
  where nothing listened. An nginx proxy now serves that port and rewrites the base
  path Cleanuparr's web UI builds its asset, API and SignalR URLs from, so they
  resolve under the ingress path instead of the Home Assistant root. Direct access
  on port 11011 is unchanged (#3084)
- Remove `webui`, which the add-on linter rejects when ingress is enabled and which
  the repository's other 55 ingress add-ons do not set; "Open Web UI" uses ingress
  and port 11011 stays published
- Fix `env_vars`: the add-on declared the env-var passthrough in its schema but never
  installed `00-global_var.sh`, the module that converts it, and could not have run it —
  the image has no `jq`, and cont-init scripts were started with plain `bash`, so the
  module's bashio guard always took its no-Supervisor branch and exited. Install `jq`,
  add the module, run the init scripts under bashio as the Maintainerr add-on does, and
  source the generated `/.env` before starting Cleanuparr. `PUID`/`PGID` are still read
  from the image's defaults for the data-directory `chown` — see the pull request
 
## 2.10.6 (2026-09-19)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
- Migrate legacy add-on configuration map names to current app configuration terminology.
- Fix persistent data directory: the entrypoint now writes to the `/config` mount (the container-side path of the `app_config` map) instead of an unmounted `/app_configs/cleanuparr` path, so Cleanuparr's data survives container recreation.
 
## 2.10.5 (2026-08-13)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.10.3 (2026-08-08)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.10.2 (2026-08-01)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.9.16 (2026-07-11)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
 
## 2.9.14 (2026-06-20)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.13 (2026-05-16)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.11 (2026-05-09)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.10 (2026-05-02)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.8 (2026-04-18)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.5 (2026-04-11)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.4 (2026-04-06)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.3 (2026-04-04)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.9.1 (2026-03-28)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)

## 2.8.1 (2026-03-14)
- Update to latest version from Cleanuparr/Cleanuparr (changelog : https://github.com/Cleanuparr/Cleanuparr/releases)
# Changelog

## 2.7.7

- Initial release of Cleanuparr addon
- Based on upstream image `ghcr.io/cleanuparr/cleanuparr:2.7.7`
- Persistent config stored in HA addon config directory
- Supports amd64 and aarch64 architectures
