FROM linuxserver/znc:znc-1.7.3-ls14

# use /data instead of /config for hass.io environment
RUN sed -i "s|/config|/config/znc|g" /etc/services.d/znc/run \
    && sed -i "s|/config|/config/znc|g" /etc/cont-init.d/20-config \
    && sed -i "s|/config/znc/config/zncs|/config/znc/configs|g" /etc/cont-init.d/20-config

# copy local files
COPY root/ /