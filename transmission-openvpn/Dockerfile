FROM haugene/transmission-openvpn:2.7

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
CMD ["dumb-init", "/customstart.sh"]