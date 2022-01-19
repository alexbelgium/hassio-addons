#!/usr/bin/env bashio
######################
# Home Assistant Build-env
######################
set -e
set +u

#### Variable ####

DOCKER_TIMEOUT=20
DOCKER_PID=-1
DOCKER_HUB=
DOCKER_HUB_CHECK=false
DOCKER_CACHE=true
DOCKER_LATEST=true
DOCKER_PUSH=true
DOCKER_USER=
DOCKER_PASSWORD=
DOCKER_LOCAL=false
SELF_CACHE=false
CUSTOM_CACHE_TAG=
RELEASE_TAG=false
GIT_REPOSITORY=
GIT_BRANCH="master"
TARGET=
VERSION=
VERSION_BASE=
VERSION_FROM=
IMAGE=
RELEASE=
ADDITIONAL_TAGS=()
BUILD_LIST=()
BUILD_TYPE="addon"
BUILD_TASKS=()
BUILD_ERROR=()
declare -A BUILD_MACHINE=(
                          [generic-x86-64]="amd64" \
                          [intel-nuc]="amd64" \
                          [khadas-vim3]="aarch64" \
                          [odroid-c2]="aarch64" \
                          [odroid-c4]="aarch64" \
                          [odroid-n2]="aarch64" \
                          [odroid-xu]="armv7" \
                          [qemuarm]="armhf" \
                          [qemuarm-64]="aarch64" \
                          [qemux86]="i386" \
                          [qemux86-64]="amd64" \
                          [raspberrypi]="armhf" \
                          [raspberrypi2]="armv7" \
                          [raspberrypi3]="armv7" \
                          [raspberrypi3-64]="aarch64" \
                          [raspberrypi4]="armv7" \
                          [raspberrypi4-64]="aarch64" \
                          [tinker]="armv7" )


#### Misc functions ####

function print_help() {
    cat << EOF
Hass.io build-env for ecosystem:
docker run --rm homeassistant/{arch}-builder:latest [options]

Options:
  -h, --help
        Display this help and exit.

  Repository / Data
    -r, --repository <REPOSITORY>
        Set git repository to load data from.
    -b, --branch <BRANCH>
        Set git branch for repository.
    -t, --target <PATH_TO_BUILD>
        Set local folder or path inside repository for build.

  Version/Image handling
    -v, --version <VERSION>
        Overwrite version/tag of build.
    -i, --image <IMAGE_NAME>
        Overwrite image name of build / support {arch}.
    --release <VERSION>
        Additional version information like for base images.
    --release-tag
        Use this as main tag.
    --additional-tag
        Add additional tags that will be published
    --version-from <VERSION>
        Use this to set build_from tag if not specified.

  Architecture
    --armhf
        Build for arm v6.
    --armv7
        Build for arm v7.
    --amd64
        Build for intel/amd 64bit.
    --aarch64
        Build for arm 64bit.
    --i386
        Build for intel/amd 32bit.
    --all
        Build all architecture.

  Build handling
    --test
       Disable push to dockerhub.
    --no-latest
       Do not tag images as latest.
    --no-cache
       Disable cache for the build (from latest).
    --self-cache
       Use same tag as cache tag instead latest.
    --cache-tag <TAG>
       Use a custom tag for the build cache.
    -d, --docker-hub <DOCKER_REPOSITORY>
       Set or overwrite the docker repository.
    --docker-hub-check
       Check if the version already exists before starting the build.
    --docker-user <USER>
       Username to login into docker with
    --docker-password <PASSWORD>
       Password to login into docker with

    Use the host docker socket if mapped into container:
       /var/run/docker.sock

  Internals:
    --addon
        Default on. Run all things for an addon build.
    --generic <VERSION>
        Build based on the build.json
    --base <VERSION>
        Build our base images.
    --machine <VERSION=ALL,X,Y>
        Build the machine based image for a release/landingpage.

  Security:
    Enable signing images with Codenotary. Need set follow env:
    - CAS_API_KEY
EOF

    bashio::exit.nok
}

