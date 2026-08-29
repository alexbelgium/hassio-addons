## 3.3.3.1 (29-08-2026)
- Fix build failure against the current upstream image: since v3.3.4 the upstream
  build deletes /sbin/apk, so the shared module and package scripts had no package
  manager and failed with "apt-get: not found / apk: not found" (exit 127). The
  statically-linked apk binary is now restored from a build stage.

## 3.3.3 (2026-06-19)
- Initial release
- Zoraxy reverse proxy with web management UI (port 8000) for Home Assistant
- Persistent configuration stored in the add-on config directory (/config)
- Options exposed: NOAUTH, ZEROTIER, FASTGEOIP, MDNS, plus env_vars passthrough
- ZeroTier mode supported via the NET_ADMIN capability and /dev/net/tun device
- Based on upstream tobychui/zoraxy (https://github.com/tobychui/zoraxy/releases)
