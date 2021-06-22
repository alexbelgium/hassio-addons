ARG BUILD_FROM
ARG BUILD_VERSION
ARG BUILD_UPSTREAM="v1.5.0.13"
FROM ${BUILD_FROM}${BUILD_UPSTREAM}
ARG BASHIO_VERSION=0.13.0

RUN \
    ################
    # Install apps #
    ################
    apk add --no-cache \
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
    && sed -i 's|/config|-R /config/diskover|g' /etc/cont-init.d/10-adduser \    
    && sed -i 's=	/config=/config/diskover || true=g' /etc/cont-init.d/50-diskover-config \
    && sed -i 's=	/config=/config/diskover || true=g' /etc/cont-init.d/60-diskover-web-config
	
# copy local files
COPY root/ /
