#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Check if the CPU supports AVX2
if [[ "$(uname -m)" = "x86_64" ]]; then
  if lscpu | grep -q "Flags"; then
    if ! lscpu | grep -q "avx2"; then
        bashio::log.warning "NON SUPPORTED CPU DETECTED"
        bashio::log.warning "Your cpu doesn't support avx2, the analyzer service will likely won't work"
        bashio::log.warning "Trying to install tensorflow instead of tflite_runtime instead"
        mkdir -p /home/pi/.cache/pip
        chown "0:0" /home/pi/.cache/pip
        $PYTHON_VIRTUAL_ENV /usr/bin/pip3 uninstall -y tflite_runtime
        $PYTHON_VIRTUAL_ENV /usr/bin/pip3 install tensorflow
        chown "$PUID:$PGID" /home/pi/.cache/pip
    fi
  fi
fi
