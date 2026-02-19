## 3.0.1-3 (19-02-2026)
- Minor bugs fixed
## 3.0.1-2 (19-02-2026)
- Added Home Assistant Ingress support for Seerr with an internal NGINX reverse proxy and ingress-aware response rewriting.
- Enabled ingress in the add-on manifest and updated startup flow to launch NGINX before Seerr.

## v3.0.1 (2026-02-17)
- Initial release based on the Overseerr add-on, updated to the Seerr upstream image and naming.
- Switched base image to `seerr/seerr:latest` and updated metadata/options for the new slug.
- Remove bundled binary image assets from the add-on directory as requested by review feedback.

