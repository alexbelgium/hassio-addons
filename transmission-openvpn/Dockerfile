ARG BUILD_FROM
# hadolint ignore=DL3006
FROM $BUILD_FROM

RUN curl -J -L -o /tmp/bashio.tar.gz \
        "https://github.com/hassio-addons/bashio/archive/v0.7.1.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf \
        /tmp/bashio.tar.gz \
        --strip 1 -C /tmp/bashio \
    \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -fr /tmp/* 

RUN usermod -d /config-internal abc \
    && sed -i "s|/config|/config-internal|g" /etc/openvpn/adjustConfigs.sh \
    && sed -i "s|/config|/config-internal|g" /etc/openvpn/updateConfigs.sh \
    && sed -i "s|/config|/config-internal|g" /etc/openvpn/start.sh \
    && find /etc/openvpn/*/ -type f -name '*.sh' -exec sed -i "s|/config|/config-internal|g" {} \; \
    && sed -i "s|/config|/config-internal|g" /etc/transmission/updatePort.sh \
    && sed -i "s|/config|/config-internal|g" /etc/transmission/updatePPPort.sh \
    && sed -i "s|/config|/config-internal|g" /etc/transmission/userSetup.sh

# copy local files
COPY root/ /
RUN chmod +x /customstart.sh
CMD ["dumb-init", "/customstart.sh"]