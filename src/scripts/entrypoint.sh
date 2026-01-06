#!/bin/bash
###############################################################################
# PDF Toolbox Custom Entrypoint
# Wrapper around Stirling PDF's init script that handles:
#   1. Branding setup (copy from template to volume)
#   2. Base64 certificate decoding
#
# Compatible with:
#   - latest-fat image: uses /scripts/init.sh
#   - unified image: uses /entrypoint.sh
###############################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

###############################################################################
# Branding Setup - Copy from template to volume
###############################################################################

setup_branding() {
    # Check if branding template exists (created at build time)
    if [[ ! -d /branding-template/static ]]; then
        echo -e "${YELLOW}[PDF Toolbox] No branding template found, skipping branding setup${NC}"
        return 0
    fi

    echo -e "${CYAN}[PDF Toolbox] Setting up branding from template...${NC}"

    # Stirling PDF V2 expects files in /customFiles/ structure:
    #   /customFiles/static/modern-logo/  - SVG logos
    #   /customFiles/static/classic-logo/ - SVG logos (fallback)
    #   /customFiles/static/custom.css    - Custom CSS
    #   /customFiles/static/favicon.*     - Favicons
    #   /customFiles/translations/        - Custom translations

    # Ensure customFiles directories exist
    mkdir -p /customFiles/static/modern-logo
    mkdir -p /customFiles/static/classic-logo
    mkdir -p /customFiles/translations

    # ALWAYS overwrite branding files from template (like P12 certificate)
    # This ensures branding is always up-to-date with the image

    # Copy static branding files (logos, CSS, favicons)
    if [[ -d /branding-template/static ]]; then
        # Copy modern-logo directory (always overwrite)
        if [[ -d /branding-template/static/modern-logo ]]; then
            cp -r /branding-template/static/modern-logo/* /customFiles/static/modern-logo/ 2>/dev/null || true
            echo -e "${GREEN}[PDF Toolbox] Copied modern-logo files${NC}"
        fi

        # Copy classic-logo directory (always overwrite)
        if [[ -d /branding-template/static/classic-logo ]]; then
            cp -r /branding-template/static/classic-logo/* /customFiles/static/classic-logo/ 2>/dev/null || true
            echo -e "${GREEN}[PDF Toolbox] Copied classic-logo files${NC}"
        fi

        # Copy root static files (favicon, custom.css, etc.) - always overwrite
        for file in /branding-template/static/*; do
            if [[ -f "$file" ]]; then
                filename=$(basename "$file")
                cp "$file" "/customFiles/static/$filename"
                echo -e "${GREEN}[PDF Toolbox] Copied $filename${NC}"
            fi
        done
    fi

    # Copy translations (always overwrite)
    if [[ -d /branding-template/translations ]]; then
        cp -r /branding-template/translations/* /customFiles/translations/ 2>/dev/null || true
        echo -e "${GREEN}[PDF Toolbox] Copied translation files${NC}"
    fi

    # Debug: List what was copied
    echo -e "${CYAN}[PDF Toolbox] Branding files in /customFiles/static/:${NC}"
    ls -la /customFiles/static/ 2>/dev/null | head -20 || true

    # Copy custom_settings.yml to /configs (also in branding-template due to volume mount)
    if [[ -f /branding-template/configs/custom_settings.yml ]]; then
        mkdir -p /configs
        if [[ ! -f /configs/custom_settings.yml ]]; then
            cp /branding-template/configs/custom_settings.yml /configs/custom_settings.yml
            echo -e "${GREEN}[PDF Toolbox] Copied custom_settings.yml to /configs/${NC}"
        else
            echo -e "${YELLOW}[PDF Toolbox] custom_settings.yml already exists, skipping${NC}"
        fi
    fi

    echo -e "${CYAN}[PDF Toolbox] Branding setup complete${NC}"
}

###############################################################################
# Certificate Setup from Base64 Environment Variable
###############################################################################

setup_certificate() {
    local cert_exists=false

    # If Base64 certificate is provided via environment, ALWAYS decode it (allows updates)
    if [[ -n "${KEYSTORE_P12_BASE64:-}" ]]; then
        echo -e "${CYAN}[PDF Toolbox] Setting up signing certificate from environment...${NC}"

        # Ensure configs directory exists
        mkdir -p /configs

        # Decode Base64 to P12 file (always overwrite to allow certificate updates)
        echo "$KEYSTORE_P12_BASE64" | base64 -d > /configs/keystore.p12

        # Set proper permissions (readable by application)
        chmod 644 /configs/keystore.p12

        # Verify the file was created and is valid
        if [[ -f /configs/keystore.p12 ]] && [[ -s /configs/keystore.p12 ]]; then
            echo -e "${GREEN}[PDF Toolbox] Certificate installed at /configs/keystore.p12${NC}"
            cert_exists=true
        else
            echo -e "${YELLOW}[PDF Toolbox] Warning: Failed to create certificate file${NC}"
        fi
    # Otherwise check if certificate already exists (e.g., mounted via volume)
    elif [[ -f /configs/keystore.p12 ]] && [[ -s /configs/keystore.p12 ]]; then
        echo -e "${GREEN}[PDF Toolbox] Certificate found at /configs/keystore.p12 (volume mount)${NC}"
        cert_exists=true
    fi

    # Auto-enable server certificate if cert exists
    if [[ "$cert_exists" == "true" ]]; then
        # Export environment variable for Stirling PDF
        export SYSTEM_SERVERCERTIFICATE_ENABLED=true
        echo -e "${GREEN}[PDF Toolbox] Set SYSTEM_SERVERCERTIFICATE_ENABLED=true${NC}"

        # Also update custom_settings.yml if it exists (YAML config may override env vars)
        local settings_file="/configs/custom_settings.yml"
        if [[ -f "$settings_file" ]]; then
            # Update serverCertificate.enabled to true
            # The structure is:
            #   serverCertificate:
            #     enabled: false
            if grep -q "serverCertificate:" "$settings_file"; then
                # Use sed to change 'enabled: false' to 'enabled: true' after serverCertificate:
                # This matches lines with 'enabled: false' that follow serverCertificate:
                sed -i '/serverCertificate:/,/^[a-zA-Z]/ s/^\([[:space:]]*enabled:[[:space:]]*\)false/\1true/' "$settings_file"
                echo -e "${GREEN}[PDF Toolbox] Updated custom_settings.yml: serverCertificate.enabled=true${NC}"
            fi
        fi
    fi
}

###############################################################################
# Main
###############################################################################

# Setup branding from template (if exists)
setup_branding

# Setup certificate from Base64 if provided
setup_certificate

# Determine which original entrypoint to use
# latest-fat image uses /scripts/init.sh
# unified image uses /entrypoint.sh (renamed to /entrypoint-original.sh)
if [[ -x /scripts/init.sh ]]; then
    exec /scripts/init.sh "$@"
elif [[ -x /entrypoint-original.sh ]]; then
    exec /entrypoint-original.sh "$@"
else
    echo -e "${YELLOW}[PDF Toolbox] Warning: No original entrypoint found, starting Java directly${NC}"
    exec java -jar /app.jar "$@"
fi