#### Docker functions ####

function start_docker() {
    local starttime
    local endtime

    if [ -S "/var/run/docker.sock" ]; then
        bashio::log.info "Using host docker setup with '/var/run/docker.sock'"
        DOCKER_LOCAL="true"
        return 0
    fi

    bashio::log.info "Starting docker."
    dockerd 2> /dev/null &
    DOCKER_PID=$!

    bashio::log.info "Waiting for docker to initialize..."
    starttime="$(date +%s)"
    endtime="$(date +%s)"
    until docker info >/dev/null 2>&1; do
        if [ $((endtime - starttime)) -le $DOCKER_TIMEOUT ]; then
            sleep 1
            endtime=$(date +%s)
        else
            bashio::exit.nok "Timeout while waiting for docker to come up"
        fi
    done
    bashio::log.info "Docker was initialized"
}


function stop_docker() {
    local starttime
    local endtime

    if [ "$DOCKER_LOCAL" == "true" ]; then
        return 0
    fi

    bashio::log.info "Stopping in container docker..."
    if [ "$DOCKER_PID" -gt 0 ] && kill -0 "$DOCKER_PID" 2> /dev/null; then
        starttime="$(date +%s)"
        endtime="$(date +%s)"

        # Now wait for it to die
        kill "$DOCKER_PID"
        while kill -0 "$DOCKER_PID" 2> /dev/null; do
            if [ $((endtime - starttime)) -le $DOCKER_TIMEOUT ]; then
                sleep 1
                endtime=$(date +%s)
            else
                bashio::exit.nok "Timeout while waiting for container docker to die"
            fi
        done
    else
        bashio::log.warning "Your host might have been left with unreleased resources"
    fi
}


