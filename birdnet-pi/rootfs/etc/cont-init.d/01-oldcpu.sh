#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Compensate for old cpu without avx2
if lscpu | grep -q avx2; then
    bashio::log.warning "NON SUPPORTED CPU DETECTED"
    bashio::log.warning "Your cpu doesn't support avx2, the analyzer service will likely won't work"
    bashio::log.warning "Trying to install tensorflow instead of tflite_runtime instead"
    $PYTHON_VIRTUAL_ENV pip3 uninstall -y tflite_runtime
    $PYTHON_VIRTUAL_ENV pip3 install tensorflow
fi
