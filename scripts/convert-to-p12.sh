#!/bin/bash
###############################################################################
# Convert PEM Certificate to P12 Format
# Converts CA-signed PEM certificate + key to P12 format for Stirling PDF
# Automatically updates .env with Base64-encoded certificate
#
# Usage:
#   ./scripts/convert-to-p12.sh              # Auto-detect in certs/
#   ./scripts/convert-to-p12.sh cert.crt     # Specify certificate file
###############################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$PROJECT_DIR/certs"
ENV_FILE="$PROJECT_DIR/.env"
OUTPUT_NAME="cert"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} PEM to P12 Certificate Converter${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed or not in PATH${NC}"
    exit 1
fi

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

###############################################################################
# Auto-detect certificates in certs/
###############################################################################

auto_detect_certs() {
    local crt_files=()
    local key_files=()

    # Find certificate files
    while IFS= read -r -d '' file; do
        crt_files+=("$file")
    done < <(find "$CERT_DIR" -maxdepth 1 \( -name "*.crt" -o -name "*.pem" -o -name "*.cer" \) -type f -print0 2>/dev/null || true)

    # Find key files
    while IFS= read -r -d '' file; do
        key_files+=("$file")
    done < <(find "$CERT_DIR" -maxdepth 1 -name "*.key" -type f -print0 2>/dev/null || true)

    # Return results
    echo "${#crt_files[@]}:${#key_files[@]}"
}

select_file() {
    local prompt="$1"
    shift
    local files=("$@")

    if [[ ${#files[@]} -eq 0 ]]; then
        return 1
    elif [[ ${#files[@]} -eq 1 ]]; then
        echo "${files[0]}"
        return 0
    else
        echo -e "${CYAN}Multiple files found:${NC}" >&2
        local i=1
        for f in "${files[@]}"; do
            echo "  $i) $(basename "$f")" >&2
            ((i++))
        done
        read -p "$prompt [1-${#files[@]}]: " choice >&2
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#files[@]} ]]; then
            echo "${files[$((choice-1))]}"
            return 0
        else
            return 1
        fi
    fi
}

###############################################################################
# Main Logic
###############################################################################

CERT_FILE=""
KEY_FILE=""
CA_FILE=""

# Check for command line argument
if [[ $# -ge 1 && -f "$1" ]]; then
    CERT_FILE="$1"
    echo -e "${BLUE}Using certificate from argument: $CERT_FILE${NC}"
fi

# Try auto-detection if no cert specified
if [[ -z "$CERT_FILE" ]]; then
    echo -e "${BLUE}Scanning certs/ directory for certificates...${NC}"
    echo ""

    # Find all certificate and key files
    crt_files=()
    key_files=()

    # Find all certificate files (include all .crt, .pem, .cer)
    while IFS= read -r -d '' file; do
        crt_files+=("$file")
    done < <(find "$CERT_DIR" -maxdepth 1 \( -name "*.crt" -o -name "*.pem" -o -name "*.cer" \) ! -name "ca-chain.crt" -type f -print0 2>/dev/null || true)

    # Find all key files
    while IFS= read -r -d '' file; do
        key_files+=("$file")
    done < <(find "$CERT_DIR" -maxdepth 1 -name "*.key" -type f -print0 2>/dev/null || true)

    if [[ ${#crt_files[@]} -gt 0 ]]; then
        echo -e "${GREEN}Found ${#crt_files[@]} certificate file(s) and ${#key_files[@]} key file(s) in certs/${NC}"
        echo ""

        # Select certificate
        if [[ ${#crt_files[@]} -eq 1 ]]; then
            CERT_FILE="${crt_files[0]}"
            echo -e "Certificate: ${CYAN}$(basename "$CERT_FILE")${NC}"
        else
            echo -e "${CYAN}Select certificate file:${NC}"
            i=1
            for f in "${crt_files[@]}"; do
                echo "  $i) $(basename "$f")"
                ((i++))
            done
            read -p "Choice [1-${#crt_files[@]}]: " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#crt_files[@]} ]]; then
                CERT_FILE="${crt_files[$((choice-1))]}"
            fi
        fi

        # Select key
        if [[ ${#key_files[@]} -eq 1 ]]; then
            KEY_FILE="${key_files[0]}"
            echo -e "Private key: ${CYAN}$(basename "$KEY_FILE")${NC}"
        elif [[ ${#key_files[@]} -gt 1 ]]; then
            echo ""
            echo -e "${CYAN}Select private key file:${NC}"
            i=1
            for f in "${key_files[@]}"; do
                echo "  $i) $(basename "$f")"
                ((i++))
            done
            read -p "Choice [1-${#key_files[@]}]: " choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#key_files[@]} ]]; then
                KEY_FILE="${key_files[$((choice-1))]}"
            fi
        fi
        echo ""
    else
        echo -e "${YELLOW}No certificates found in certs/ directory.${NC}"
        echo ""
    fi
fi

# Manual input if auto-detection didn't find files
if [[ -z "$CERT_FILE" ]]; then
    echo "Please provide the paths to your certificate files."
    echo "  Example: certs/my-cert.crt or /path/to/certificate.pem"
    echo ""
    read -p "Path to certificate file (.crt/.pem): " CERT_FILE

    # Check if user wants to abort
    if [[ -z "$CERT_FILE" ]]; then
        echo -e "${YELLOW}No certificate specified. Aborting.${NC}"
        echo ""
        echo "Usage: Place your .crt and .key files in certs/ directory"
        echo "       or provide the full path when prompted."
        exit 0
    fi
fi

if [[ ! -f "$CERT_FILE" ]]; then
    echo -e "${RED}Error: Certificate file not found: $CERT_FILE${NC}"
    exit 1
fi

if [[ -z "$KEY_FILE" ]]; then
    # Try to find matching key file
    CERT_BASENAME=$(basename "$CERT_FILE" | sed 's/\.[^.]*$//')
    CERT_DIRNAME=$(dirname "$CERT_FILE")

    # Check for common key file patterns
    for ext in .key -key.pem .pem; do
        if [[ -f "$CERT_DIRNAME/$CERT_BASENAME$ext" ]]; then
            KEY_FILE="$CERT_DIRNAME/$CERT_BASENAME$ext"
            echo -e "Auto-detected key file: ${CYAN}$(basename "$KEY_FILE")${NC}"
            break
        fi
    done

    if [[ -z "$KEY_FILE" ]]; then
        read -p "Path to private key file (.key): " KEY_FILE
    fi

    if [[ -z "$KEY_FILE" ]]; then
        echo -e "${RED}Error: No private key file specified${NC}"
        exit 1
    fi
fi

if [[ ! -f "$KEY_FILE" ]]; then
    echo -e "${RED}Error: Private key file not found: $KEY_FILE${NC}"
    exit 1
fi

# Optional: CA chain file
if [[ -z "$CA_FILE" ]]; then
    # Check for CA chain in certs/
    if [[ -f "$CERT_DIR/ca-chain.crt" ]]; then
        echo -e "Found CA chain: ${CYAN}ca-chain.crt${NC}"
        read -p "Use this CA chain? (Y/n): " -n 1 -r use_ca
        echo
        if [[ ! $use_ca =~ ^[Nn]$ ]]; then
            CA_FILE="$CERT_DIR/ca-chain.crt"
        fi
    else
        read -p "Path to CA chain file (optional, Enter to skip): " CA_FILE
    fi
fi

if [[ -n "$CA_FILE" && ! -f "$CA_FILE" ]]; then
    echo -e "${YELLOW}Warning: CA chain file not found: $CA_FILE (skipping)${NC}"
    CA_FILE=""
fi

# Check if output already exists
if [[ -f "$CERT_DIR/$OUTPUT_NAME.p12" ]]; then
    echo ""
    echo -e "${YELLOW}Warning: P12 file already exists at $CERT_DIR/$OUTPUT_NAME.p12${NC}"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Generate or prompt for passphrase
echo ""
read -p "Generate random passphrase? (Y/n): " -n 1 -r GEN_PASS
echo
if [[ $GEN_PASS =~ ^[Nn]$ ]]; then
    read -sp "Enter passphrase for P12 file: " PASSPHRASE
    echo
    read -sp "Confirm passphrase: " PASSPHRASE_CONFIRM
    echo
    if [[ "$PASSPHRASE" != "$PASSPHRASE_CONFIRM" ]]; then
        echo -e "${RED}Error: Passphrases do not match${NC}"
        exit 1
    fi
else
    # Generate alphanumeric passphrase
    PASSPHRASE=$(openssl rand -hex 24)
fi

echo ""
echo -e "${BLUE}Converting certificate to P12 format...${NC}"

# Build CA option
CA_OPT=""
if [[ -n "$CA_FILE" ]]; then
    CA_OPT="-certfile $CA_FILE"
fi

# Create P12 with compatible encryption
openssl pkcs12 -export \
    -out "$CERT_DIR/$OUTPUT_NAME.p12" \
    -inkey "$KEY_FILE" \
    -in "$CERT_FILE" \
    $CA_OPT \
    -passout pass:"$PASSPHRASE" \
    -certpbe PBE-SHA1-3DES \
    -keypbe PBE-SHA1-3DES \
    -macalg SHA1

# Set proper permissions
chmod 644 "$CERT_DIR/$OUTPUT_NAME.p12"

# Save passphrase
echo "$PASSPHRASE" > "$CERT_DIR/.passphrase"
chmod 600 "$CERT_DIR/.passphrase"

echo -e "${GREEN}P12 conversion complete!${NC}"

# Verify the P12 file
echo -e "${BLUE}Verifying P12 file...${NC}"
openssl pkcs12 -in "$CERT_DIR/$OUTPUT_NAME.p12" -passin pass:"$PASSPHRASE" -noout 2>/dev/null && \
    echo -e "${GREEN}P12 file is valid!${NC}" || \
    echo -e "${RED}Warning: Could not verify P12 file${NC}"

# Show certificate info
echo ""
echo -e "${BLUE}Certificate Information:${NC}"
openssl pkcs12 -in "$CERT_DIR/$OUTPUT_NAME.p12" -passin pass:"$PASSPHRASE" -nokeys 2>/dev/null | \
    openssl x509 -noout -subject -issuer -dates 2>/dev/null || true

# Generate Base64
echo ""
echo -e "${BLUE}Encoding certificate as Base64...${NC}"
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS
    CERT_BASE64=$(base64 -i "$CERT_DIR/$OUTPUT_NAME.p12")
else
    # Linux
    CERT_BASE64=$(base64 -w 0 "$CERT_DIR/$OUTPUT_NAME.p12")
fi

echo -e "${GREEN}Base64 encoding complete!${NC}"

###############################################################################
# Update .env file for Stirling PDF
###############################################################################

update_env_var() {
    local VAR_NAME="$1"
    local VAR_VALUE="$2"
    local COMMENT="$3"

    if grep -q "^${VAR_NAME}=" "$ENV_FILE"; then
        # Update existing value
        sed -i "s|^${VAR_NAME}=.*|${VAR_NAME}=${VAR_VALUE}|" "$ENV_FILE"
        echo -e "${GREEN}Updated ${VAR_NAME} in .env${NC}"
    elif grep -q "^# ${VAR_NAME}=" "$ENV_FILE"; then
        # Uncomment and set value
        sed -i "s|^# ${VAR_NAME}=.*|${VAR_NAME}=${VAR_VALUE}|" "$ENV_FILE"
        echo -e "${GREEN}Enabled ${VAR_NAME} in .env${NC}"
    else
        # Append to file
        if [[ -n "$COMMENT" ]]; then
            echo "" >> "$ENV_FILE"
            echo "# ${COMMENT}" >> "$ENV_FILE"
        fi
        echo "${VAR_NAME}=${VAR_VALUE}" >> "$ENV_FILE"
        echo -e "${GREEN}Added ${VAR_NAME} to .env${NC}"
    fi
}

ENV_UPDATED=false

if [[ -f "$ENV_FILE" ]]; then
    echo ""
    echo -e "${BLUE}Updating .env file...${NC}"
    update_env_var "KEYSTORE_PASSWORD" "$PASSPHRASE" "PDF Signing Certificate Password"
    update_env_var "KEYSTORE_P12_BASE64" "$CERT_BASE64" "PDF Signing Certificate (Base64 encoded P12)"
    ENV_UPDATED=true
else
    echo ""
    echo -e "${YELLOW}Note: .env file not found. Create it from .env.example and add:${NC}"
    echo "  KEYSTORE_PASSWORD=$PASSPHRASE"
    echo "  KEYSTORE_P12_BASE64=<see certs/.p12.base64>"
    # Save Base64 to file for manual use
    echo "$CERT_BASE64" > "$CERT_DIR/.p12.base64"
    chmod 600 "$CERT_DIR/.p12.base64"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Files created:"
echo "  - $CERT_DIR/$OUTPUT_NAME.p12"
echo "  - $CERT_DIR/.passphrase"
[[ -n "$CA_FILE" ]] && echo "  - CA chain included in P12"
echo ""
echo -e "${BLUE}Certificate Details:${NC}"
openssl pkcs12 -in "$CERT_DIR/$OUTPUT_NAME.p12" -passin pass:"$PASSPHRASE" -nokeys 2>/dev/null | \
    openssl x509 -noout -subject -enddate 2>/dev/null | sed 's/^/  /' || true
echo ""
echo -e "${BLUE}Passphrase:${NC} $PASSPHRASE"
echo ""
if [[ "$ENV_UPDATED" == "true" ]]; then
    echo -e "${GREEN}Environment variables written to .env:${NC}"
    echo "  - KEYSTORE_PASSWORD"
    echo "  - KEYSTORE_P12_BASE64"
    echo ""
fi
echo -e "${GREEN}========================================${NC}"
