ARG BUILD_FROM
ARG BUILD_VERSION
FROM ${BUILD_FROM}
ARG BASHIO_VERSION=0.13.0

RUN \
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
    && sed -i 's/{PGID:-911}/(bashio::config "PGID")/g' /etc/cont-init.d/10-adduser
    #	\
	# Allow custom config folder
    #&& sed -i 's=/config=/config/organizr=g' /etc/cont-init.d/10-adduser \
    #&& sed -i 's=/config=/config/organizr=g' /etc/cont-init.d/20-config \
    #&& sed -i 's=/config=/config/organizr=g' /etc/cont-init.d/30-setup \
    #&& sed -i 's=/config=/config/organizr=g' /etc/cont-init.d/40-install \
    #&& sed -i 's=/config=/config/organizr=g' /etc/logrotate.d/nginx \
    #&& sed -i 's=/config=/config/organizr=g' /etc/logrotate.d/php_ftm7 \
    #&& sed -i 's=/config=/config/organizr=g' /etc/services.d/nginx/run \
    #&& sed -i 's=/config=/config/organizr=g' /etc/services.d/nginx/run \

	
# copy local files
COPY root/ /
