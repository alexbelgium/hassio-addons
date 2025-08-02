#!/usr/bin/with-contenv bashio
# Example validated initialization script
# This demonstrates how to use the input validation library
set -euo pipefail

# Source the validation library
source /ha_input_validation.sh

bashio::log.info "🔍 Starting configuration validation..."

##################################
# VALIDATE COMMON CONFIGURATIONS #
##################################

# Use the common validation function
validate_common_config

##################################
# VALIDATE APPLICATION-SPECIFIC  #
##################################

# Example for a media server add-on like Plex/Emby
if [[ "${ADDON_TYPE:-media}" == "media" ]]; then
    # Validate transcoding quality settings
    if bashio::config.has_value "transcoding_quality"; then
        validate_string "transcoding_quality" "^(low|medium|high|ultra)$" "Transcoding quality (low, medium, high, ultra)" false
    fi
    
    # Validate maximum concurrent streams
    if bashio::config.has_value "max_streams"; then
        validate_numeric "max_streams" 1 20 "Maximum concurrent streams (1-20)" false
    fi
fi

# Example for a file management add-on like Filebrowser
if [[ "${ADDON_TYPE:-file}" == "file" ]]; then
    # Validate base folder (prevent directory traversal)
    if bashio::config.has_value "base_folder"; then
        validate_path "base_folder" "/config" "Base folder for file browsing" false
    fi
    
    # Validate disable thumbnails setting
    if bashio::config.has_value "disable_thumbnails"; then
        validate_boolean "disable_thumbnails" "Disable thumbnail generation" false
    fi
fi

# Example for a network tool add-on like Arpspoof
if [[ "${ADDON_TYPE:-network}" == "network" ]]; then
    # Validate target IP addresses
    if bashio::config.has_value "target_ip"; then
        validate_ip "target_ip" "Target device IP address"
    fi
    
    # Validate gateway IP
    if bashio::config.has_value "gateway_ip"; then
        validate_ip "gateway_ip" "Network gateway IP address"
    fi
    
    # Validate block duration
    if bashio::config.has_value "block_duration"; then
        validate_numeric "block_duration" 1 3600 "Block duration in seconds (1-3600)"
    fi
fi

##################################
# VALIDATE SECURITY SETTINGS     #
##################################

# Validate authentication settings
if bashio::config.has_value "enable_auth"; then
    validate_boolean "enable_auth" "Enable authentication"
    
    if bashio::config.true "enable_auth"; then
        # If auth is enabled, validate credentials
        validate_string "username" "^[a-zA-Z0-9_-]{3,20}$" "Username (3-20 alphanumeric characters)"
        
        # Validate password strength
        if bashio::config.has_value "password"; then
            local password
            password=$(bashio::config "password")
            
            if [[ ${#password} -lt 8 ]]; then
                bashio::log.fatal "Password too short. Minimum 8 characters required."
                exit 1
            fi
            
            if [[ ! "$password" =~ [A-Z] ]] || [[ ! "$password" =~ [a-z] ]] || [[ ! "$password" =~ [0-9] ]]; then
                bashio::log.warning "⚠️  Weak password detected. Consider using uppercase, lowercase, and numbers."
            fi
            
            bashio::log.debug "✅ Validated password strength"
        fi
    fi
fi

##################################
# FINALIZATION                   #
##################################

bashio::log.info "🎉 Configuration validation completed successfully!"
bashio::log.info "Starting application with validated configuration..."

# At this point, all configuration values have been validated
# and the application can start safely with trusted inputs

# Export validated configurations as environment variables for the application
export VALIDATED_CONFIG="true"
export CONFIG_VALIDATION_TIME="$(date -Iseconds)"

bashio::log.debug "Environment prepared with validated configuration"