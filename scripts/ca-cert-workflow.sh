#!/bin/bash
###############################################################################
# CA Certificate Workflow for PDF Signing
# Two-step process for obtaining CA-signed certificates
#
# Step 1: Generate CSR and private key
# Step 2: Import signed certificate and create P12
#
# For Stirling PDF, the .p12 file is mounted to /customFiles/signatures/
###############################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CERT_DIR="$PROJECT_DIR/certs"
CSR_NAME="signing-request"
OUTPUT_NAME="cert"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed or not in PATH${NC}"
    exit 1
fi

# Create certs directory if it doesn't exist
mkdir -p "$CERT_DIR"

# =============================================================================
# Step 1: Generate CSR
# =============================================================================
generate_csr() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Step 1: Generate Certificate Request${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Check if CSR or key already exists
    if [[ -f "$CERT_DIR/$CSR_NAME.csr" ]] || [[ -f "$CERT_DIR/$CSR_NAME.key" ]]; then
        echo -e "${YELLOW}Warning: CSR or private key already exists${NC}"
        echo "  - $CERT_DIR/$CSR_NAME.csr"
        echo "  - $CERT_DIR/$CSR_NAME.key"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    # Prompt for certificate details
    echo "Enter certificate details (press Enter for defaults):"
    echo ""

    read -p "Organization Name [BAUER GROUP]: " ORG_NAME
    ORG_NAME=${ORG_NAME:-"BAUER GROUP"}

    read -p "Organizational Unit []: " ORG_UNIT
    ORG_UNIT=${ORG_UNIT:-""}

    read -p "Country Code (2 letters) [DE]: " COUNTRY
    COUNTRY=${COUNTRY:-"DE"}

    read -p "State/Province []: " STATE
    STATE=${STATE:-""}

    read -p "City []: " CITY
    CITY=${CITY:-""}

    read -p "Common Name [PDF Signing Certificate]: " CN
    CN=${CN:-"PDF Signing Certificate"}

    read -p "Email Address (optional) []: " EMAIL
    EMAIL=${EMAIL:-""}

    # Key size selection
    echo ""
    echo "Key size: 1) 2048 bit  2) 4096 bit (recommended)"
    read -p "Choice [2]: " KEY_SIZE_CHOICE
    KEY_SIZE_CHOICE=${KEY_SIZE_CHOICE:-"2"}
    [[ "$KEY_SIZE_CHOICE" == "1" ]] && KEY_SIZE=2048 || KEY_SIZE=4096

    # Build subject string
    SUBJECT="/CN=$CN/O=$ORG_NAME"
    [[ -n "$ORG_UNIT" ]] && SUBJECT="/OU=$ORG_UNIT$SUBJECT"
    [[ -n "$COUNTRY" ]] && SUBJECT="/C=$COUNTRY$SUBJECT"
    [[ -n "$STATE" ]] && SUBJECT="/ST=$STATE$SUBJECT"
    [[ -n "$CITY" ]] && SUBJECT="/L=$CITY$SUBJECT"
    [[ -n "$EMAIL" ]] && SUBJECT="$SUBJECT/emailAddress=$EMAIL"

    echo ""
    echo -e "${BLUE}Subject: $SUBJECT${NC}"
    echo ""

    # Generate private key
    echo -e "${BLUE}Generating private key ($KEY_SIZE bit)...${NC}"
    openssl genrsa -out "$CERT_DIR/$CSR_NAME.key" $KEY_SIZE 2>/dev/null
    chmod 600 "$CERT_DIR/$CSR_NAME.key"
    echo -e "${GREEN}Private key generated!${NC}"

    # Generate CSR
    echo -e "${BLUE}Generating CSR...${NC}"
    openssl req -new -key "$CERT_DIR/$CSR_NAME.key" -out "$CERT_DIR/$CSR_NAME.csr" -subj "$SUBJECT" -sha256
    echo -e "${GREEN}CSR generated!${NC}"

    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} CSR Generated Successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Files created:"
    echo -e "  ${BLUE}$CERT_DIR/$CSR_NAME.csr${NC} (submit to CA)"
    echo -e "  ${BLUE}$CERT_DIR/$CSR_NAME.key${NC} (KEEP SECURE!)"
    echo ""
    echo -e "${YELLOW}Next: Submit CSR to your CA, then run this script again for Step 2${NC}"
    echo ""
    echo -e "${BLUE}CSR Content:${NC}"
    echo "----------------------------------------"
    cat "$CERT_DIR/$CSR_NAME.csr"
    echo "----------------------------------------"
}

