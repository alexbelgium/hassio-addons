
## 3.7.21 (2026-10-11)
- Initial release: Joplin desktop streamed to the browser with Selkies, based on linuxserver/docker-joplin (amd64 only, as Joplin publishes no Linux arm64 build)
- Shares the Selkies startup scripts with the webtop and claude_desktop add-ons (data location, GPU permissions, ingress, SSL)
- Own SSL certificates (`use_own_certs`) now also apply when `data_location` is changed: the shared `90-ssl.sh` replaces whatever certificate path nginx holds instead of a fixed `/config/data/ssl/...` string, and warns instead of reporting success when it cannot
