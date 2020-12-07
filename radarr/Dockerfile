FROM linuxserver/radarr

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /etc/services.d/radarr/run

VOLUME [ "/data" ]