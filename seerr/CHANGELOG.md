 
## 3.4.1.1 (2026-08-16)

- Fixed `404: Not Found` when clicking **Discover** in the sidebar through ingress (#2975). Seerr's Discover link points at `/`, which nginx rewrote to the ingress entry without a trailing slash; Home Assistant only routes ingress on `/api/hassio_ingress/<token>/…`, so the request was rejected by Home Assistant before reaching the add-on. Only ingress was affected; the directly published port 5055 always worked.

## 3.4.1 (2026-08-01)
- Update to latest version from seerr-team/seerr (changelog : https://github.com/seerr-team/seerr/releases)
## 3.3.0.1 (2026-07-28)

- Fixed searches failing through ingress with `500 Internal Server Error` (#2906, #2646). Home Assistant's ingress proxy re-encodes the query string and passes a space as `+`, along with a bare `:` `/` `?` `@` `!` `$` `'` `(` `)` `*` `,` - all of which Seerr's OpenAPI validator rejects as reserved characters. Nginx now re-encodes them before proxying, so titles such as `Monsters, Inc.`, `Ocean's Eleven`, `Mission: Impossible` and `Who? What?` search correctly. Only ingress was affected; the directly published port 5055 always worked.

## 3.3.0 (2026-06-05)
- Update to latest version from seerr-team/seerr (changelog : https://github.com/seerr-team/seerr/releases)

## 3.2.0 (2026-04-23)
- Update to latest version from seerr-team/seerr (changelog : https://github.com/seerr-team/seerr/releases)
## 3.2.0 (21-04-2026)
- Minor bugs fixed
## 3.1.0-4 (14-04-2026)
- Minor bugs fixed
## 3.1.0-3 (14-04-2026)
- Minor bugs fixed

## 3.1.0-2 (22-03-2026)
- Added configurable `NODE_MEMORY_LIMIT` option (default 512 MB) to control Node.js heap size and prevent OOM kills

## 3.1.0 (22-03-2026)
- Set default Node.js memory limit (512MB) to prevent OOM kills that caused the addon to stop responding
- Update to latest version from seerr-team/seerr (changelog : https://github.com/seerr-team/seerr/releases)

## 3.0.1 (2026-02-21)
- Update to latest version from seerr-team/seerr (changelog : https://github.com/seerr-team/seerr/releases)
## 3.0.1-6 (20-02-2026)
- Minor bugs fixed
## 3.0.1-5 (19-02-2026)
- Minor bugs fixed
## 3.0.1-4 (19-02-2026)
- Minor bugs fixed
## 3.0.1-3 (19-02-2026)
- Minor bugs fixed
## 3.0.1-2 (19-02-2026)
- Added Home Assistant Ingress support for Seerr with an internal NGINX reverse proxy and ingress-aware response rewriting.
- Enabled ingress in the add-on manifest and updated startup flow to launch NGINX before Seerr.

## v3.0.1 (2026-02-17)
- Initial release based on the Overseerr add-on, updated to the Seerr upstream image and naming.
- Switched base image to `seerr/seerr:latest` and updated metadata/options for the new slug.
- Remove bundled binary image assets from the add-on directory as requested by review feedback.

