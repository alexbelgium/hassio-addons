# Changelog

## 3.8.52.1 (06-11-2026)

- Fix login page returning a JSON 401 (AUTH_001) through ingress and port 20128: the middleware matchers are now prefixed with the ingress base path (#3204)

## 3.8.52 (2026-10-22)

- Initial release of OmniRoute add-on
- Upstream version 3.8.52 from cheaper-inference/OmniRoute
- OpenAI-compatible gateway and proxy supporting multi-provider routing, load balancing, and fallbacks
- Full Home Assistant Ingress integration with bundled NGINX reverse proxy
- Optional direct port 20128 (disabled by default) for external OpenAI API clients, coding tools, and direct web access
- Persistent configuration and SQLite database mapped to HA add-on config directory
- Multi-architecture support for amd64 and aarch64
