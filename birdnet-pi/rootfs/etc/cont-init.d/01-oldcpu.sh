#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Compensate for old cpu without avx2
if [[ "$(uname -m)" = "x86_64" && lscpu | grep -q "Flags" && ! lscpu | grep -q "avx2" ]]; then
    bashio::log.warning "NON SUPPORTED CPU DETECTED"
    bashio::log.warning "Your cpu doesn't support avx2, the analyzer service will likely won't work"
    bashio::log.warning "Trying to install tensorflow instead of tflite_runtime instead"
    $PYTHON_VIRTUAL_ENV /usr/bin/pip3 uninstall -y tflite_runtime
    $PYTHON_VIRTUAL_ENV /usr/bin/pip3 install tensorflow
fi
