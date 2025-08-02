#!/bin/bash
# Secure script downloader with integrity verification
set -euo pipefail

##################################
# Secure Template Script Download #
##################################

# Function to securely download and verify scripts
secure_download() {
    local url="$1"
    local output_file="$2"
    local expected_sha256="$3"
    
    echo "🔒 Securely downloading: $(basename "$output_file")"
    
    # Download with retry logic
    local retries=3
    local retry_delay=2
    
    for i in $(seq 1 $retries); do
        if curl -fsSL --retry 3 --retry-delay 1 --connect-timeout 10 --max-time 30 "$url" -o "$output_file"; then
            break
        elif [ $i -eq $retries ]; then
            echo "❌ Failed to download after $retries attempts: $url" >&2
            return 1
        else
            echo "⚠️  Download attempt $i failed, retrying in ${retry_delay}s..." >&2
            sleep $retry_delay
        fi
    done
    
    # Verify SHA256 checksum if provided
    if [ -n "$expected_sha256" ]; then
        echo "🔍 Verifying integrity..."
        local actual_sha256
        actual_sha256=$(sha256sum "$output_file" | cut -d' ' -f1)
        
        if [ "$actual_sha256" = "$expected_sha256" ]; then
            echo "✅ Integrity verification passed"
        else
            echo "❌ INTEGRITY VERIFICATION FAILED!" >&2
            echo "Expected: $expected_sha256" >&2
            echo "Actual:   $actual_sha256" >&2
            rm -f "$output_file"
            return 1
        fi
    else
        echo "⚠️  No checksum provided - skipping integrity verification"
    fi
    
    # Set secure permissions
    chmod 755 "$output_file"
    echo "🔧 Set secure permissions (755)"
}

# Function to install common dependencies securely
install_dependencies() {
    echo "📦 Installing secure dependencies..."
    
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

# Main execution if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🛡️  Home Assistant Secure Script Downloader"
    echo "This script provides secure download functions for HA add-ons"
    echo ""
    echo "Usage:"
    echo "  source $0"
    echo "  secure_download <url> <output_file> <sha256_hash>"
    echo ""
    echo "Example:"
    echo "  secure_download 'https://example.com/script.sh' '/tmp/script.sh' 'abc123...'"
fi