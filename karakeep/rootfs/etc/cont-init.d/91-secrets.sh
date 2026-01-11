#!/command/with-contenv bashio
# shellcheck shell=bash
set -e

generate_secret() {
  tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 64
}

set_option() {
  local key="$1"
  local value="$2"

  # Store permanently in Home Assistant add-on options
  bashio::addon.option "${key}" "${value}"

  # Export into current process
  export "${key}=${value}"

  # Export into s6 so all services inherit it
  if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "${value}" > "/var/run/s6/container_environment/${key}"
  fi
}

load_option() {
  local key="$1"
  local value

  value="$(bashio::config "${key}")"
  export "${key}=${value}"

  if [ -d /var/run/s6/container_environment ]; then
    printf "%s" "${value}" > "/var/run/s6/container_environment/${key}"
  fi
}

for key in MEILI_MASTER_KEY NEXTAUTH_SECRET; do
  if bashio::config.has_value "${key}"; then
    bashio::log.info "Using existing ${key}"
    load_option "${key}"
  else
    bashio::log.warning "${key} not set, generating persistent secret"
    value="$(generate_secret)"
    set_option "${key}" "${value}"
  fi
done
