## 2025.12-4 (31-12-2025)
- Minor bugs fixed
## 2025.12-3 (31-12-2025)
- Minor bugs fixed
## 2025.12-2 (31-12-2025)
- Minor bugs fixed
## alpine-sts-3 (30-12-2025)
- Minor bugs fixed
## alpine-sts-2 (30-12-2025)
- Minor bugs fixed
## alpine-sts (30-12-2025)

- Fix: Restore official Portainer Agent image source - Fix circular dependency (Fixes #2318)
- Revert COPY --from to use official ghcr.io/portainerci/agent:latest instead of self-reference
- Restored multi-architecture support via ARG BUILD_FROM/ARG BUILD_ARCH (fixes aarch64 builds)
- Removed stderr suppression to preserve error messages for user diagnostics
- This fixes build failures that prevented users from updating
- Updated config.yaml version tag to match buildable image tag

## alpine-sts-bashio-fix (29-12-2025)

- Fix: PROTECTION MODE IS ENABLED error when protection mode is OFF (Fixes #2307)
- Update bashio from v0.17.5 → main branch for improved API error handling
- Add robust protection mode check with Docker socket fallback
- Tested and verified working on Home Assistant OS


- Fix: PROTECTION MODE IS ENABLED error when protection mode is OFF (Fixes #2307)
- Update bashio from v0.17.5 → main branch for improved API error handling
- Add robust protection mode check with Docker socket fallback
- Tested and verified working on Home Assistant OS

## alpine-sts (24-12-2025)
- Update to latest version from portainer/agent

##  (23-12-2025)
- Update to latest version from portainer/agent
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## alpine-sts (24-05-2025)
- Update to latest version from portainer/agent

## linux-arm64-2.21.5-alpine (10-05-2025)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.5-alpine (21-12-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.4-alpine (26-10-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.3-alpine (12-10-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.2-alpine (28-09-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.1-alpine (14-09-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.0-rc2-alpine (24-08-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.0-rc1-alpine (17-08-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.3-alpine (25-05-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.2-alpine (04-05-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.1-alpine (06-04-2024)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.0-alpine (23-03-2024)
- Update to latest version from portainer/agent
## linux-arm64-2.19.4-alpine-3 (21-03-2024)
- Minor bugs fixed
## linux-arm64-2.19.4-alpine-2 (14-03-2024)
- Minor bugs fixed

## linux-arm64-2.19.4-alpine (20-01-2024)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.4 (09-12-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.3 (25-11-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.2 (18-11-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.1 (23-09-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.0 (02-09-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.18.4 (08-07-2023)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.18.3 (10-06-2023)

- Update to latest version from portainer/agent

## 2.18.3-alpine (27-05-2023)

- Update to latest version from portainer/agent
## 2.18.2-7 (22-05-2023)

- Minor bugs fixed
## 2.18.2-6 (21-05-2023)

- Require unprotected
- Correct healthcheck
- First build
