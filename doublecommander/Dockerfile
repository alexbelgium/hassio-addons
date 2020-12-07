FROM linuxserver/doublecommander

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /etc/services.d/doublecommander/run

VOLUME [ "/data" ]