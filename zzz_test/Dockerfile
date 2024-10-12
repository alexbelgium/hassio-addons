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

ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM} AS base-addon

##################
# 2 Modify Image #
##################

# Set S6 wait time
ENV S6_CMD_WAIT_FOR_SERVICES=1 \
    S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0 \
    S6_SERVICES_GRACETIME=0

# Correct data path
# hadolint ignore=DL4006
RUN grep -rl "/app/data" /app | xargs sed -i 's|/app/data|/config/addons_config/mealie_data|g' && \
    sed -i "s|change_user$|# change_user|g" /app/run.sh

##################
# 3 Install Apps #
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

###############################################
# 4 Integrate Mealie Dockerfile - Frontend Build
###############################################

# Define build arguments for SUB_PATH
ARG SUB_PATH=/hllo/
ENV SUB_PATH=${SUB_PATH}

# Frontend Builder Stage
FROM node:16 AS mealie-frontend-builder

WORKDIR /app/frontend

# Copy frontend source code
COPY ./frontend .

# Install dependencies
RUN yarn install \
    --prefer-offline \
    --frozen-lockfile \
    --non-interactive \
    --production=false \
    --network-timeout 1000000

# Pass SUB_PATH to the build environment
ENV SUB_PATH=${SUB_PATH}

# Build the frontend
RUN yarn generate

###############################################
# 5 Integrate Mealie Dockerfile - Python Base and Dependencies
###############################################

FROM python:3.10-slim AS mealie-python-base

ENV MEALIE_HOME="/app"

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

# Prepend poetry and venv to PATH
ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

# Create user account
RUN useradd -u 911 -U -d $MEALIE_HOME -s /bin/bash abc \
    && usermod -G users abc \
    && mkdir $MEALIE_HOME

# Builder Base Image
FROM mealie-python-base AS mealie-builder-base

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential \
        libpq-dev \
        libwebp-dev \
        # LDAP Dependencies
        libsasl2-dev libldap2-dev libssl-dev \
        gnupg gnupg2 gnupg1 \
    && rm -rf /var/lib/apt/lists/* \
    && pip install -U --no-cache-dir pip

# Install Poetry
ENV POETRY_VERSION=1.3.1
RUN curl -sSL https://install.python-poetry.org | python3 -

# Copy project requirement files
WORKDIR $PYSETUP_PATH
COPY ./poetry.lock ./pyproject.toml ./

# Install runtime dependencies
RUN poetry install -E pgsql --only main

# CRFPP Image (Assuming it's needed)
FROM hkotel/crfpp AS crfpp

RUN echo "crfpp-container"

# Production Image
FROM mealie-python-base AS mealie-production

LABEL org.opencontainers.image.source="https://github.com/mealie-recipes/mealie"

ENV PRODUCTION=true
ENV TESTING=false

ARG COMMIT
ENV GIT_COMMIT_HASH=${COMMIT}

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        gosu \
        iproute2 \
        libldap-common \
        libldap-2.5 \
    && rm -rf /var/lib/apt/lists/*

# Create directory for Docker Secrets
RUN mkdir -p /run/secrets

# Copy Poetry and virtual environment from builder-base
COPY --from=mealie-builder-base $POETRY_HOME $POETRY_HOME
COPY --from=mealie-builder-base $PYSETUP_PATH $PYSETUP_PATH

ENV LD_LIBRARY_PATH=/usr/local/lib

# Copy CRF++ binaries
COPY --from=crfpp /usr/local/lib/ /usr/local/lib
COPY --from=crfpp /usr/local/bin/crf_learn /usr/local/bin/crf_learn
COPY --from=crfpp /usr/local/bin/crf_test /usr/local/bin/crf_test

# Copy backend application
COPY ./mealie $MEALIE_HOME/mealie
COPY ./poetry.lock ./pyproject.toml $MEALIE_HOME/

# Alembic migrations
COPY ./alembic $MEALIE_HOME/alembic
COPY ./alembic.ini $MEALIE_HOME/

# Install Python runtime dependencies
WORKDIR $MEALIE_HOME
RUN . $VENV_PATH/bin/activate && poetry install -E pgsql --only main
WORKDIR /

# Install CRF++ Models
RUN python $MEALIE_HOME/mealie/scripts/install_model.py

# Define volumes and environment variables
VOLUME [ "$MEALIE_HOME/data/" ]
ENV APP_PORT=9000

EXPOSE ${APP_PORT}

# Healthcheck
HEALTHCHECK CMD python $MEALIE_HOME/mealie/scripts/healthcheck.py || exit 1

# ----------------------------------
# 6 Integrate Mealie Dockerfile - Copy Frontend

ENV STATIC_FILES=/spa/static
COPY --from=mealie-frontend-builder /app/frontend/dist ${STATIC_FILES}

ENV HOST=0.0.0.0

EXPOSE ${APP_PORT}

# ----------------------------------
# 7 Entrypoint and Scripts

# Add entrypoint
ENV S6_STAGE2_HOOK=/ha_entrypoint.sh
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint.sh" "/ha_entrypoint.sh"

# Entrypoint modifications
ADD "https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_entrypoint_modif.sh" "/ha_entrypoint_modif.sh"
RUN chmod 777 /ha_entrypoint.sh /ha_entrypoint_modif.sh && /ha_entrypoint_modif.sh && rm /ha_entrypoint_modif.sh

# Modify run.sh for ARMv7
RUN \
    # Add custom instructions to run.sh on armv7
    sed -i '1d' /app/run.sh \
    && cat /app/run.sh >> /run.txt \
    && cat /run.txt > /app/run.sh \
    && chmod +x /app/run.sh

# Copy and set entrypoint script
COPY ./docker/entry.sh $MEALIE_HOME/run.sh

RUN chmod +x $MEALIE_HOME/run.sh
ENTRYPOINT ["/app/run.sh"]

############
# 8 Labels #
############

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION
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
# 9 Healthcheck #
#################

# Assuming healthcheck is already defined in Mealie Production Stage
# If additional healthchecks are needed, add them here.
