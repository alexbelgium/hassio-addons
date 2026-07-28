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