function run_build() {
    local build_dir=$1
    local repository=$2
    local image=$3
    local version=$4
    local build_from=$5
    local build_arch=$6
    local docker_cli=("${!7}")
    local docker_tags=("${!8}")
    local shadow_repository=${9}
    local codenotary_base=${10}
    local codenotary_sign=${11}

    local push_images=()
    local cache_tag="latest"
    local metadata
    local release="${version}"

    # Overwrites
    if bashio::var.has_value "${DOCKER_HUB}"; then repository="${DOCKER_HUB@L}"; fi
    if bashio::var.has_value "${IMAGE}"; then image="${IMAGE@L}"; fi
    if bashio::var.has_value "${RELEASE}"; then release="${RELEASE}"; fi

    # Replace {arch} with build arch for image
    # shellcheck disable=SC1117
    image="$(echo "${image}" | sed -r "s/\{arch\}/${build_arch}/g")"

    # Check if image exists on docker hub
    if bashio::var.true "$DOCKER_HUB_CHECK"; then
        metadata="$(curl -s "https://hub.docker.com/v2/repositories/${repository}/${image}/tags/${version}/")"

        if bashio::var.has_value "${metadata}" && [[ "$(echo "${metadata}" | jq --raw-output '.name')" == "${version}" ]]; then
            bashio::log.info "Skip build, found ${image}:${version} on dockerhub"
            return 0
        else
            bashio::log.info "Start build, ${image}:${version} is not on dockerhub"
        fi
    fi

    # Init Cache
    if bashio::var.true "${DOCKER_CACHE}"; then
        if bashio::var.has_value "${CUSTOM_CACHE_TAG}"; then
            cache_tag="${CUSTOM_CACHE_TAG}"
        elif bashio::var.true "${SELF_CACHE}"; then
            cache_tag="${version}"
        fi

        bashio::log.info "Init cache for ${repository}/${image}:${version} with tag ${cache_tag}"
        if docker pull "${repository}/${image}:${cache_tag}" > /dev/null 2>&1 && codenotary_validate "${codenotary_sign}" "${repository}/${image}:${cache_tag}" "false"; then
            docker_cli+=("--cache-from" "${repository}/${image}:${cache_tag}")
        else
            docker_cli+=("--no-cache")
            bashio::log.warning "No cache image found. Disabling cache for this build."
        fi
    else
        docker_cli+=("--no-cache")
    fi

    # Set Labels
    docker_cli+=("--label" "io.hass.arch=${build_arch}")
    docker_cli+=("--label" "org.opencontainers.image.created=$(date --rfc-3339=seconds --utc)")
    docker_cli+=("--label" "io.hass.version=${release}")
    docker_cli+=("--label" "org.opencontainers.image.version=${release}")

    # Validate the base image
    if ! codenotary_validate "${codenotary_base}" "${build_from}" "true"; then
        bashio::exit.nok "Invalid base image ${build_from}"
    fi

    # Build image
    bashio::log.info "Run build for ${repository}/${image}:${version}"
    docker build --pull --platform /linux/${build_arch} -t "${repository}/${image}:${version}" \
        --build-arg "BUILD_FROM=${build_from}" \
        --build-arg "BUILD_VERSION=${version}" \
        --build-arg "BUILD_ARCH=${build_arch}" \
        "${docker_cli[@]}" \
        "${build_dir}"

    # Success?
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        BUILD_ERROR+=("${repository}/${image}:${version}")
        return 0
    fi

    push_images+=("${repository}/${image}:${version}")
    bashio::log.info "Finish build for ${repository}/${image}:${version}"

    # Tag latest
    if bashio::var.true "${DOCKER_LATEST}"; then
        docker_tags+=("latest")
    fi

    # Add additional tags
    for tag_image in "${ADDITIONAL_TAGS[@]}"; do
        docker_tags+=("${tag_image}")
    done

    # Tag images
    for tag_image in "${docker_tags[@]}"; do
        bashio::log.info "Create image tag: ${tag_image}"
        docker tag "${repository}/${image}:${version}" "${repository}/${image}:${tag_image}"
        push_images+=("${repository}/${image}:${tag_image}")
    done

    # Use shaddow repository
    if bashio::var.has_value "${shadow_repository}"; then
        bashio::log.info "Generate repository shadow images"
        docker tag "${repository}/${image}:${version}" "${shadow_repository}/${image}:${version}"
        for tag_image in "${docker_tags[@]}"; do
            bashio::log.info "Create shadow-image tag: ${shadow_repository}/${image}:${tag_image}"
            docker tag "${repository}/${image}:${version}" "${shadow_repository}/${image}:${tag_image}"
            push_images+=("${shadow_repository}/${image}:${tag_image}")
        done
        push_images+=("${shadow_repository}/${image}:${version}")
    fi

    # Singing image
    codenotary_sign "${codenotary_sign}" "${repository}/${image}:${version}"

    # Push images
    if bashio::var.true "${DOCKER_PUSH}"; then
        for i in "${push_images[@]}"; do
            for j in {1..3}; do
                bashio::log.info "Start upload of ${i} (attempt #${j}/3)"
                if docker push "${i}" > /dev/null 2>&1; then
                    bashio::log.info "Upload succeeded on attempt #${j}"
                    break
                fi
                if [[ "${j}" == "3" ]]; then
                    bashio::exit.nok "Upload failed on attempt #${j}"
                else
                    bashio::log.warning "Upload failed on attempt #${j}"
                    sleep 30
                fi
            done
        done
    fi
}

function convert_to_json() {
    # Convert [build|config].[yml|yaml] to json in a temp directory
    mkdir -p /tmp/build_config
    for file in config build; do
        if bashio::fs.file_exists "${TARGET}/${file}.yml"; then
            yq e -N -M -o=json "${TARGET}/${file}.yml" > "/tmp/build_config/${file}.json"
        elif bashio::fs.file_exists "${TARGET}/${file}.yaml"; then
            yq e -N -M -o=json "${TARGET}/${file}.yaml" > "/tmp/build_config/${file}.json"
        fi
    done
}

function copy_config_tmp() {
    # Copy [build|config].json to a temp directory
    mkdir -p /tmp/build_config
    for file in config build; do
        if bashio::fs.file_exists "${TARGET}/${file}.json"; then
            cp "${TARGET}/${file}.json" "/tmp/build_config/${file}.json"
        fi
    done
}



#### Build functions ####

function build_base() {
    local build_arch=${1}

    local build_from=
    local image=
    local repository=
    local shadow_repository=
    local raw_image=
    local args=
    local codenotary_base=
    local codenotary_sign=
    local docker_cli=()
    local docker_tags=()

    # Read build.json
    if bashio::fs.file_exists "/tmp/build_config/build.json"; then
        build_from="$(jq --raw-output ".build_from.${build_arch} // empty" "/tmp/build_config/build.json")"
        args="$(jq --raw-output '.args // empty | keys[]' "/tmp/build_config/build.json")"
        labels="$(jq --raw-output '.labels // empty | keys[]' "/tmp/build_config/build.json")"
        raw_image="$(jq --raw-output '.image // empty' "/tmp/build_config/build.json")"
        shadow_repository="$(jq --raw-output '.shadow_repository // empty' "/tmp/build_config/build.json")"
        codenotary_base="$(jq --raw-output '.codenotary.base_image // empty' "/tmp/build_config/build.json")"
        codenotary_sign="$(jq --raw-output '.codenotary.signer // empty' "/tmp/build_config/build.json")"
    fi

    # Set defaults build things
    if ! bashio::var.has_value "${build_from}"; then
        bashio::log.error "${build_arch} not supported for this build"
        return 1
    fi

    # Modify build_from
    if [[ "${build_from}" =~ :$ ]]; then
        if bashio::var.has_value "${VERSION_FROM}"; then
            build_from="${build_from}${VERSION_FROM}"
        else
            build_from="${build_from}${VERSION_BASE}"
        fi
    fi
    bashio::log.info "Use BUILD_FROM: ${build_from}"

    # Read data from image
    if ! bashio::var.has_value "${raw_image}"; then
        bashio::log.error "Can't find the image tag on build.json"
        return 1
    fi
    repository="$(echo "${raw_image}" | cut -f 1 -d '/')"
    image="$(echo "${raw_image}" | cut -f 2 -d '/')"

    # Additional build args
    if bashio::var.has_value "${args}"; then
        for arg in ${args}; do
            value="$(jq --raw-output ".args.${arg}" "/tmp/build_config/build.json")"
            docker_cli+=("--build-arg" "${arg}=${value}")
        done
    fi

    # Additional build labels
    if bashio::var.has_value "${labels}"; then
        for label in ${labels}; do
            value="$(jq --raw-output ".labels.\"${label}\"" "/tmp/build_config/build.json")"
            docker_cli+=("--label" "${label}=${value}")
        done
    fi

    # Tag with version/build
    if bashio::var.true "${RELEASE_TAG}"; then
        docker_tags=("${VERSION}")
    fi

    # Set type
    docker_cli+=("--label" "io.hass.type=base")
    docker_cli+=("--label" "io.hass.base.version=${RELEASE}")
    docker_cli+=("--label" "io.hass.base.arch=${build_arch}")
    docker_cli+=("--label" "io.hass.base.image=${build_from}")

    # Start build
    run_build "${TARGET}" "${repository}" "${image}" "${VERSION_BASE}" \
        "${build_from}" "${build_arch}" docker_cli[@] docker_tags[@] "${shadow_repository}" \
        "${codenotary_base}" "${codenotary_sign}"
}


function build_addon() {
    local build_arch=$1

    local build_from=
    local version=
    local image=
    local repository=
    local shadow_repository=
    local raw_image=
    local name=
    local description=
    local url=
    local args=
    local codenotary_base=
    local codenotary_sign=
    local docker_cli=()
    local docker_tags=()

    # Read addon build.json
    if bashio::fs.file_exists "/tmp/build_config/build.json"; then
        build_from="$(jq --raw-output ".build_from.$build_arch // empty" "/tmp/build_config/build.json")"
        args="$(jq --raw-output '.args // empty | keys[]' "/tmp/build_config/build.json")"
        shadow_repository="$(jq --raw-output '.shadow_repository // empty' "/tmp/build_config/build.json")"
        codenotary_base="$(jq --raw-output '.codenotary.base_image // empty' "/tmp/build_config/build.json")"
        codenotary_sign="$(jq --raw-output '.codenotary.signer // empty' "/tmp/build_config/build.json")"
    fi

    # Set defaults build things
    if [ -z "$build_from" ]; then
        build_from="homeassistant/${build_arch}-base:latest"
    fi

    # Additional build args
    if [ -n "$args" ]; then
        for arg in $args; do
            value="$(jq --raw-output ".args.$arg" "/tmp/build_config/build.json")"
            docker_cli+=("--build-arg" "$arg=$value")
        done
    fi

    # Read addon config.json
    name="$(jq --raw-output '.name // empty' "/tmp/build_config/config.json" | sed "s/'//g")"
    description="$(jq --raw-output '.description // empty' "/tmp/build_config/config.json" | sed "s/'//g")"
    url="$(jq --raw-output '.url // empty' "/tmp/build_config/config.json")"
    raw_image="$(jq --raw-output '.image // empty' "/tmp/build_config/config.json")"
    mapfile -t supported_arch < <(jq --raw-output '.arch // empty' "/tmp/build_config/config.json")
    
    # Read version from config.json when VERSION is not set
    if [ -n "$VERSION" ]; then
    	version="$VERSION"
    else
    	version="$(jq --raw-output '.version' "/tmp/build_config/config.json")"
    fi

    # Check arch
    if [[ ! ${supported_arch[*]} =~ ${build_arch} ]]; then
        bashio::log.error "$build_arch not supported for this add-on"
        return 1
    fi

    # Read data from image
    if [ -n "$raw_image" ]; then
        repository="$(echo "$raw_image" | cut -f 1 -d '/')"
        image="$(echo "$raw_image" | cut -f 2 -d '/')"
    fi

    # Set additional labels
    docker_cli+=("--label" "io.hass.name=$name")
    docker_cli+=("--label" "io.hass.description=$description")
    docker_cli+=("--label" "io.hass.type=addon")

    if [ -n "$url" ]; then
        docker_cli+=("--label" "io.hass.url=$url")
    fi

    # Start build
    run_build "$TARGET" "$repository" "$image" "$version" \
        "$build_from" "$build_arch" docker_cli[@] docker_tags[@] "${shadow_repository}" \
        "${codenotary_base}" "${codenotary_sign}"
}


function build_generic() {
    local build_arch=$1

    local build_from=
    local image=
    local repository=
    local shadow_repository=
    local raw_image=
    local args=
    local codenotary_base=
    local codenotary_sign=
    local docker_cli=()
    local docker_tags=()

    # Read build.json
    if bashio::fs.file_exists "/tmp/build_config/build.json"; then
        build_from="$(jq --raw-output ".build_from.$build_arch // empty" "/tmp/build_config/build.json")"
        args="$(jq --raw-output '.args // empty | keys[]' "/tmp/build_config/build.json")"
        labels="$(jq --raw-output '.labels // empty | keys[]' "/tmp/build_config/build.json")"
        raw_image="$(jq --raw-output '.image // empty' "/tmp/build_config/build.json")"
        shadow_repository="$(jq --raw-output '.shadow_repository // empty' "/tmp/build_config/build.json")"
        codenotary_base="$(jq --raw-output '.codenotary.base_image // empty' "/tmp/build_config/build.json")"
        codenotary_sign="$(jq --raw-output '.codenotary.signer // empty' "/tmp/build_config/build.json")"
    fi

    # Set defaults build things
    if ! bashio::var.has_value "$build_from"; then
        bashio::log.error "$build_arch not supported for this build"
        return 1
    fi

    # Read data from image
    if ! bashio::var.has_value "$raw_image"; then
        bashio::log.error "Can't find the image tag on build.json"
        return 1
    fi
    repository="$(echo "$raw_image" | cut -f 1 -d '/')"
    image="$(echo "$raw_image" | cut -f 2 -d '/')"

    # Additional build args
    if bashio::var.has_value "$args"; then
        for arg in $args; do
            value="$(jq --raw-output ".args.$arg" "/tmp/build_config/build.json")"
            docker_cli+=("--build-arg" "$arg=$value")
        done
    fi

    # Additional build labels
    if bashio::var.has_value "$labels"; then
        for label in $labels; do
            value="$(jq --raw-output ".labels.\"$label\"" "/tmp/build_config/build.json")"
            docker_cli+=("--label" "$label=$value")
        done
    fi

    # Start build
    run_build "$TARGET" "$repository" "$image" "$VERSION" \
        "$build_from" "$build_arch" docker_cli[@] docker_tags[@] "${shadow_repository}" \
        "${codenotary_base}" "${codenotary_sign}"
}


