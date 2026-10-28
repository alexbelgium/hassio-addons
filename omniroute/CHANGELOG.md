## 3.8.52.1 (2026-10-28)

- Use the `bashio::app.*` functions instead of the deprecated `bashio::addon.*` ones, removing the deprecation warnings in the log; bashio older than v0.18.0 is upgraded to v0.19.0 at build time

# Changelog

## 3.8.52 (2026-10-22)

- Initial release of OmniRoute add-on
- Upstream version 3.8.52 from cheaper-inference/OmniRoute
- OpenAI-compatible gateway and proxy supporting multi-provider routing, load balancing, and fallbacks
- Full Home Assistant Ingress integration with bundled NGINX reverse proxy
- Optional direct port 20128 (disabled by default) for external OpenAI API clients, coding tools, and direct web access
- Persistent configuration and SQLite database mapped to HA add-on config directory
- Multi-architecture support for amd64 and aarch64
