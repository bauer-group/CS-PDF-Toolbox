#!/bin/bash
###############################################################################
# Apply Custom Translations to Stirling PDF V2
# This script handles custom translation file placement
#
# Compatible with: Stirling PDF V2 (React frontend)
#
# NOTE: Stirling PDF V2 includes 40+ languages out of the box.
#       The V2 React frontend uses JSON-based translations internally,
#       but the backend still supports properties files for custom overrides.
#
# Custom translations can be added by:
#       1. Mounting custom translation files to /customFiles/translations/
#       2. Setting LANGS environment variable to limit available languages
#
# V2 Changes:
#       - Frontend uses i18n JSON files (compiled into React bundle)
#       - Backend still uses messages_XX.properties for API responses
#       - Custom translations go to /customFiles/ (not /customFiles/static/)
###############################################################################

set -eu

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN} Checking Translation Configuration${NC}"
echo -e "${CYAN}========================================${NC}"

# Configuration
BRANDING_DIR="${BRANDING_DIR:-/branding}"
# V2: customFiles is at root level, not inside /configs
# Can be overridden via CUSTOM_FILES_DIR env var (e.g., /branding-template for build-time)
CUSTOM_FILES_BASE="${CUSTOM_FILES_DIR:-/customFiles}"
TRANSLATIONS_SOURCE="$BRANDING_DIR/translations"

# =============================================================================
# Check for custom translation files
# =============================================================================

echo -e "${BLUE}[1/2] Checking for custom translations...${NC}"

if [[ ! -d "$TRANSLATIONS_SOURCE" ]]; then
    echo -e "${YELLOW}  No translations directory found at $TRANSLATIONS_SOURCE${NC}"
    echo -e "${YELLOW}  Using default Stirling PDF translations.${NC}"
    echo ""
    echo -e "${GREEN}Stirling PDF includes translations for 40+ languages.${NC}"
    echo -e "Set the LANGS environment variable to limit available languages."
    echo -e "Example: LANGS=en_GB,de_DE,fr_FR"
    exit 0
fi

# Count custom property files
PROPS_FILES=$(find "$TRANSLATIONS_SOURCE" -maxdepth 1 -name "messages_*.properties" -type f 2>/dev/null | wc -l)

if [[ "$PROPS_FILES" -eq 0 ]]; then
    echo -e "${YELLOW}  No custom messages_*.properties files found${NC}"
    echo -e "${YELLOW}  Using default Stirling PDF translations.${NC}"
    exit 0
fi

echo -e "  Found ${GREEN}$PROPS_FILES${NC} custom translation file(s)"

# =============================================================================
# Copy custom translation files
# =============================================================================

echo -e "${BLUE}[2/2] Copying custom translations...${NC}"

# V2: customFiles is at root level (or branding-template during build)
CUSTOM_TRANSLATIONS_DIR="$CUSTOM_FILES_BASE/translations"
mkdir -p "$CUSTOM_TRANSLATIONS_DIR"

COPIED=0
for props_file in "$TRANSLATIONS_SOURCE"/messages_*.properties; do
    if [[ -f "$props_file" ]]; then
        filename=$(basename "$props_file")
        cp "$props_file" "$CUSTOM_TRANSLATIONS_DIR/$filename"
        echo "  Copied: $filename"
        ((COPIED++)) || true
    fi
done

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Translation Configuration Complete${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "  Custom translations copied: ${GREEN}$COPIED${NC}"
echo -e "  Target directory: $CUSTOM_TRANSLATIONS_DIR"
echo ""
echo -e "${BLUE}Note:${NC} Stirling PDF will automatically load custom translations"
echo -e "      from the customFiles directory on startup."
echo ""