function build_machine() {
    local build_machine=$1
    local build_arch=$2

    local args=
    local image=
    local repository=
    local raw_image=
    local build_from=
    local shadow_repository=
    local codenotary_base=
    local codenotary_sign=
    local docker_cli=()
    local docker_tags=()

    # Read build.json
    if bashio::fs.file_exists "/tmp/build_config/build.json"; then
        build_from="$(jq --raw-output ".build_from.${build_arch} // empty" "/tmp/build_config/build.json")"
        args="$(jq --raw-output '.args // empty | keys[]' "/tmp/build_config/build.json")"
        labels="$(jq --raw-output '.labels // empty | keys[]' "/tmp/build_config/build.json")"
        raw_image="$(jq --raw-output '.image // empty' "/tmp/build_config/build.json")"
        shadow_repository="$(jq --raw-output '.shadow_repository // empty' "/tmp/build_config/build.json")"
        codenotary_base="$(jq --raw-output '.codenotary.base_image // empty' "/tmp/build_config/build.json")"
        codenotary_sign="$(jq --raw-output '.codenotary.signer // empty' "/tmp/build_config/build.json")"
    fi

    # Modify build_from
    if [[ "${build_from}" =~ :$ ]]; then
        build_from="${build_from}${VERSION}"
    fi
    bashio::log.info "Use BUILD_FROM: ${build_from}"

    # Change dockerfile
    if bashio::fs.file_exists "${TARGET}/${build_machine}"; then
        docker_cli+=("--file" "${TARGET}/${build_machine}")
    fi

    repository="$(echo "${raw_image}" | cut -f 1 -d '/')"
    image="$(echo "${raw_image}" | cut -f 2 -d '/')"

    # Replace {machine} with build machine for image
    # shellcheck disable=SC1117
    image="$(echo "${image}" | sed -r "s/\{machine\}/${build_machine}/g")"

    # Additional build args
    if bashio::var.has_value "${args}"; then
        for arg in ${args}; do
            value="$(jq --raw-output ".args.${arg}" "/tmp/build_config/build.json")"
            docker_cli+=("--build-arg" "${arg}=${value}")
        done
    fi

    # Additional build labels
    if bashio::var.has_value "${labels}"; then
        for label in ${labels}; do
            value="$(jq --raw-output ".labels.\"${label}\"" "/tmp/build_config/build.json")"
            docker_cli+=("--label" "${label}=${value}")
        done
    fi

    # Set labels
    docker_cli+=("--label" "io.hass.machine=${build_machine}")

    # Start build
    run_build "${TARGET}" "${repository}" "${image}" "${VERSION}" \
        "${build_from}" "${build_arch}" docker_cli[@] docker_tags[@] "${shadow_repository}" \
        "${codenotary_base}" "${codenotary_sign}"
}


