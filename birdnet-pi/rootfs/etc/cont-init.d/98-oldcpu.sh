#!/command/with-contenv bashio
# shellcheck shell=bash disable=SC1091
set -e

##################
# ALLOW RESTARTS #
##################

if [[ "${BASH_SOURCE[0]}" == /etc/cont-init.d/* ]]; then
    mkdir -p /etc/scripts-init
    sed -i "s|/etc/cont-init.d|/etc/scripts-init|g" /ha_entrypoint.sh
    sed -i "/ rm/d" /ha_entrypoint.sh
    cp "${BASH_SOURCE[0]}" /etc/scripts-init/
fi

######################
# INSTALL TENSORFLOW #
######################

# Check if the CPU supports AVX2
if [[ "$(uname -m)" = "x86_64" ]]; then
    if lscpu | grep -q "Flags"; then
        if ! lscpu | grep -q "avx2"; then
            bashio::log.warning "NON SUPPORTED CPU DETECTED"
            bashio::log.warning "Your cpu doesn't support avx2, the analyzer service will likely won't work"
            bashio::log.warning "Trying to install tensorflow instead of tflite_runtime instead. This might take some time (up to 5 minutes)."
            bashio::log.warning "You could try also Birdnet-Go which should supports your cpu"
            source /home/pi/BirdNET-Pi/birdnet/bin/activate
            mkdir -p /home/pi/.cache/pip || true &> /dev/null
            chmod 777 /home/pi/.cache/pip || true &> /dev/null
            pip3 uninstall -y tflite_runtime
            pip install --upgrade packaging==23.2
            pip3 install --upgrade --force-reinstall "https://github.com/snowzach/tensorflow-multiarch/releases/download/v2.16.1/tensorflow-2.16.1-cp311-cp311-linux_x86_64.whl"
            deactivate
        fi
    fi
fi
