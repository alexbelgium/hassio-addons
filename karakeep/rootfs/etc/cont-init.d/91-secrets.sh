#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

generate_secret() {
  tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64
}

set_option() {
  local key="$1"
  local value="$2"

  bashio::addon.option "${key}" "${value}"
  export "${key}=${value}"

  if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "${value}" > "/var/run/s6/container_environment/${key}"
  fi
}

for key in MEILI_MASTER_KEY NEXTAUTH_SECRET; do
  if bashio::config.has_value "${key}"; then
    value="$(bashio::config "${key}")"
    export "${key}=${value}"
    if [ -d /var/run/s6/container_environment ]; then
      printf "%s" "${value}" > "/var/run/s6/container_environment/${key}"
    fi
  else
    bashio::log.warning "${key} is not set. Generating a new value and storing it in addon options."
    value="$(generate_secret)"
    set_option "${key}" "${value}"
  fi
done
