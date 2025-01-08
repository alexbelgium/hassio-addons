#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

# Check if the CPU supports AVX2
if [[ "$(uname -m)" = "x86_64" ]]; then
    # Get the CPU flags
    cpu_flags=$(lscpu | grep "Flags" | awk '{print $2}')
    
    # Check if avx2 is NOT present in the flags
    if [[ ! "$cpu_flags" =~ "avx2" ]]; then
        bashio::log.warning "NON SUPPORTED CPU DETECTED"
        bashio::log.warning "Your CPU doesn't support AVX2, the analyzer service likely won't work."
        bashio::log.warning "Trying to install tensorflow instead of tflite_runtime."

        # Uninstall tflite_runtime and install tensorflow
        $PYTHON_VIRTUAL_ENV /usr/bin/pip3 uninstall -y tflite_runtime
        $PYTHON_VIRTUAL_ENV /usr/bin/pip3 install tensorflow
    fi
fi
