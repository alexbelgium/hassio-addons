ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install requirements for add-on
RUN \
    apk add --no-cache \
    python3 \
    py3-pip \
    git

# Clone the TeslaMate ABRP repository
RUN git clone https://github.com/fetzu/teslamate-abrp /app

WORKDIR /app

# Install Python requirements
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy root filesystem
COPY rootfs /

# Set proper permissions
RUN chmod a+x /usr/bin/teslamate-abrp.py

ENTRYPOINT ["/usr/bin/teslamate-abrp.py"]
