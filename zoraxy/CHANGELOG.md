## 3.3.3 (2026-06-19)
- Initial release
- Zoraxy reverse proxy with web management UI (port 8000) for Home Assistant
- Persistent configuration stored in the add-on config directory (/config)
- Options exposed: NOAUTH, ZEROTIER, FASTGEOIP, MDNS, plus env_vars passthrough
- ZeroTier mode supported via the NET_ADMIN capability and /dev/net/tun device
- Based on upstream tobychui/zoraxy (https://github.com/tobychui/zoraxy/releases)
