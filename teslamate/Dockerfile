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
FROM ${BUILD_FROM}

##################
# 2 Finalize     #
##################

# Add rootfs (for S6 overlay and run.sh)
COPY rootfs/ /

# Volumes
VOLUME ["/data", "/config"]

# Healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD wget -q --no-check-certificate --spider http://127.0.0.1:4000/ || exit 1

# Labels
LABEL \
    io.hass.name="TeslaMate" \
    io.hass.description="A powerful data logger for Tesla vehicles" \
    io.hass.type="addon" \
    maintainer="alexbelgium" \
    url="https://github.com/bruvv/hassio-addons"

# Environment
ENV \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    LANG=C.UTF-8 \
    TERM=xterm-256color

# Ports
EXPOSE 4000/tcp

# Entrypoint for S6 overlay
ENTRYPOINT ["/init"]

CMD ["/usr/bin/run.sh"]
