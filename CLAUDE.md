# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Home Assistant add-on repository containing 120+ Docker-based add-ons for the Home Assistant Supervisor. Each add-on is a self-contained directory with a Dockerfile, config schema, and S6-overlay init scripts. The repository uses GitHub Actions for CI/CD, linting, and automated upstream version tracking.

## Add-On Directory Structure

Most add-ons follow this common layout, though exceptions exist (e.g. some archived add-ons use `config.json` instead of `config.yaml`, some add-ons have `build.yaml` instead of `build.json` or no build file at all, and not every add-on includes a `rootfs/` tree):

```
addon_name/
├── config.yaml          # HA add-on metadata, schema, ports, maps
├── build.json           # Base Docker images per architecture (may be build.yaml, or absent)
├── Dockerfile           # Multi-stage build (always uses shared .templates/ scripts)
├── updater.json         # Upstream release tracking; required to enable automatic updates
├── CHANGELOG.md         # Required; must be updated on every PR
└── rootfs/              # Optional; absent in some add-ons
    └── etc/
        ├── cont-init.d/ # S6-overlay init scripts (numbered, run in order)
        └── services.d/  # S6-overlay supervised services (some add-ons use
                         # s6-overlay v3 layout at etc/s6-overlay/s6-rc.d/ instead)
```

## Dockerfile Convention

Most Dockerfiles follow this 6-section pattern (some add-ons deviate slightly, e.g. using a pinned upstream image directly instead of `ARG BUILD_FROM`):

1. **Build Image** – `ARG BUILD_FROM` + `FROM ${BUILD_FROM}`
2. **Modify Image** – S6 env vars, LSIO modifications via `ha_lsio.sh`
3. **Install Apps** – Copy `rootfs/`, download modules, install packages
4. **Entrypoint** – Set `S6_STAGE2_HOOK=/ha_entrypoint.sh`
5. **Labels** – Standard OCI + HA labels from build args
6. **Healthcheck** – curl-based check suppressed from nginx/apache logs

Shared build-time scripts are pulled from `.templates/` at build time:
- `ha_automodules.sh` – Downloads module scripts listed in `ARG MODULES=`
- `ha_autoapps.sh` – Installs packages listed in `ENV PACKAGES=`
- `ha_entrypoint.sh` – S6 stage-2 hook; launches the cont-init stack at container start
- `ha_lsio.sh` – Patches LinuxServer.io base images for HA compatibility
- `bashio-standalone.sh` – Bashio library for scripts outside Supervisor context

The `ARG MODULES=` line lists template scripts to download at build time (e.g., `00-banner.sh 01-custom_script.sh 00-smb_mounts.sh`). Commonly-used modules in `.templates/` (not exhaustive):
- `00-global_var.sh` – Initialize global env vars from HA options
- `00-local_mounts.sh` – Mount local disks (localdisks option)
- `00-smb_mounts.sh` – SMB/CIFS network mount support
- `01-config_yaml.sh` – Map HA options → app's `config.yaml`
- `01-custom_script.sh` – Run user-provided custom scripts
- `90-disable_ingress.sh` – Allow disabling HA ingress
- `90-dns_set.sh` – Configure custom DNS
- `91-universal_graphic_drivers.sh` – GPU driver detection
- `19-json_repair.sh` – Validate/repair JSON config files

## config.yaml Schema

Key fields in every add-on's `config.yaml`:

```yaml
arch: [aarch64, amd64]
image: ghcr.io/alexbelgium/{slug}-{arch}
version: "X.Y.Z"          # upstream version (format varies; see Versioning section)
ingress: true/false
ingress_port: 8000
map:
  - addon_config:rw        # /addon_configs/<hostname>/
  - share:rw
  - media:rw
  - ssl
schema:
  env_vars:                # Allows arbitrary env var passthrough
    - name: match(^[A-Za-z0-9_]+$)
      value: str?
  PUID: int
  PGID: int
  TZ: str?
  networkdisks: str?       # SMB mounts
  localdisks: str?         # Local disk mounts
```

