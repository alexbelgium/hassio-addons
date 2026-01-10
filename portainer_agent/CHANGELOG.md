## 2025.12-6 (2025-12-31)
- Minor bugs fixed
## 2025.12-5 (2025-12-31)
- Minor bugs fixed
## 2025.12-4 (2025-12-31)
- Minor bugs fixed
## 2025.12-3 (2025-12-31)
- Minor bugs fixed
## 2025.12-2 (2025-12-31)
- Minor bugs fixed
## alpine-sts-3 (2025-12-30)
- Minor bugs fixed
## alpine-sts-2 (2025-12-30)
- Minor bugs fixed
## alpine-sts (2025-12-30)

- Fix: Restore official Portainer Agent image source - Fix circular dependency (Fixes #2318)
- Revert COPY --from to use official ghcr.io/portainerci/agent:latest instead of self-reference
- Restored multi-architecture support via ARG BUILD_FROM/ARG BUILD_ARCH (fixes aarch64 builds)
- Removed stderr suppression to preserve error messages for user diagnostics
- This fixes build failures that prevented users from updating
- Updated config.yaml version tag to match buildable image tag

## alpine-sts-bashio-fix (2025-12-29)

- Fix: PROTECTION MODE IS ENABLED error when protection mode is OFF (Fixes #2307)
- Update bashio from v0.17.5 → main branch for improved API error handling
- Add robust protection mode check with Docker socket fallback
- Tested and verified working on Home Assistant OS


- Fix: PROTECTION MODE IS ENABLED error when protection mode is OFF (Fixes #2307)
- Update bashio from v0.17.5 → main branch for improved API error handling
- Add robust protection mode check with Docker socket fallback
- Tested and verified working on Home Assistant OS

## alpine-sts (2025-12-24)
- Update to latest version from portainer/agent

##  (2025-12-23)
- Update to latest version from portainer/agent
- The Home Assistant project has deprecated support for the armv7, armhf and i386 architectures. Support wil be fully dropped in the upcoming Home Assistant 2025.12 release

- Added support for configuring extra environment variables via the `env_vars` add-on option alongside config.yaml. See https://github.com/alexbelgium/hassio-addons/wiki/Add-Environment-variables-to-your-Addon-2 for details.

## alpine-sts (2025-05-24)
- Update to latest version from portainer/agent

## linux-arm64-2.21.5-alpine (2025-05-10)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.5-alpine (2024-12-21)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.4-alpine (2024-10-26)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.3-alpine (2024-10-12)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.2-alpine (2024-09-28)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.1-alpine (2024-09-14)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.0-rc2-alpine (2024-08-24)
- Update to latest version from portainer/agent

## linux-ppc64le-2.21.0-rc1-alpine (2024-08-17)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.3-alpine (2024-05-25)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.2-alpine (2024-05-04)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.1-alpine (2024-04-06)
- Update to latest version from portainer/agent

## linux-ppc64le-2.20.0-alpine (2024-03-23)
- Update to latest version from portainer/agent
## linux-arm64-2.19.4-alpine-3 (2024-03-21)
- Minor bugs fixed
## linux-arm64-2.19.4-alpine-2 (2024-03-14)
- Minor bugs fixed

## linux-arm64-2.19.4-alpine (2024-01-20)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.4 (2023-12-09)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.3 (2023-11-25)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.2 (2023-11-18)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.1 (2023-09-23)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.19.0 (2023-09-02)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.18.4 (2023-07-08)

- Update to latest version from portainer/agent

## windowsltsc2022-amd64-2.18.3 (2023-06-10)

- Update to latest version from portainer/agent

## 2.18.3-alpine (2023-05-27)

- Update to latest version from portainer/agent
## 2.18.2-7 (2023-05-22)

- Minor bugs fixed
## 2.18.2-6 (2023-05-21)

- Require unprotected
- Correct healthcheck
- First build
