#!/usr/bin/with-contenv bashio
# Input Validation Library for Home Assistant Add-ons
# Provides secure validation functions for user inputs
set -euo pipefail

##################################
# CONFIGURATION INPUT VALIDATION #
##################################

# Function to validate string input with pattern
validate_string() {
    local config_key="$1"
    local pattern="$2"
    local description="$3"
    local required="${4:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            bashio::log.fatal "Expected: $description"
            exit 1
        else
            return 0  # Optional field not provided
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    if [[ ! $value =~ $pattern ]]; then
        bashio::log.fatal "Invalid format for '$config_key': '$value'"
        bashio::log.fatal "Expected: $description"
        bashio::log.fatal "Pattern: $pattern"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated $config_key: $value"
}

# Function to validate numeric input with bounds
validate_numeric() {
    local config_key="$1"
    local min_val="$2"
    local max_val="$3"
    local description="$4"
    local required="${5:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            exit 1
        else
            return 0
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    # Check if it's a valid number
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        bashio::log.fatal "Invalid numeric value for '$config_key': '$value'"
        bashio::log.fatal "Expected: $description"
        exit 1
    fi
    
    # Check bounds
    if [[ $value -lt $min_val ]] || [[ $value -gt $max_val ]]; then
        bashio::log.fatal "Value for '$config_key' out of range: $value"
        bashio::log.fatal "Expected: $description (range: $min_val-$max_val)"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated $config_key: $value"
}

# Function to validate boolean input
validate_boolean() {
    local config_key="$1"
    local description="$2"
    local required="${3:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            exit 1
        else
            return 0
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    if [[ ! "$value" =~ ^(true|false)$ ]]; then
        bashio::log.fatal "Invalid boolean value for '$config_key': '$value'"
        bashio::log.fatal "Expected: $description (true or false)"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated $config_key: $value"
}

# Function to validate file path (prevent directory traversal)
validate_path() {
    local config_key="$1"
    local base_path="$2"
    local description="$3"
    local required="${4:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            exit 1
        else
            return 0
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    # Check for directory traversal attempts
    if [[ "$value" =~ \.\. ]] || [[ "$value" =~ ^/ ]]; then
        bashio::log.fatal "Invalid path for '$config_key': '$value'"
        bashio::log.fatal "Path contains directory traversal or is absolute"
        bashio::log.fatal "Expected: $description"
        exit 1
    fi
    
    # Normalize path and check if it's within base path
    local full_path="$base_path/$value"
    local real_path
    real_path=$(realpath -m "$full_path" 2>/dev/null || echo "$full_path")
    local real_base
    real_base=$(realpath -m "$base_path")
    
    if [[ ! "$real_path" =~ ^"$real_base" ]]; then
        bashio::log.fatal "Path '$config_key' outside allowed base: '$value'"
        bashio::log.fatal "Expected: $description"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated path $config_key: $value"
}

# Function to validate URL
validate_url() {
    local config_key="$1"
    local allowed_schemes="$2"  # e.g., "http|https"
    local description="$3"
    local required="${4:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            exit 1
        else
            return 0
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    # Basic URL validation
    local url_pattern="^($allowed_schemes)://[A-Za-z0-9.-]+(:[0-9]+)?(/.*)?$"
    
    if [[ ! "$value" =~ $url_pattern ]]; then
        bashio::log.fatal "Invalid URL for '$config_key': '$value'"
        bashio::log.fatal "Expected: $description"
        bashio::log.fatal "Allowed schemes: $allowed_schemes"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated URL $config_key: $value"
}

# Function to validate IP address
validate_ip() {
    local config_key="$1"
    local description="$2"
    local required="${3:-true}"
    
    if ! bashio::config.has_value "$config_key"; then
        if [[ "$required" == "true" ]]; then
            bashio::log.fatal "Required configuration '$config_key' not found"
            exit 1
        else
            return 0
        fi
    fi
    
    local value
    value=$(bashio::config "$config_key")
    
    # IPv4 validation
    local ipv4_pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ "$value" =~ $ipv4_pattern ]]; then
        # Validate each octet is 0-255
        IFS='.' read -ra octets <<< "$value"
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                bashio::log.fatal "Invalid IP address for '$config_key': '$value'"
                bashio::log.fatal "Expected: $description"
                exit 1
            fi
        done
    else
        bashio::log.fatal "Invalid IP address format for '$config_key': '$value'"
        bashio::log.fatal "Expected: $description"
        exit 1
    fi
    
    bashio::log.debug "✅ Validated IP $config_key: $value"
}

# Function to validate common add-on configurations
validate_common_config() {
    bashio::log.info "🔍 Validating common configuration parameters..."
    
    # Validate SSL configuration if present
    if bashio::config.has_value "ssl"; then
        validate_boolean "ssl" "Enable/disable SSL"
        
        if bashio::config.true "ssl"; then
            validate_string "certfile" "^[a-zA-Z0-9._-]+\.pem$" "SSL certificate filename" true
            validate_string "keyfile" "^[a-zA-Z0-9._-]+\.pem$" "SSL private key filename" true
        fi
    fi
    
    # Validate user/group IDs if present
    if bashio::config.has_value "PUID"; then
        validate_numeric "PUID" 0 65535 "User ID (0-65535)"
    fi
    
    if bashio::config.has_value "PGID"; then
        validate_numeric "PGID" 0 65535 "Group ID (0-65535)"
    fi
    
    # Validate timezone if present
    if bashio::config.has_value "TZ"; then
        validate_string "TZ" "^[A-Za-z0-9/_+-]+$" "Timezone (e.g., Europe/London)" false
    fi
    
    bashio::log.info "✅ Common configuration validation completed"
}

# If script is called directly, show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    bashio::log.info "🛡️  Home Assistant Input Validation Library"
    bashio::log.info "This library provides secure validation functions for add-on configurations"
    echo ""
    bashio::log.info "Usage: source /ha_input_validation.sh"
fi