## 3.4.1.3 (2026-08-18)

- Fixed the `404: Not Found` on **Discover** persisting for browsers that had already opened Seerr through ingress, even after 3.4.1.1 and 3.4.1.2 were installed (#2975). Seerr serves its JavaScript bundle with `Cache-Control: public, max-age=31536000, immutable`, and the add-on's nginx rewrites that bundle to carry the ingress prefix - which strips the `ETag` and `Last-Modified` a browser would revalidate with. Since every add-on version served the same upstream build, the chunk URLs never changed either, so a browser kept replaying the broken 3.4.1/3.4.1.1 JavaScript from its own cache for up to a year and no fix could reach it. That is why the report persisted on the origin the reporter uses daily (`https://<domain>/`) while a browser that had never cached it (`http://<ip>:8123/`) already showed the fixed behaviour. The asset paths now carry the add-on version, so each release has its own URLs and the first page load after an update fetches the current bundle. Only ingress was affected; the directly published port 5055 always worked.

## 3.4.1.2 (2026-08-18)

- Fixed **Discover** in the sidebar still failing through ingress after 3.4.1.1 (#2975). The trailing slash added in 3.4.1.1 was also applied to the copy of the link inside Seerr's JavaScript bundle, and Next.js' client-side router strips a trailing slash before navigating: it then sent the click to a URL Home Assistant does not route, so it either landed on the same `404: Not Found` or threw `Invariant: attempted to hard navigate to the same URL` and did nothing at all. The bundle is no longer rewritten, so **Discover** routes inside the app exactly like **Requests**, **Issues** and **Settings** already did. The server-rendered link keeps its trailing slash. Only ingress was affected; the directly published port 5055 always worked.

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

