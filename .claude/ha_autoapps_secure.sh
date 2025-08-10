#!/bin/bash
# Secure version of automatic apps download
set -euo pipefail

##############################
# Automatic apps download #
# SECURE VERSION            #
##############################

PACKAGES="$1"
echo "📦 Installing packages securely: $PACKAGES"

# Install dependencies securely
install_dependencies() {
    echo "🔧 Installing required dependencies..."

    # Install bash if needed
    if ! command -v bash > /dev/null 2>&1; then
        (apt-get update && apt-get install -yqq --no-install-recommends bash || apk add --no-cache bash) > /dev/null
    fi

    # Install curl if needed
    if ! command -v curl > /dev/null 2>&1; then
        (apt-get update && apt-get install -yqq --no-install-recommends curl || apk add --no-cache curl) > /dev/null
    fi

    # Install ca-certificates for SSL verification
    (apt-get update && apt-get install -yqq --no-install-recommends ca-certificates || apk add --no-cache ca-certificates) > /dev/null 2>&1 || true
}

# Secure download function
secure_download() {
    local url="$1"
    local output_file="$2"
    local expected_sha256="${3:-}"

    echo "🔒 Downloading: $(basename "$output_file")"

    # Download with security headers and timeouts
    if ! curl -fsSL \
        --retry 3 \
        --retry-delay 2 \
        --connect-timeout 10 \
        --max-time 60 \
        --user-agent "HomeAssistant-AddOn/1.0" \
        --header "Accept: application/octet-stream" \
        "$url" -o "$output_file"; then
        echo "❌ Failed to download: $url" >&2
        return 1
    fi

    # Verify checksum if provided
    if [ -n "$expected_sha256" ]; then
        local actual_sha256
        actual_sha256=$(sha256sum "$output_file" | cut -d' ' -f1)

        if [ "$actual_sha256" != "$expected_sha256" ]; then
            echo "❌ Checksum verification failed for $output_file" >&2
            echo "Expected: $expected_sha256" >&2
            echo "Actual:   $actual_sha256" >&2
            rm -f "$output_file"
            return 1
        fi
        echo "✅ Checksum verified"
    else
        echo "⚠️  No checksum provided - consider adding one for security"
    fi

    # Set secure permissions
    chmod 755 "$output_file"
}

# Main execution
main() {
    echo "🛡️  Starting secure package installation..."

    # Install dependencies
    install_dependencies

    # For now, we'll download without checksum but with secure practices
    # TODO: Add checksums for ha_automatic_packages.sh in future releases
    echo "📥 Downloading package installer..."

    local script_url="https://raw.githubusercontent.com/alexbelgium/hassio-addons/master/.templates/ha_automatic_packages.sh"
    local script_file="/ha_automatic_packages.sh"

    # Download securely (without checksum for now - to be added)
    if secure_download "$script_url" "$script_file" ""; then
        echo "🏃 Executing package installer..."

        # Execute with error handling
        if bash "$script_file" "${PACKAGES:-}"; then
            echo "✅ Package installation completed successfully"
        else
            echo "❌ Package installation failed" >&2
            exit 1
        fi

        # Clean up
        rm -f "$script_file"
        echo "🧹 Cleanup completed"
    else
        echo "❌ Failed to download package installer" >&2
        exit 1
    fi
}

# Execute main function
main "$@"
