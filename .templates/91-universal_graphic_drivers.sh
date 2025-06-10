#!/usr/bin/env bashio
set -e

if bashio::config.has_value "graphic_driver"; then

    # Origin : https://github.com/wumingjieno1/photoprism-test/blob/main/scripts/dist/install-gpu.sh
    # abort if not executed as root
    if [[ $(id -u) != "0" ]]; then
        # shellcheck disable=SC2128
        bashio::log.fatal "Error: Run $(basename "${BASH_SOURCE}") as root" 1>&2
        exit 1
  fi

    # Get installer type
    if [ -f /usr/bin/apt ]; then
        bashio::log.info "... Distribution detected : Debian/Ubuntu"
        apt-get install -yqq software-properties-common >/dev/null
        add-apt-repository ppa:kisak/kisak-mesa >/dev/null
        apt-get update >/dev/null
        apt-get install -yqq mesa
  elif   [ -f /usr/bin/apk ]; then
        bashio::log.info "... Distribution detected : Alpine"
  fi

    # Detect GPU
    # shellcheck disable=SC2207
    GPU_DETECTED=($(lshw -c display -json 2>/dev/null | jq -r '.[].configuration.driver'))
    bashio::log.info "... GPU detected: ${GPU_DETECTED[*]}"
    graphic_driver=""

    # Get arch type
    BUILD_ARCH="$(uname -m)"
    case "$BUILD_ARCH" in
        amd64 | AMD64 | x86_64 | x86-64)
            BUILD_ARCH=amd64
            ;;

        arm64 | ARM64 | aarch64)
            BUILD_ARCH=arm64
            graphic_driver=aarch64_rpi
            ;;

        arm | ARM | aarch | armv7l | armhf)
            bashio::log.fatal "Unsupported Machine Architecture: $BUILD_ARCH" 1>&2
            exit 1
            ;;

        *)
            bashio::log.fatal "Unsupported Machine Architecture: $BUILD_ARCH" 1>&2
            exit 1
            ;;
  esac
    bashio::log.info "... architecture detected: ${BUILD_ARCH}"

    #graphic_driver="$(bashio::config "graphic_driver")"
    case "$graphic_driver" in
        x64_AMD)
            if [[ "$BUILD_ARCH" != amd64 ]]; then bashio::log.fatal "Wrong architecture, $graphic_driver doesn't support $BUILD_ARCH"; fi
            [ -f /usr/bin/apt ] && DOCKER_MODS=linuxserver/mods:jellyfin-amd && run_mods >/dev/null && bashio::log.green "... done"
            [ -f /usr/bin/apk ] && apk add --no-cache mesa-dri-classic mesa-vdpau-gallium linux-firmware-radeon >/dev/null && bashio::log.green "... done"
            ;;

        x64_NVIDIA)
            if [[ "$BUILD_ARCH" != amd64 ]]; then bashio::log.fatal "Wrong architecture, $graphic_driver doesn't support $BUILD_ARCH"; fi
            [ -f /usr/bin/apk ] && apk add --no-cache linux-firmware-radeon >/dev/null && bashio::log.green "... done"
            [ -f /usr/bin/apt ] && apt-get -yqq install libcuda1 libnvcuvid1 libnvidia-encode1 nvidia-opencl-icd nvidia-vdpau-driver nvidia-driver-libs nvidia-kernel-dkms libva2 vainfo libva-wayland2 >/dev/null && bashio::log.green "... done"
            ;;

        x64_Intel)
            if [[ "$BUILD_ARCH" != amd64 ]]; then bashio::log.fatal "Wrong architecture, $graphic_driver doesn't support $BUILD_ARCH"; fi
            [ -f /usr/bin/apk ] && apk add --no-cache opencl mesa-dri-gallium mesa-vulkan-intel mesa-dri-intel intel-media-driver >/dev/null && bashio::log.green "... done"
            [ -f /usr/bin/apt ] && DOCKER_MODS=linuxserver/mods:jellyfin-opencl-intel && run_mods && apt-get -yqq install intel-opencl-icd intel-media-va-driver-non-free i965-va-driver-shaders mesa-va-drivers libmfx1 libva2 vainfo libva-wayland2 >/dev/null && bashio::log.green "... done"
            ;;

        aarch64_rpi)
            if [[ "$BUILD_ARCH" != arm64 ]]; then bashio::log.fatal "Wrong architecture, $graphic_driver doesn't support $BUILD_ARCH"; fi
            bashio::log.info "Installing Rpi graphic drivers"
            [ -f /usr/bin/apk ] && apk add --no-cache mesa-dri-vc4 mesa-dri-swrast mesa-gbm xf86-video-fbdev >/dev/null && bashio::log.green "... done"
            [ -f /usr/bin/apt ] && apt-get -yqq install libgles2-mesa libgles2-mesa-dev xorg-dev >/dev/null && bashio::log.green "... done"
            ;;

  esac

    # Main run logic
    run_mods() {
        echo "[mod-init] Attempting to run Docker Modification Logic"
        for DOCKER_MOD in $(echo "${DOCKER_MODS}" | tr '|' '\n'); do
            # Support alternative endpoints
            if [[ ${DOCKER_MOD} == ghcr.io/* ]] || [[ ${DOCKER_MOD} == linuxserver/* ]]; then
                DOCKER_MOD="${DOCKER_MOD#ghcr.io/*}"
                ENDPOINT="${DOCKER_MOD%%:*}"
                USERNAME="${DOCKER_MOD%%/*}"
                REPO="${ENDPOINT#*/}"
                TAG="${DOCKER_MOD#*:}"
                if [[ ${TAG} == "${DOCKER_MOD}" ]]; then
                    TAG="latest"
        fi
                FILENAME="${USERNAME}.${REPO}.${TAG}"
                AUTH_URL="https://ghcr.io/token?scope=repository%3A${USERNAME}%2F${REPO}%3Apull"
                MANIFEST_URL="https://ghcr.io/v2/${ENDPOINT}/manifests/${TAG}"
                BLOB_URL="https://ghcr.io/v2/${ENDPOINT}/blobs/"
                MODE="ghcr"
      else
                ENDPOINT="${DOCKER_MOD%%:*}"
                USERNAME="${DOCKER_MOD%%/*}"
                REPO="${ENDPOINT#*/}"
                TAG="${DOCKER_MOD#*:}"
                if [[ ${TAG} == "${DOCKER_MOD}" ]]; then
                    TAG="latest"
        fi
                FILENAME="${USERNAME}.${REPO}.${TAG}"
                AUTH_URL="https://auth.docker.io/token?service=registry.docker.io&scope=repository:${ENDPOINT}:pull"
                MANIFEST_URL="https://registry-1.docker.io/v2/${ENDPOINT}/manifests/${TAG}"
                BLOB_URL="https://registry-1.docker.io/v2/${ENDPOINT}/blobs/"
                MODE="dockerhub"
      fi
            # Kill off modification logic if any of the usernames are banned
            for BANNED in $(curl -s https://raw.githubusercontent.com/linuxserver/docker-mods/master/blacklist.txt); do
                if [[ "${BANNED,,}" == "${USERNAME,,}" ]]; then
                    if [[ -z ${RUN_BANNED_MODS+x} ]]; then
                        echo "[mod-init] ${DOCKER_MOD} is banned from use due to reported abuse aborting mod logic"
                        return
          else
                        echo "[mod-init] You have chosen to run banned mods ${DOCKER_MOD} will be applied"
          fi
        fi
      done
            echo "[mod-init] Applying ${DOCKER_MOD} files to container"
            # Get Dockerhub token for api operations
            TOKEN="$(
                curl -f --retry 10 --retry-max-time 60 --retry-connrefused \
                    --silent \
                    --header 'GET' \
                    "${AUTH_URL}" |
                jq -r '.token'
      )"
            # Determine first and only layer of image
            SHALAYER=$(get_blob_sha "${MODE}" "${TOKEN}" "${MANIFEST_URL}")
            # Check if we have allready applied this layer
            if [[ -f "/${FILENAME}" ]] && [[ "${SHALAYER}" == "$(cat /"${FILENAME}")" ]]; then
                echo "[mod-init] ${DOCKER_MOD} at ${SHALAYER} has been previously applied skipping"
      else
                # Download and extract layer to /
                curl -f --retry 10 --retry-max-time 60 --retry-connrefused \
                    --silent \
                    --location \
                    --request GET \
                    --header "Authorization: Bearer ${TOKEN}" \
                    "${BLOB_URL}${SHALAYER}" -o \
                    /modtarball.tar.xz
                mkdir -p /tmp/mod
                tar xzf /modtarball.tar.xz -C /tmp/mod
                if [[ -d /tmp/mod/etc/s6-overlay ]]; then
                    if [[ -d /tmp/mod/etc/cont-init.d ]]; then
                        rm -rf /tmp/mod/etc/cont-init.d
          fi
                    if [[ -d /tmp/mod/etc/services.d ]]; then
                        rm -rf /tmp/mod/etc/services.d
          fi
        fi
                shopt -s dotglob
                cp -R /tmp/mod/* /
                shopt -u dotglob
                rm -rf /tmp/mod
                rm -rf /modtarball.tar.xz
                echo "${SHALAYER}" >"/${FILENAME}"
                echo "[mod-init] ${DOCKER_MOD} applied to container"
      fi
    done
  }

fi