function extract_machine_build() {
    local list=$1
    local array=()
    local remove=()

    if [ "$list" != "ALL" ]; then
        IFS="," read -ra array <<<"$list"
        for i in "${!BUILD_MACHINE[@]}"; do
            skip=
            for j in "${array[@]}"; do
                [[ $i == "$j" ]] && { skip=1; break; }
            done
            [[ -n $skip ]] || remove+=("$i")
        done

        for i in "${remove[@]}"; do
            unset "BUILD_MACHINE[$i]"
        done
    fi
}

#### initialized cross-build ####

function init_crosscompile() {
    if [[ "$(uname -m)" != "x86_64" ]]; then
        bashio::log.info "No crossbuild support on host"
        return 0
    fi

    bashio::log.info "Setup crosscompiling feature"
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes \
        > /dev/null 2>&1 || bashio::log.warning "Can't enable crosscompiling feature"
}

#### Security CodeNotary ####

function codenotary_setup() {
    if bashio::var.false "${DOCKER_PUSH}" || bashio::var.is_empty "${CAS_API_KEY+x}"; then
        return 0
    fi

    for j in {1..15}; do
        if cas login > /dev/null 2>&1; then
            return 0
        fi
        sleep $((5 * j))
    done 
        
    bashio::exit.nok "Login to Codenotary fails!"
}

function codenotary_sign() {
    local trust=$1
    local image=$2

    local success=false

    if bashio::var.false "${DOCKER_PUSH}" || bashio::var.is_empty "${CAS_API_KEY+x}"; then
        return 0
    fi
    
    for j in {1..15}; do
        if ! cas authenticate --signerID "${trust}" --silent "docker://${image}"; then
            cas notarize --ci-attr "docker://${image}" || true
        else
            success=true
            break
        fi
        sleep $((5 * j))
    done

    if bashio::var.false "${success}"; then
        bashio::exit.nok "Failed to sign the image"
    fi
    bashio::log.info "Signed ${image} with ${trust}"
}

function codenotary_validate() {
    local trust=$1
    local image=$2
    local pull=$3
    local success=false

    if ! bashio::var.has_value "${trust}"; then
        return 0
    fi

    if bashio::var.true "${pull}"; then
        bashio::log.info "Download image ${image} for CodeNotary validation"
        docker pull "${image}" > /dev/null 2>&1 || bashio::exit.nok "Can't pull image ${image}"
    fi

    for j in {1..15}; do
        # shellcheck disable=SC1007
        if CAS_API_KEY= cas authenticate --signerID "${trust}" --silent "docker://${image}" ; then
            success=true
            break
        fi
        sleep $((5 * j))
    done

    if bashio::var.false "${success}"; then
        bashio::log.warning "Validation of ${image} fails!"
        return 1
    fi
    bashio::log.info "Image ${image} is trusted"
}


#### Error handling ####

function error_handling() {
    stop_docker
    bashio::exit.nok "Abort by User"
}
trap 'error_handling' SIGINT SIGTERM

#### Parse arguments ####

