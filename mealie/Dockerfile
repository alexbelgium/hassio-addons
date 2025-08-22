#============================#
#  ALEXBELGIUM'S DOCKERFILE  #
#============================#
#           _.------.
#       _.-`    ('>.-`"""-.
# '.--'`       _'`   _ .--.)
#    -'         '-.-';`   `
#    ' -      _.'  ``'--.
#        '---`    .-'""`
#               /`
#=== Home Assistant Addon ===#

#################
# 1 Build Image #
#################

# Stage 1: Build Frontend with SUB_PATH
FROM node:20 AS frontend-builder

# Set the SUB_PATH environment variable
ARG SUB_PATH="/mealie/"
ENV SUB_PATH=$SUB_PATH

ENV MEALIE_VERSION="v3.1.1"

# Clone the Mealie repository to get the frontend source code
WORKDIR /frontend
# hadolint ignore=DL3003
RUN mkdir -p /frontend/tempdir && cd /frontend/tempdir && \
    git clone --branch "$MEALIE_VERSION" https://github.com/mealie-recipes/mealie.git . && \
    cp -rf frontend/* /frontend && cd /frontend && rm -rf tempdir && \
    yarn install --prefer-offline --frozen-lockfile --non-interactive --production=false --network-timeout 1000000

# Build the frontend
RUN yarn generate

# Stage 2: Build the Final Image
FROM hkotel/mealie:latest

# Copy the rebuilt frontend files into the final image
WORKDIR /mealie
COPY --from=frontend-builder /frontend/dist /mealie/frontend

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Correct data path
# hadolint ignore=DL4006,DL3003
RUN \
    # Copy frontend
    cd /opt/mealie/lib/python*/site-packages/mealie && \
    rm -r frontend && mv /mealie/frontend . && \
    # avoid changing user
    sed -i "s|change_user$|# change_user|g" /app/run.sh && sed -i 's|\${!file_var}|${!file_var:-}|g' /app/run.sh

##################
# 3 Install apps #
##################

# Add rootfs
COPY rootfs/ /

# Uses /bin for compatibility purposes
# hadolint ignore=DL4005
RUN if [ ! -f /bin/sh ] && [ -f /usr/bin/sh ]; then ln -s /usr/bin/sh /bin/sh; fi && \
    if [ ! -f /bin/bash ] && [ -f /usr/bin/bash ]; then ln -s /usr/bin/bash /bin/bash; fi

# Modules
ARG MODULES="00-banner.sh 01-custom_script.sh"

# Automatic modules download
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automodules.sh" "/ha_automodules.sh"
RUN chmod 744 /ha_automodules.sh && /ha_automodules.sh "$MODULES" && rm /ha_automodules.sh

# Manual apps
ENV PACKAGES="nginx"

# Automatic apps & bashio
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_autoapps.sh" "/ha_autoapps.sh"
RUN chmod 744 /ha_autoapps.sh && /ha_autoapps.sh "$PACKAGES" && rm /ha_autoapps.sh

################
# 4 Entrypoint #
################

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Standalone bashio command
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/bashio-standalone.sh" "/.bashio-standalone.sh"
RUN chmod 777 /.bashio-standalone.sh

RUN \
    # Add custom instructions to run.sh on armv7
    sed -i '1d' /app/run.sh \
    && cat /app/run.sh >> /run.txt \
    && cat /run.txt > /app/run.sh \
    && chmod +x /app/run.sh

# Expose necessary ports
EXPOSE 9000

# Set the entrypoint
ENTRYPOINT ["/app/run.sh"]

############
# 5 Labels #
############

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
ENV BUILD_VERSION="${BUILD_VERSION}"
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Add-ons" \
    org.opencontainers.image.authors="alexbelgium (https://github.com/alexbelgium)" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://github.com/alexbelgium" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}

#################
# 6 Healthcheck #
#################

# Use upstream
