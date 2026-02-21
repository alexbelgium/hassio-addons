# Changelog

## 1.0.3

- Added the add-on to this repository under the official add-on folder/slug name `manyfold`.
- Updated image namespace and repository metadata for this repository:
  - `image: ghcr.io/alexbelgium/manyfold-{arch}`
  - `url: https://github.com/alexbelgium/hassio-addons/tree/master/manyfold`
- Updated AppArmor profile name to `hassio-addons/manyfold`.

## 1.0.2

- Added build metadata for Home Assistant CI compatibility:
  - `manyfold/build.yaml` with multi-arch `build_from` entries
  - image template wiring in `config.yaml`
- Switched Docker base wiring to Home Assistant add-on build conventions:
  - `Dockerfile` now uses `ARG BUILD_FROM` and `FROM ${BUILD_FROM}`
- Updated add-on `url` metadata to this repository path.
- Updated repository README to remove obsolete `import_path` references.
- Added ShellCheck compatibility headers (`# shellcheck shell=bash`) to s6/entry scripts using `with-contenv`.
- Removed default-valued metadata keys (`apparmor`, `boot`, `ingress`, `stage`) to satisfy add-on linter rules.

## 1.0.1

- New resource tuning options for smaller HAOS hosts:
  - `web_concurrency`
  - `rails_max_threads`
  - `default_worker_concurrency`
  - `performance_worker_concurrency`
  - `max_file_upload_size`
  - `max_file_extract_size`
- Baseline AppArmor support:
  - `apparmor: true` in add-on metadata
  - `manyfold/apparmor.txt` profile
- Removed `import_path` option and runtime wiring to reduce confusion (it was not a web import endpoint).
- Kept ingress disabled and documented direct access on port `3214`.
- Host media mappings (`/share`, `/media`) are writable to support writable library paths like `/media/manyfold/models`.
- Home Assistant ingress/panel 404 issue by moving to direct web UI access model.
- Startup/runtime setup improvements:
  - Better path validation for configured library and thumbnails paths
  - Clearer startup logs and configuration summary
  - More robust secret/bootstrap handling and ownership setup
- Recommended small-server baseline (see README):
  - `web_concurrency: 1`
  - `rails_max_threads: 5`
  - `default_worker_concurrency: 2`
  - `performance_worker_concurrency: 1`

## 1.0.0

- First Home Assistant add-on packaging for Manyfold (`manyfold`).
- Runs `ghcr.io/manyfold3d/manyfold-solo` with persistent data under `/config`.
- Sidebar/web UI integration on port `3214`.
- Configurable storage paths and startup path safety checks.
- Non-root runtime defaults (`puid`/`pgid`) and startup ownership handling.
