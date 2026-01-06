#!/bin/bash
###############################################################################
# Patch: Skip Font Installation at Runtime
#
# The original installFonts.sh script runs at container startup and tries to
# install fonts via apk, even if they're already installed. This causes:
#   - Slow startup (fetches APK index from 5 repos)
#   - Network traffic on every container start
#
# This patch replaces installFonts.sh with a no-op script since we pre-install
# all fonts at build-time in the Dockerfile.
#
# Note: This patch modifies /scripts/ directly (not STIRLING_DIR which is /configs/)
###############################################################################

echo "Patching installFonts.sh to skip runtime font installation..."

# Check if the script exists
if [ ! -f /scripts/installFonts.sh ]; then
    echo "Warning: /scripts/installFonts.sh not found, skipping patch"
    exit 0
fi

# Create a no-op script that just logs and exits
cat > /scripts/installFonts.sh << 'EOF'
#!/bin/bash
# =============================================================================
# installFonts.sh - PATCHED by PDF Toolbox
# =============================================================================
# This script has been patched to skip font installation at runtime.
# All fonts are pre-installed at build-time in the Dockerfile for faster startup.
#
# Original behavior: Iterates through LANGS and installs fonts via apk
# Patched behavior: Logs a message and exits successfully
# =============================================================================

echo "[PDF Toolbox] Fonts pre-installed at build-time, skipping runtime installation."
exit 0
EOF

chmod +x /scripts/installFonts.sh
echo "Successfully patched installFonts.sh"
