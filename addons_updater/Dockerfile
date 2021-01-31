ARG BUILD_FROM
FROM $BUILD_FROM

VOLUME [ "/data" ]

#Install last version https://github.com/dvershinin/lastversion
RUN \
    apk add --no-cache git \
    && pip install --upgrade pip \
    && pip install lastversion

# Copy script
COPY run.sh /
RUN chmod a+x /run.sh
CMD [ "/run.sh"] 

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
