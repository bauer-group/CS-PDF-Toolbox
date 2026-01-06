#!/bin/bash
###############################################################################
# PDF Toolbox Secret Generator
# Generates secure random secrets for use in .env configuration
#
# For Stirling PDF, secrets are simpler than Documenso:
# - Admin password
# - API key (optional)
###############################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(dirname "$0")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} PDF Toolbox Secret Generator${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Check if openssl is available
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}Error: OpenSSL is not installed${NC}"
    exit 1
fi

# Generate secrets
echo -e "${BLUE}Generating secrets...${NC}"

# Admin password (alphanumeric, 24 chars)
ADMIN_PASSWORD=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 24)

# API Key (hex, 32 chars)
API_KEY=$(openssl rand -hex 16)

# SMTP password placeholder (user should set their own)
SMTP_PASSWORD="CHANGE_ME_$(openssl rand -hex 8)"

echo -e "${GREEN}Secrets generated successfully!${NC}"
echo ""

# Check if .env exists
UPDATE_ENV=false
if [[ -f "$ENV_FILE" ]]; then
    echo -e "${YELLOW}Found existing .env file${NC}"
    read -p "Do you want to update it with new secrets? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        UPDATE_ENV=true
    fi
else
    # Create .env from .env.example
    if [[ -f "$ENV_EXAMPLE" ]]; then
        echo -e "${BLUE}Creating .env from .env.example...${NC}"
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        UPDATE_ENV=true
    fi
fi

# Display secrets
echo ""
echo -e "${BLUE}Generated Secrets:${NC}"
echo "=========================================="
echo ""
echo -e "  ${GREEN}SECURITY_INITIAL_LOGIN_PASSWORD${NC}=$ADMIN_PASSWORD"
echo -e "  ${GREEN}SECURITY_CUSTOM_GLOBAL_API_KEY${NC}=$API_KEY"
echo -e "  ${GREEN}MAIL_PASSWORD${NC}=$SMTP_PASSWORD"
echo ""
echo "=========================================="

# Update .env file if requested
if [[ "$UPDATE_ENV" == true ]]; then
    echo ""
    echo -e "${BLUE}Updating .env file...${NC}"

    # macOS and Linux compatible sed
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s|^SECURITY_INITIAL_LOGIN_PASSWORD=.*|SECURITY_INITIAL_LOGIN_PASSWORD=$ADMIN_PASSWORD|" "$ENV_FILE"
        sed -i '' "s|^MAIL_PASSWORD=.*|MAIL_PASSWORD=$SMTP_PASSWORD|" "$ENV_FILE"
        # API key is optional, only update if exists
        grep -q "^SECURITY_CUSTOM_GLOBAL_API_KEY=" "$ENV_FILE" && \
            sed -i '' "s|^SECURITY_CUSTOM_GLOBAL_API_KEY=.*|SECURITY_CUSTOM_GLOBAL_API_KEY=$API_KEY|" "$ENV_FILE" || \
            echo "# SECURITY_CUSTOM_GLOBAL_API_KEY=$API_KEY" >> "$ENV_FILE"
    else
        sed -i "s|^SECURITY_INITIAL_LOGIN_PASSWORD=.*|SECURITY_INITIAL_LOGIN_PASSWORD=$ADMIN_PASSWORD|" "$ENV_FILE"
        sed -i "s|^MAIL_PASSWORD=.*|MAIL_PASSWORD=$SMTP_PASSWORD|" "$ENV_FILE"
        grep -q "^SECURITY_CUSTOM_GLOBAL_API_KEY=" "$ENV_FILE" && \
            sed -i "s|^SECURITY_CUSTOM_GLOBAL_API_KEY=.*|SECURITY_CUSTOM_GLOBAL_API_KEY=$API_KEY|" "$ENV_FILE" || \
            echo "# SECURITY_CUSTOM_GLOBAL_API_KEY=$API_KEY" >> "$ENV_FILE"
    fi

    echo -e "${GREEN}.env file updated!${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}Generated:${NC}"
echo "  - Admin password (for initial login)"
echo "  - API key (for programmatic access)"
echo "  - SMTP password placeholder"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Review .env file and update SMTP settings if needed"
echo "  2. Enable login: SECURITY_ENABLE_LOGIN=true"
echo "  3. Start the stack: docker compose -f docker-compose.development.yml up -d"
echo "  4. Login with: admin / $ADMIN_PASSWORD"
echo "  5. Change password after first login!"
echo ""
echo -e "${GREEN}========================================${NC}"
