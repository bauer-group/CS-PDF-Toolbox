#!/bin/bash
###############################################################################
# Apply White-Label Branding to Stirling PDF V2
# This script applies custom branding during Docker build
#
# Compatible with: Stirling PDF V2 (React frontend)
# Repository: https://github.com/Stirling-Tools/Stirling-PDF
#
# V2 Branding:
# - Logo files in /customFiles/static/modern-logo/ (or classic-logo/)
# - Favicon in /customFiles/static/
# - Custom CSS in /customFiles/static/
# - App name/description via admin UI (not env vars in V2)
#
# V2 Logo Structure:
#   customFiles/static/modern-logo/
#     ├── StirlingPDFLogoBlackText.svg    (light mode with text)
#     ├── StirlingPDFLogoWhiteText.svg    (dark mode with text)
#     ├── StirlingPDFLogoNoTextLight.svg  (icon only, light)
#     ├── StirlingPDFLogoNoTextDark.svg   (icon only, dark)
#     ├── logo-tooltip.svg                (small tooltip icon)
#     └── favicon.ico                     (style-specific favicon)
###############################################################################

set -eu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} Applying V2 White-Label Branding${NC}"
echo -e "${GREEN}========================================${NC}"

# Load branding configuration
BRANDING_DIR="${BRANDING_DIR:-/branding}"
STIRLING_DIR="${STIRLING_DIR:-/configs}"

# V2: customFiles is at root level, not inside /configs
# Can be overridden via CUSTOM_FILES_DIR env var (e.g., /branding-template/static for build-time)
CUSTOM_FILES_DIR="${CUSTOM_FILES_DIR:-/customFiles/static}"

if [[ -f "$BRANDING_DIR/branding.env" ]]; then
    echo -e "${BLUE}Loading branding configuration...${NC}"
    set -a
    source "$BRANDING_DIR/branding.env"
    set +a
else
    echo -e "${YELLOW}Warning: No branding.env found, using defaults${NC}"
    BRAND_APP_NAME="${BRAND_APP_NAME:-PDF Toolbox}"
    BRAND_COMPANY_NAME="${BRAND_COMPANY_NAME:-Company}"
fi

echo -e "${BLUE}Custom files directory: $CUSTOM_FILES_DIR${NC}"
echo ""

# =============================================================================
# 1. Create Directory Structure
# =============================================================================
echo -e "${BLUE}[1/5] Creating directory structure...${NC}"

mkdir -p "$CUSTOM_FILES_DIR/modern-logo"
mkdir -p "$CUSTOM_FILES_DIR/classic-logo"
echo "  Created logo directories"

# =============================================================================
# 2. Copy Logo Files for V2
# =============================================================================
echo -e "${BLUE}[2/5] Setting up V2 logo files...${NC}"

# Check if we have source logos
if [[ -f "$BRANDING_DIR/logo-source-wide.svg" ]]; then
    # Copy wide logo as the text variants
    cp "$BRANDING_DIR/logo-source-wide.svg" "$CUSTOM_FILES_DIR/modern-logo/StirlingPDFLogoBlackText.svg"
    cp "$BRANDING_DIR/logo-source-wide.svg" "$CUSTOM_FILES_DIR/modern-logo/StirlingPDFLogoWhiteText.svg"
    cp "$BRANDING_DIR/logo-source-wide.svg" "$CUSTOM_FILES_DIR/modern-logo/StirlingPDFLogoGreyText.svg"
    echo "  Copied wide logo as text variants"
fi

if [[ -f "$BRANDING_DIR/logo-source-square.svg" ]]; then
    # Copy square logo as the icon variants
    cp "$BRANDING_DIR/logo-source-square.svg" "$CUSTOM_FILES_DIR/modern-logo/StirlingPDFLogoNoTextLight.svg"
    cp "$BRANDING_DIR/logo-source-square.svg" "$CUSTOM_FILES_DIR/modern-logo/StirlingPDFLogoNoTextDark.svg"
    cp "$BRANDING_DIR/logo-source-square.svg" "$CUSTOM_FILES_DIR/modern-logo/logo-tooltip.svg"
    echo "  Copied square logo as icon variants"
fi

# Copy to classic-logo as well for compatibility
if [[ -d "$CUSTOM_FILES_DIR/modern-logo" ]]; then
    cp -r "$CUSTOM_FILES_DIR/modern-logo/"* "$CUSTOM_FILES_DIR/classic-logo/" 2>/dev/null || true
    echo "  Mirrored to classic-logo directory"
fi

# =============================================================================
# 3. Copy Favicon Files
# =============================================================================
echo -e "${BLUE}[3/5] Setting up favicons...${NC}"

# Main favicon.svg (V2 prefers SVG)
if [[ -f "$BRANDING_DIR/logo-source-square.svg" ]]; then
    cp "$BRANDING_DIR/logo-source-square.svg" "$CUSTOM_FILES_DIR/favicon.svg"
    echo "  Copied favicon.svg"
fi

# Fallback favicon.ico
if [[ -f "$BRANDING_DIR/assets/favicon.ico" ]]; then
    cp "$BRANDING_DIR/assets/favicon.ico" "$CUSTOM_FILES_DIR/favicon.ico"
    cp "$BRANDING_DIR/assets/favicon.ico" "$CUSTOM_FILES_DIR/modern-logo/favicon.ico"
    cp "$BRANDING_DIR/assets/favicon.ico" "$CUSTOM_FILES_DIR/classic-logo/favicon.ico"
    echo "  Copied favicon.ico"
fi

# PNG favicons for various sizes
for favicon in favicon-16x16.png favicon-32x32.png favicon-48x48.png; do
    if [[ -f "$BRANDING_DIR/assets/$favicon" ]]; then
        cp "$BRANDING_DIR/assets/$favicon" "$CUSTOM_FILES_DIR/$favicon"
        echo "  Copied $favicon"
    fi
done

# Apple touch icon
if [[ -f "$BRANDING_DIR/assets/apple-touch-icon.png" ]]; then
    cp "$BRANDING_DIR/assets/apple-touch-icon.png" "$CUSTOM_FILES_DIR/apple-touch-icon.png"
    echo "  Copied apple-touch-icon.png"
fi

# Android chrome icons
for size in 192x192 512x512; do
    if [[ -f "$BRANDING_DIR/assets/android-chrome-${size}.png" ]]; then
        cp "$BRANDING_DIR/assets/android-chrome-${size}.png" "$CUSTOM_FILES_DIR/android-chrome-${size}.png"
        echo "  Copied android-chrome-${size}.png"
    fi
done

# =============================================================================
# 4. Create Custom CSS (Theme Colors + Hide Unwanted Elements)
# =============================================================================
echo -e "${BLUE}[4/5] Creating custom CSS...${NC}"

CSS_FILE="$CUSTOM_FILES_DIR/custom.css"

# Use colors from branding.env (with defaults)
PRIMARY_COLOR="${BRAND_THEME_COLOR:-#FF8500}"
PRIMARY_HOVER="${BRAND_ORANGE_600:-#EA6D00}"
PRIMARY_LIGHT="${BRAND_ORANGE_100:-#FFEDD5}"
PRIMARY_DARK="${BRAND_ORANGE_700:-#C2570A}"
BG_SUBTLE="${BRAND_BACKGROUND_SUBTLE:-#FAFAFA}"
BORDER_COLOR="${BRAND_BORDER:-#E4E4E7}"
TEXT_SECONDARY="${BRAND_TEXT_SECONDARY:-#52525B}"

cat > "$CSS_FILE" << CSSEOF
/* =============================================================================
 * Stirling PDF V2 Custom Branding CSS
 * Generated by apply-branding.sh
 * Primary Color: ${PRIMARY_COLOR}
 * ============================================================================= */

/* =============================================================================
 * HIDE UNWANTED FOOTER LINKS
 * Removes: Survey (Umfrage), Discord, GitHub links
 * ============================================================================= */

/* Hide social/external links in footer */
footer a[href*="discord"],
footer a[href*="github.com/Stirling"],
footer a[href*="survey"],
footer a[href*="umfrage"],
a[href*="discord.gg"],
a[href*="github.com/Stirling-Tools"] {
  display: none !important;
}

/* Hide any "Made with" or attribution links */
footer .social-links,
footer .external-links,
[class*="social"],
[class*="discord"],
[class*="github-link"] {
  display: none !important;
}

/* =============================================================================
 * PRIMARY COLOR OVERRIDES
 * ============================================================================= */

:root {
  /* Primary Color */
  --primary-color: ${PRIMARY_COLOR} !important;
  --primary-color-hover: ${PRIMARY_HOVER} !important;
  --primary-color-light: ${PRIMARY_LIGHT} !important;
  --primary-color-dark: ${PRIMARY_DARK} !important;

  /* Override common CSS variable names */
  --color-primary: ${PRIMARY_COLOR} !important;
  --color-primary-hover: ${PRIMARY_HOVER} !important;
  --accent-color: ${PRIMARY_COLOR} !important;
  --brand-color: ${PRIMARY_COLOR} !important;

  /* MUI/React common variables */
  --mui-palette-primary-main: ${PRIMARY_COLOR} !important;
  --mui-palette-primary-light: ${PRIMARY_LIGHT} !important;
  --mui-palette-primary-dark: ${PRIMARY_DARK} !important;
}

/* Button overrides */
button[class*="primary"],
.btn-primary,
[class*="MuiButton"][class*="primary"],
[class*="MuiButton-containedPrimary"] {
  background-color: ${PRIMARY_COLOR} !important;
  border-color: ${PRIMARY_COLOR} !important;
}

button[class*="primary"]:hover,
.btn-primary:hover,
[class*="MuiButton"][class*="primary"]:hover {
  background-color: ${PRIMARY_HOVER} !important;
  border-color: ${PRIMARY_HOVER} !important;
}

/* Focus states */
button:focus,
.btn:focus,
input:focus,
[class*="MuiOutlinedInput"]:focus-within {
  outline-color: ${PRIMARY_COLOR} !important;
  border-color: ${PRIMARY_COLOR} !important;
}

/* Links */
a:not([class*="btn"]) {
  color: ${PRIMARY_COLOR};
}

a:not([class*="btn"]):hover {
  color: ${PRIMARY_HOVER};
}

/* Progress bars */
[class*="progress"],
[class*="MuiLinearProgress"] {
  background-color: ${PRIMARY_LIGHT} !important;
}

[class*="progress"] > *,
[class*="MuiLinearProgress-bar"] {
  background-color: ${PRIMARY_COLOR} !important;
}

/* Checkboxes and switches */
[class*="MuiCheckbox-root"].Mui-checked,
[class*="MuiSwitch-root"] .Mui-checked {
  color: ${PRIMARY_COLOR} !important;
}

/* Selected/active states */
[class*="Mui-selected"],
[class*="active"],
.nav-link.active {
  color: ${PRIMARY_COLOR} !important;
  border-color: ${PRIMARY_COLOR} !important;
}

/* Tabs */
[class*="MuiTab-root"].Mui-selected {
  color: ${PRIMARY_COLOR} !important;
}

[class*="MuiTabs-indicator"] {
  background-color: ${PRIMARY_COLOR} !important;
}

/* Chips/badges */
[class*="MuiChip"][class*="primary"],
.badge-primary {
  background-color: ${PRIMARY_COLOR} !important;
}

/* =============================================================================
 * HIDE LICENSE WARNING / UPGRADE PROMPTS
 * ============================================================================= */

/* Hide any license/upgrade banners */
[class*="license"],
[class*="upgrade"],
[class*="premium"],
[class*="enterprise"],
.license-warning,
.upgrade-banner {
  display: none !important;
}

/* =============================================================================
 * FOOTER CLEANUP
 * ============================================================================= */

/* Clean footer styling */
footer {
  background-color: ${BG_SUBTLE} !important;
  border-top: 1px solid ${BORDER_COLOR} !important;
}

/* Only show legal links we want */
footer a[href*="bauer-group.com"],
footer a[href*="terms"],
footer a[href*="privacy"] {
  display: inline !important;
  color: ${TEXT_SECONDARY} !important;
}

footer a[href*="bauer-group.com"]:hover,
footer a[href*="terms"]:hover,
footer a[href*="privacy"]:hover {
  color: ${PRIMARY_COLOR} !important;
}
CSSEOF

echo "  Created custom.css with brand colors and hidden links"

# =============================================================================
# 5. Summary
# =============================================================================
echo -e "${BLUE}[5/5] Summary${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} V2 White-Label Branding Applied Successfully${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  App Name:      ${BRAND_APP_NAME:-PDF Toolbox [BAUER GROUP]}"
echo "  Company:       ${BRAND_COMPANY_NAME:-BAUER GROUP}"
echo "  Theme Color:   #FF8500 (BAUER GROUP Orange)"
echo ""
echo -e "${BLUE}Files Created:${NC}"
echo "  - $CSS_FILE"
echo "  - $CUSTOM_FILES_DIR/favicon.svg"
echo "  - $CUSTOM_FILES_DIR/modern-logo/*.svg"
echo ""
echo -e "${BLUE}Directory Contents:${NC}"
ls -la "$CUSTOM_FILES_DIR" 2>/dev/null || echo "  (directory listing failed)"
echo ""
echo -e "${BLUE}Modern Logo Contents:${NC}"
ls -la "$CUSTOM_FILES_DIR/modern-logo" 2>/dev/null || echo "  (directory listing failed)"
echo ""
echo -e "${YELLOW}NOTE: In V2, set app name via Admin UI → Settings${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
