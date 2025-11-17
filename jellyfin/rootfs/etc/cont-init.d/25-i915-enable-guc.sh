#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
set -e

if ! bashio::config.has_value 'i915_enable_guc'; then
    exit 0
fi

GUC_VALUE=$(bashio::config 'i915_enable_guc')

if [[ "${GUC_VALUE}" = "null" ]]; then
    exit 0
fi

if [[ ${GUC_VALUE} -lt 0 || ${GUC_VALUE} -gt 3 ]]; then
    bashio::log.warning "Invalid i915_enable_guc value '${GUC_VALUE}'. Expected a value between 0 and 3. Skipping configuration."
    exit 0
fi

PARAM_PATH="/sys/module/i915/parameters/enable_guc"

if [ ! -e "${PARAM_PATH}" ]; then
    bashio::log.warning "i915 module parameter not found at ${PARAM_PATH}. The add-on cannot enable GuC unless the host kernel exposes this path."
    exit 0
fi

if [ ! -w "${PARAM_PATH}" ]; then
    bashio::log.warning "Missing permission to change ${PARAM_PATH}. Try enabling privileged mode or ensure the host allows changing the parameter."
    exit 0
fi

if echo "${GUC_VALUE}" > "${PARAM_PATH}"; then
    bashio::log.info "Set i915 enable_guc to ${GUC_VALUE}."
else
    bashio::log.warning "Failed to set i915 enable_guc to ${GUC_VALUE}."
fi
