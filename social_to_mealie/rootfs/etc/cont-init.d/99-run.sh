#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

bashio::log.info "Starting Social to Mealie"
cd /app || bashio::exit.nok "App directory not found"

# On aarch64, native Node.js modules (sharp, @next/swc, etc.) may have been
# incorrectly cross-compiled via Docker BuildKit QEMU emulation, causing
# "Illegal instruction" crashes on real hardware. Rebuild them for the actual
# native architecture.
if [ "$(uname -m)" = "aarch64" ]; then
    bashio::log.info "Ensuring native modules are built for aarch64..."
    npm rebuild 2>&1 || bashio::log.warning "Could not rebuild native modules - the addon may not work correctly on this architecture"
fi

chown nextjs /app/entrypoint.sh
chmod +x /app/entrypoint.sh
exec gosu nextjs /app/entrypoint.sh node --run start