The `env_vars` schema key enables the env-var passthrough mechanism. At runtime the `00-global_var.sh` cont-init module reads `/data/options.json` and exports each key as an environment variable (writing to `/.env` and `/etc/environment`). `ha_entrypoint.sh` is the S6 stage-2 hook that launches the cont-init stack but does not itself perform the JSON-to-env conversion.

## Versioning

Add-on versions in `config.yaml` closely follow the upstream release tag and do not conform to a single fixed format. Common patterns include:

- `X.Y.Z` – plain upstream semver (e.g. `0.137.0`)
- `X.Y.Z-N` – upstream version with a local patch counter (e.g. `0.6.26-2`)
- LSIO-style tags (e.g. `1.43.1.10611-1e34174b1-ls301`)
- Date-based versions (e.g. `2026.02.28`)
- Nightly builds (e.g. `nightly-20260321-397`)

When an upstream version is bumped, update `version` in `config.yaml`. If the add-on's `Dockerfile` contains an `ARG BUILD_UPSTREAM` line, update that value too — it is the canonical place that records the upstream version at build time (it is **not** stored in `build.json`/`build.yaml`). Some add-ons do not use `BUILD_UPSTREAM` at all. The `updater.json` file tracks which upstream source/repo to monitor and records the last seen version.

## updater.json Format

```json
{
  "source": "github",           // github|dockerhub|pip|gitlab|bitbucket|helm_chart|...
  "upstream_repo": "owner/repo",
  "upstream_version": "1.2.3",  // auto-populated by addons_updater
  "slug": "addon_slug",
  "last_update": "2025-01-01",
  "github_beta": false,
  "github_fulltag": false,      // true = keep "v3.0.1-ls67", false = strip to "3.0.1"
  "github_tagfilter": "",       // require this text in release tag
  "github_exclude": "",         // exclude releases containing this text
  "paused": false
}
```

## CI/CD Workflows

**On push to master** (`onpush_builder.yaml`): Detects changed add-ons by watching `config.*` files, then sanitizes text files (Unicode spaces → ASCII, CRLF → LF) and restores shell script permissions. Auto-commits fixes with `[nobuild]` to skip rebuild loop.

**On PR** (`onpr_check-pr.yaml`): Validates CHANGELOG.md was updated, runs HA addon-linter, and tests Docker build for all changed add-ons.

**Weekly** (`lint.yml`): Runs Super-Linter across the repo, fixes shell formatting with shfmt (4-space indent), opens PRs for automated fixes.

**Weekly** (`weekly_addons_updater`): Runs the `addons_updater` container to bump add-on versions to match upstream.

Adding `[nobuild]` anywhere in a commit message skips the builder workflow.

## Linting Rules

| Tool | Config | Key ignores |
|------|--------|------------|
| Hadolint | `.hadolint.yaml` | DL3002, DL3006-9, DL3018 (no pinning required) |
| ShellCheck | `.shellcheckrc` | SC2002 |
| Markdownlint | `.markdownlint.yaml` | MD013 (line length), MD025, MD033, MD041 |
| shfmt | (CI enforced) | 4-space indent |

## PR Requirements

1. Update `CHANGELOG.md` in every changed add-on (CI validates this).
2. Bump `version` in `config.yaml`.
3. All linting must pass (Hadolint, ShellCheck, Markdownlint, HA addon-linter).
4. Docker build must succeed for all declared architectures.

## S6-Overlay Init Script Naming

Scripts in `rootfs/etc/cont-init.d/` run in lexicographic order. Common numbering conventions (many add-ons use other prefixes too):
- `20-*` – Directory/folder setup
- `32-*` – Nginx ingress configuration (e.g. `32-nginx_ingress.sh`)
- `80-*` – Application configuration
- `90-*` – Misc pre-startup tasks (ssl, vpn, custom run)
- `99-*` – Final startup / launch
