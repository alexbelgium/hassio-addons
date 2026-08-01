## 4.16.0.95.7 (2026-08-01)

- Version renamed from `4.16-r0-ls95-7`, which Home Assistant could not order and therefore could not reliably offer as an update: every number of the previous version is kept, as a section of its own. The addon itself and the upstream version it tracks are unchanged

## 4.16-r0-ls95-7 (28-07-2026)

- Fix Selkies dying with a Rust `RuntimeDirNotSet` unwrap panic just after `Data WebSocket Server listening on port 8081`, and the data websocket then being proxied to the wrong port. Upstream relies on s6-rc ordering: `init-selkies-config` publishes `XDG_RUNTIME_DIR` and `CUSTOM_WS_PORT` into the s6 envdir and `svc-selkies` starts afterwards. The add-on entrypoint replaces s6-overlay and starts every `s6-rc.d` run script in parallel with no dependency graph, so Selkies can snapshot the envdir before that oneshot has written to it -- which is why it bound port 8081 (its own default) instead of the 8082 nginx proxies to, and why its Wayland compositor found no runtime directory to bind a socket in. `20-folders.sh` now exports both variables inside each run script, where no start ordering can lose them, and corrects the base image's `$HOME/.XDG` override where that write happens instead of appending a correction after the `exit 0` that the oneshot-tolerance block adds -- which meant the correction never ran on any boot after the first.

- Microsoft Edge install: `apt-get` and `dpkg` failures no longer abort container startup -- a transient mirror failure or a bad download now logs a warning and leaves the desktop running without Edge, and apt acquisition is bounded so a stalled mirror cannot hang start-up. The post-install wrapper swap is now gated on the helper still being present, so a second run cannot move the installed wrapper aside with nothing left to replace it.

## 4.16-r0-ls95-6 (28-07-2026)

- Share the Selkies startup scripts with the `claude_desktop` add-on by symlink (`20-folders.sh`, `21-gpu_permissions.sh`, `80-configuration.sh`, `90-ingress.sh` and the nginx includes), so the fixes made there now apply here too. This brings in: GPU render-node permissions granted before the graphical services start (fixes `libEGL warning: failed to open /dev/dri/card0: Permission denied` and the resulting "waiting for stream" hang); the s6 envdir and `XDG_RUNTIME_DIR` created up front; the cache redirected to tmpfs; `/tmp/.X11-unix` pre-created so Xorg can bind its socket as a non-root user; the `init-video` and `init-selkies-config` oneshots made non-fatal so a partially permitted device setup no longer crash-loops the add-on; and an ingress config that keeps the correct (non-SSL) nginx server block. The Microsoft Edge install moves to its own webtop-only `81-microsoft_edge.sh`, which also picks up the ownership fixup that previously ran in `20-folders.sh` before Edge was installed and so never matched anything.

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## 4.16-r0-ls95-5 (2026-02-23)
- Fix ingress: replace CWS port placeholder with 8082 and SUBFOLDER with /

## 4.16-r0-ls95-4 (2025-06-01)
- Minor bugs fixed
## 4.16-r0-ls94-4 (2025-05-28)
- Minor bugs fixed
## 4.16-r0-ls94-2 (2025-05-28)
- Minor bugs fixed

## 4.16-r0-ls94 (2025-05-24)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)
## 4.16-r0-ls93-2 (2025-05-17)
- Minor bugs fixed

## 4.16-r0-ls93 (2025-05-17)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls94 (2025-04-26)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls93 (2025-04-19)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls94 (2025-04-05)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls93 (2025-03-29)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls95 (2025-03-22)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls94 (2025-03-15)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls93 (2025-03-08)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls95 (2025-03-01)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)
## 4.16-r0-ls94-5 (2025-02-21)
- Option to install microsoft edge

## 4.16-r0-ls94-3 (2025-02-15)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## 4.16-r0-ls94-9 (2025-01-29)
- Minor bugs fixed
## 4.16-r0-ls94-7 (2025-01-29)
- External port disabled by default to rely on ingress
- Added a message that opening a port without password is a very high risk
- Add microsoft edge

## 4.16-r0-ls94 (2025-01-25)
- Update to latest version from linuxserver/docker-webtop (changelog : https://github.com/linuxserver/docker-webtop/releases)

## fb06d0b4-ls71-5 (2025-01-24)
- Minor bugs fixed

## fb06d0b4-ls71-4 (2025-01-24)
- Minor bugs fixed

## fb06d0b4-ls71-2 (2025-01-24)
- First version of Ubuntu KDE
- Use own ssl certificates
