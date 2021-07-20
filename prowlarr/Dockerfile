ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="nightly-0.1.0.701-ls80"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}
ARG BASHIO_VERSION=0.13.0

RUN \
    ################
    # Install apps #
    ################
    apt-get update \
    && apt-get install -y \
        jq \
        curl \
        cifs-utils \
        keyutils \
    \ 
    ###################
    # Install bashio #
    ##################
    && mkdir -p /tmp/bashio \
    && curl -L -f -s "https://github.com/hassio-addons/bashio/archive/v${BASHIO_VERSION}.tar.gz" \
    | tar -xzf - --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio \
    \
    ########################################
    # Correct upstream image folders links #
    ########################################
    \
    # Allow UID and GID setting
    && sed -i 's/bash/bashio/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PUID:-911}/(bashio::config "PUID")/g' /etc/cont-init.d/10-adduser \
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser \
	\
    # Correct permissions 
    && sed -i 's|/config|-R /config/prowlarr|g' /etc/cont-init.d/10-adduser \    
    && sed -i 's=	/config=/config/prowlarr || true=g' /etc/cont-init.d/30-config \
    && sed -i 's|/config|/config/prowlarr|g' /etc/services.d/prowlarr/run
	
# copy local files
COPY root/ /
