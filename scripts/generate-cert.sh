#!/bin/bash
###############################################################################
# PDF Signing Certificate Generator
# Generates a self-signed P12 certificate for PDF digital signatures
#
# The generated certificate is:
#   1. Saved as P12 file in certs/ (backup)
#   2. Encoded as Base64 and written to .env (KEYSTORE_P12_BASE64)
#   3. Password written to .env (KEYSTORE_PASSWORD)
#
# The container entrypoint decodes KEYSTORE_P12_BASE64 at startup.
#
# Usage:
#   ./scripts/generate-cert.sh
#
# Output:
#   - certs/cert.p12  (backup)
#   - certs/cert.crt  (public certificate)
#   - certs/cert.key  (private key backup)
#   - .env updates:   KEYSTORE_P12_BASE64, KEYSTORE_PASSWORD
###############################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$PROJECT_DIR/certs"
CERT_NAME="cert"
VALIDITY_DAYS=3650  # 10 years

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} PDF Signing Certificate Generator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed or not in PATH${NC}"
    exit 1
fi

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

# Check if certificate already exists
if [[ -f "$CERT_DIR/$CERT_NAME.p12" ]]; then
    echo -e "${YELLOW}Warning: Certificate already exists at $CERT_DIR/$CERT_NAME.p12${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Prompt for certificate details
echo "Enter certificate details (press Enter for defaults):"
echo ""

read -p "Organization Name [BAUER GROUP]: " ORG_NAME
ORG_NAME=${ORG_NAME:-"BAUER GROUP"}

read -p "Country Code (2 letters) [DE]: " COUNTRY
COUNTRY=${COUNTRY:-"DE"}

read -p "State/Province []: " STATE
STATE=${STATE:-""}

read -p "City []: " CITY
CITY=${CITY:-""}

read -p "Common Name [PDF Signing Certificate]: " CN
CN=${CN:-"PDF Signing Certificate"}

# Generate passphrase or prompt for one
echo ""
read -p "Generate random passphrase? (Y/n): " -n 1 -r GEN_PASS
echo
if [[ $GEN_PASS =~ ^[Nn]$ ]]; then
    read -sp "Enter passphrase: " PASSPHRASE
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

# Build subject string
SUBJECT="/CN=$CN/O=$ORG_NAME"
[[ -n "$COUNTRY" ]] && SUBJECT="/C=$COUNTRY$SUBJECT"
[[ -n "$STATE" ]] && SUBJECT="/ST=$STATE$SUBJECT"
[[ -n "$CITY" ]] && SUBJECT="/L=$CITY$SUBJECT"

echo ""
echo -e "${BLUE}Generating certificate...${NC}"

# Generate private key and certificate
openssl req \
    -x509 \
    -newkey rsa:4096 \
    -keyout "$CERT_DIR/$CERT_NAME.key" \
    -out "$CERT_DIR/$CERT_NAME.crt" \
    -sha256 \
    -days $VALIDITY_DAYS \
    -nodes \
    -subj "$SUBJECT" \
    2>/dev/null

# Convert to P12 format (compatible with most PDF signing tools)
openssl pkcs12 \
    -export \
    -out "$CERT_DIR/$CERT_NAME.p12" \
    -inkey "$CERT_DIR/$CERT_NAME.key" \
    -in "$CERT_DIR/$CERT_NAME.crt" \
    -passout pass:"$PASSPHRASE" \
    -certpbe PBE-SHA1-3DES \
    -keypbe PBE-SHA1-3DES \
    -macalg SHA1

# Set proper permissions
chmod 644 "$CERT_DIR/$CERT_NAME.p12"
chmod 600 "$CERT_DIR/$CERT_NAME.key"

echo -e "${GREEN}Certificate generated successfully!${NC}"

# Save passphrase to a file (secured)
PASSPHRASE_FILE="$CERT_DIR/.passphrase"
echo "$PASSPHRASE" > "$PASSPHRASE_FILE"
chmod 600 "$PASSPHRASE_FILE"

# Generate Base64 encoded P12 for environment variable
P12_BASE64=$(base64 -w 0 "$CERT_DIR/$CERT_NAME.p12")

# Update .env with certificate values
ENV_FILE="$PROJECT_DIR/.env"

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

if [[ -f "$ENV_FILE" ]]; then
    update_env_var "KEYSTORE_PASSWORD" "$PASSPHRASE" "PDF Signing Certificate Password"
    update_env_var "KEYSTORE_P12_BASE64" "$P12_BASE64" "PDF Signing Certificate (Base64 encoded P12)"
else
    echo -e "${YELLOW}Note: .env file not found. Create it from .env.example and add:${NC}"
    echo "  KEYSTORE_PASSWORD=$PASSPHRASE"
    echo "  KEYSTORE_P12_BASE64=<base64-encoded-p12>"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Files created:"
echo "  - $CERT_DIR/$CERT_NAME.p12   (signing certificate)"
echo "  - $CERT_DIR/$CERT_NAME.key   (private key backup)"
echo "  - $CERT_DIR/$CERT_NAME.crt   (public certificate)"
echo "  - $CERT_DIR/.passphrase      (certificate passphrase)"
echo ""
echo -e "${BLUE}Certificate Details:${NC}"
echo "  Organization: $ORG_NAME"
echo "  Common Name:  $CN"
echo "  Valid for:    $VALIDITY_DAYS days (~10 years)"
echo ""
echo -e "${BLUE}Passphrase:${NC} $PASSPHRASE"
echo ""
echo -e "${GREEN}Environment variables written to .env:${NC}"
echo "  - KEYSTORE_PASSWORD (certificate passphrase)"
echo "  - KEYSTORE_P12_BASE64 (Base64 encoded certificate)"
echo ""
echo -e "${YELLOW}Usage Options:${NC}"
echo ""
echo "  ${BLUE}Option A: Environment Variables (recommended for Coolify/CI)${NC}"
echo "    The container entrypoint automatically decodes KEYSTORE_P12_BASE64"
echo "    and writes it to /configs/keystore.p12 at startup."
echo "    Just set the env vars in your deployment platform."
echo ""
echo "  ${BLUE}Option B: Direct Volume Mount (local development)${NC}"
echo "    volumes:"
echo "      - './certs/cert.p12:/configs/keystore.p12:ro'"
echo ""
echo -e "${GREEN}========================================${NC}"