# =============================================================================
# Step 2: Import Signed Certificate
# =============================================================================
import_certificate() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Step 2: Import Signed Certificate${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    # Check for private key
    if [[ ! -f "$CERT_DIR/$CSR_NAME.key" ]]; then
        echo -e "${RED}Error: Private key not found!${NC}"
        echo "Expected: $CERT_DIR/$CSR_NAME.key"
        echo ""
        read -p "Path to private key (or Enter to abort): " CUSTOM_KEY
        if [[ -z "$CUSTOM_KEY" ]] || [[ ! -f "$CUSTOM_KEY" ]]; then
            echo -e "${RED}Aborted.${NC}"
            return 1
        fi
        KEY_FILE="$CUSTOM_KEY"
    else
        KEY_FILE="$CERT_DIR/$CSR_NAME.key"
        echo -e "${GREEN}Found private key from Step 1${NC}"
    fi

    # Get signed certificate
    echo ""
    read -p "Path to signed certificate from CA: " SIGNED_CERT
    if [[ -z "$SIGNED_CERT" ]] || [[ ! -f "$SIGNED_CERT" ]]; then
        echo -e "${RED}Error: Certificate not found${NC}"
        return 1
    fi

    # Verify certificate
    echo -e "${BLUE}Verifying certificate...${NC}"
    if ! openssl x509 -in "$SIGNED_CERT" -noout 2>/dev/null; then
        echo -e "${RED}Error: Invalid certificate${NC}"
        return 1
    fi

    # Check certificate matches key
    echo -e "${BLUE}Verifying certificate matches private key...${NC}"
    CERT_MOD=$(openssl x509 -in "$SIGNED_CERT" -noout -modulus 2>/dev/null | md5sum)
    KEY_MOD=$(openssl rsa -in "$KEY_FILE" -noout -modulus 2>/dev/null | md5sum)
    if [[ "$CERT_MOD" != "$KEY_MOD" ]]; then
        echo -e "${RED}Error: Certificate does not match private key!${NC}"
        return 1
    fi
    echo -e "${GREEN}Certificate matches key!${NC}"

    # Optional CA chain
    echo ""
    read -p "Path to CA chain file (optional, Enter to skip): " CA_FILE
    if [[ -n "$CA_FILE" && ! -f "$CA_FILE" ]]; then
        echo -e "${RED}Error: CA chain file not found${NC}"
        return 1
    fi

    # Show certificate info
    echo ""
    echo -e "${BLUE}Certificate Information:${NC}"
    openssl x509 -in "$SIGNED_CERT" -noout -subject -issuer -dates 2>/dev/null | sed 's/^/  /'

    # Check for existing P12
    if [[ -f "$CERT_DIR/$OUTPUT_NAME.p12" ]]; then
        echo ""
        echo -e "${YELLOW}Warning: P12 already exists at $CERT_DIR/$OUTPUT_NAME.p12${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Aborted."
            return 1
        fi
    fi

    # Passphrase
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
            return 1
        fi
    else
        PASSPHRASE=$(openssl rand -hex 24)
    fi

    # Create P12
    echo ""
    echo -e "${BLUE}Creating P12 certificate...${NC}"

    CA_OPT=""
    [[ -n "$CA_FILE" ]] && CA_OPT="-certfile $CA_FILE"

    openssl pkcs12 -export \
        -out "$CERT_DIR/$OUTPUT_NAME.p12" \
        -inkey "$KEY_FILE" \
        -in "$SIGNED_CERT" \
        $CA_OPT \
        -passout pass:"$PASSPHRASE" \
        -certpbe PBE-SHA1-3DES \
        -keypbe PBE-SHA1-3DES \
        -macalg SHA1

    chmod 644 "$CERT_DIR/$OUTPUT_NAME.p12"
    echo -e "${GREEN}P12 created!${NC}"

    # Backup files
    cp "$SIGNED_CERT" "$CERT_DIR/$OUTPUT_NAME.crt"
    cp "$KEY_FILE" "$CERT_DIR/$OUTPUT_NAME.key"
    chmod 600 "$CERT_DIR/$OUTPUT_NAME.key"
    [[ -n "$CA_FILE" ]] && cp "$CA_FILE" "$CERT_DIR/ca-chain.crt"

    # Verify P12
    echo -e "${BLUE}Verifying P12...${NC}"
    if openssl pkcs12 -in "$CERT_DIR/$OUTPUT_NAME.p12" -passin pass:"$PASSPHRASE" -noout 2>/dev/null; then
        echo -e "${GREEN}P12 is valid!${NC}"
    else
        echo -e "${RED}Warning: P12 verification failed${NC}"
    fi

    # Save passphrase
    PASSPHRASE_FILE="$CERT_DIR/.passphrase"
    echo "$PASSPHRASE" > "$PASSPHRASE_FILE"
    chmod 600 "$PASSPHRASE_FILE"

    # Cleanup temporary files from Step 1
    echo ""
    CLEANUP_FILES=""
    [[ -f "$CERT_DIR/$CSR_NAME.csr" ]] && CLEANUP_FILES="$CSR_NAME.csr "
    [[ -f "$CERT_DIR/$CSR_NAME.key" ]] && CLEANUP_FILES="$CLEANUP_FILES$CSR_NAME.key"

    if [[ -n "$CLEANUP_FILES" ]]; then
        echo "Temporary files from Step 1: $CLEANUP_FILES"
        read -p "Remove these files (no longer needed)? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            rm -f "$CERT_DIR/$CSR_NAME.csr" "$CERT_DIR/$CSR_NAME.key" 2>/dev/null
            echo "  Cleanup complete"
        fi
    fi

    # Summary
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN} Certificate Import Complete${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo "Files created:"
    echo "  - $CERT_DIR/$OUTPUT_NAME.p12"
    echo "  - $CERT_DIR/$OUTPUT_NAME.crt"
    echo "  - $CERT_DIR/$OUTPUT_NAME.key"
    echo "  - $CERT_DIR/.passphrase"
    [[ -n "$CA_FILE" ]] && echo "  - $CERT_DIR/ca-chain.crt"
    echo ""
    echo -e "${BLUE}Passphrase:${NC} $PASSPHRASE"
    echo ""
    echo -e "${YELLOW}Next steps for Stirling PDF:${NC}"
    echo "  1. Mount certificate into container:"
    echo "     volumes:"
    echo "       - ./certs/cert.p12:/customFiles/signatures/cert.p12:ro"
    echo ""
    echo "  2. Restart the container"
    echo ""
    echo -e "${GREEN}========================================${NC}"
}

# =============================================================================
# Main Menu
# =============================================================================
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} CA Certificate Workflow${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Auto-detect step based on existing files
if [[ -f "$CERT_DIR/$CSR_NAME.key" ]] && [[ -f "$CERT_DIR/$CSR_NAME.csr" ]]; then
    echo -e "${BLUE}Detected: CSR already exists${NC}"
    DEFAULT_STEP=2
elif [[ -f "$CERT_DIR/$CSR_NAME.key" ]]; then
    echo -e "${BLUE}Detected: Private key exists (CSR may have been submitted)${NC}"
    DEFAULT_STEP=2
else
    DEFAULT_STEP=1
fi

echo ""
echo "Steps:"
echo "  1) Generate CSR and private key (submit CSR to CA)"
echo "  2) Import signed certificate (after receiving from CA)"
echo ""
read -p "Select step [$DEFAULT_STEP]: " STEP
STEP=${STEP:-$DEFAULT_STEP}

case $STEP in
    1)
        generate_csr
        ;;
    2)
        import_certificate
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac
