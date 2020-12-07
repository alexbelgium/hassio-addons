FROM linuxserver/transmission

# MOFIFY DATA PATH
RUN sed -i "s|config|data|g" /etc/services.d/transmission/run

VOLUME [ "/data" ]