while [[ $# -gt 0 ]]; do
    key=$1
    case $key in
        -h|--help)
            print_help
            ;;
        -r|--repository)
            GIT_REPOSITORY=$2
            shift
            ;;
        -b|--branch)
            GIT_BRANCH=$2
            shift
            ;;
        -t|--target)
            TARGET=$2
            shift
            ;;
        -v|--version)
            VERSION=$2
            shift
            ;;
        --release)
            RELEASE=$2
            shift
            ;;
        -i|--image)
            IMAGE=$2
            shift
            ;;
        --no-latest)
            DOCKER_LATEST=false
            ;;
        --test)
            DOCKER_PUSH=false
            ;;
        --additional-tag)
            ADDITIONAL_TAGS+=("$2")
            shift
            ;;
        --no-cache)
            DOCKER_CACHE=false
            ;;
        --self-cache)
            SELF_CACHE=true
            ;;
        --cache-tag)
            CUSTOM_CACHE_TAG=$2
            shift
            ;;
        --release-tag)
            RELEASE_TAG=true
            ;;
        -d|--docker-hub)
            DOCKER_HUB=$2
            shift
            ;;
        --version-from)
            VERSION_FROM=$2
            shift
            ;;
        --docker-hub-check)
            DOCKER_HUB_CHECK=true
            ;;
        --docker-user)
            DOCKER_USER=$2
            shift
	    ;;
        --docker-password)
            DOCKER_PASSWORD=$2
            shift
	    ;;
        --armhf)
            BUILD_LIST+=("armhf")
            ;;
        --armv7)
            BUILD_LIST+=("armv7")
            ;;
        --amd64)
            BUILD_LIST+=("amd64")
            ;;
        --i386)
            BUILD_LIST+=("i386")
            ;;
        --aarch64)
            BUILD_LIST+=("aarch64")
            ;;
        --all)
            BUILD_LIST=("armhf" "armv7" "amd64" "i386" "aarch64")
            ;;
        --addon)
            BUILD_TYPE="addon"
            ;;
        --base)
            BUILD_TYPE="base"
            SELF_CACHE=true
            VERSION_BASE=$2
            shift
            ;;
        --generic)
            BUILD_TYPE="generic"
            VERSION=$2
            shift
            ;;
        --machine)
            BUILD_TYPE="machine"
            SELF_CACHE=true
            VERSION="$(echo "$2" | cut -d '=' -f 1)"
            extract_machine_build "$(echo "$2" | cut -d '=' -f 2)"
            shift
            ;;
        *)
            bashio::exit.nok "$0 : Argument '$1' unknown"
            ;;
    esac
    shift
done

# Check if an architecture is available
if [[ "${#BUILD_LIST[@]}" -eq 0 && ! "$BUILD_TYPE" == "machine" ]]; then
    bashio::exit.nok "You need select an architecture for build!"
fi


#### Main ####

mkdir -p /data

# Setup docker env
init_crosscompile
start_docker

# Convert configuration files to json if needed
convert_to_json

# Copy configuration files to tmp
copy_config_tmp

# Login into dockerhub & setup CodeNotary
if [ -n "$DOCKER_USER" ] && [ -n "$DOCKER_PASSWORD" ]; then
  docker login -u "$DOCKER_USER" -p "$DOCKER_PASSWORD"
fi
codenotary_setup

# Load external repository
if [ -n "$GIT_REPOSITORY" ]; then
    bashio::log.info "Checkout repository $GIT_REPOSITORY"
    git clone --depth 1 --branch "$GIT_BRANCH" "$GIT_REPOSITORY" /data/git 2> /dev/null
    TARGET="/data/git/$TARGET"
fi

# Select arch build
if [ "${#BUILD_LIST[@]}" -ne 0 ]; then
    bashio::log.info "Run $BUILD_TYPE build for: ${BUILD_LIST[*]}"
    for arch in "${BUILD_LIST[@]}"; do
        if [ "$BUILD_TYPE" == "addon" ]; then
            (build_addon "$arch") &
        elif [ "$BUILD_TYPE" == "generic" ]; then
            (build_generic "$arch") &
        elif [ "$BUILD_TYPE" == "base" ]; then
            (build_base "$arch") &
        elif [[ "$BUILD_TYPE" == "machine" ]]; then
            continue  # Handled in the loop below
        else
            bashio::exit.nok "Invalid build type: $BUILD_TYPE"
        fi
        BUILD_TASKS+=($!)
    done
fi

# Select machine build
if [[ "$BUILD_TYPE" == "machine" ]]; then
    bashio::log.info "Machine builds: ${!BUILD_MACHINE[*]}"
    for machine in "${!BUILD_MACHINE[@]}"; do
        machine_arch="${BUILD_MACHINE["$machine"]}"
        (build_machine "$machine" "$machine_arch") &
        BUILD_TASKS+=($!)
    done
fi

# Wait until all build jobs are done
wait "${BUILD_TASKS[@]}"

# Cleanup docker env
stop_docker

# No Errors
if [ ${#BUILD_ERROR[@]} -eq 0 ]; then
    bashio::exit.ok
fi

bashio::exit.nok "Some build fails: ${BUILD_ERROR[*]}"
