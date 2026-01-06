# =============================================================================
# Stirling PDF - BAUER GROUP Edition
# Custom image with branding and all OCR languages
# =============================================================================
#
# This Dockerfile builds a customized Stirling PDF image with:
# - All available OCR/Tesseract language packs
# - Build-time branding support (INCLUDE_BRANDING=true)
# - BAUER GROUP configuration defaults
#
# USAGE:
#   docker build -t pdf-toolbox .
#   docker build --build-arg INCLUDE_BRANDING=true -t pdf-toolbox .
#
# See: https://docs.stirlingpdf.com/Installation/Docker%20Install/
#
# =============================================================================

ARG STIRLING_VERSION=latest-fat
FROM stirlingtools/stirling-pdf:${STIRLING_VERSION}

# Re-declare ARGs after FROM to use them
ARG STIRLING_VERSION
ARG INCLUDE_BRANDING=true

# =============================================================================
# Custom Labels
# =============================================================================

# Metadata
LABEL vendor="BAUER GROUP"
LABEL maintainer="Karl Bauer <karl.bauer@bauer-group.com>"

# Opencontainers Metadata
LABEL org.opencontainers.image.title="PDF-Toolbox"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="BAUER GROUP"
LABEL org.opencontainers.image.authors="Karl Bauer <karl.bauer@bauer-group.com>"
LABEL org.opencontainers.image.source="https://github.com/bauer-group/CS-PDF-Toolbox"
LABEL org.opencontainers.image.url="https://github.com/bauer-group/CS-PDF-Toolbox"
LABEL org.opencontainers.image.documentation="https://github.com/bauer-group/CS-PDF-Toolbox#readme"
LABEL org.opencontainers.image.description="Stirling PDF - BAUER GROUP Edition with all OCR languages"
LABEL org.opencontainers.image.version="0.0.1"

# Extended Labels
LABEL org.opencontainers.image.base.name="stirlingtools/stirling-pdf:${STIRLING_VERSION}"
LABEL com.bauer-group.stirling.version="${STIRLING_VERSION}"

# =============================================================================
# Install Tesseract OCR Language Packs
# =============================================================================
# We install all commonly used business languages for international documents.
# Base image languages (eng, deu, fra, por, chi_sim) are reinstalled to get updates.
#
# Note: APK packages install .traineddata files to /usr/share/tessdata/
# which is the path Stirling PDF scans for available languages.
#
# Historical/old script variants (ita_old, spa_old, frk, grc, enm, frm, kat_old)
# are excluded as they're rarely needed in business contexts.

USER root

# Install commonly used business languages (adds ~200MB)
# Grouped by region:
#   Base (reinstall for updates): eng, deu, fra, por, chi_sim
#   Western Europe: nld, ita, spa, cat
#   Nordic: dan, fin, nor, swe
#   Eastern Europe: ces, hun, pol, ron, rus, slk, slv, ukr, bul, hrv, srp
#   Mediterranean: tur
#   Asia: chi_tra, jpn, kor, tha, vie, ind, msa
#   South Asia: hin, ben, tam, tel
#   Middle East: ara, heb
#   Baltic: lav, lit, est
#
# Not available in Alpine: fas (Farsi), gle (Irish), srp_latn (Serbian Latin), ell/gre (Greek)
RUN apk add --no-cache \
    tesseract-ocr-data-eng \
    tesseract-ocr-data-deu \
    tesseract-ocr-data-fra \
    tesseract-ocr-data-por \
    tesseract-ocr-data-chi_sim \
    tesseract-ocr-data-nld \
    tesseract-ocr-data-ita \
    tesseract-ocr-data-spa \
    tesseract-ocr-data-cat \
    tesseract-ocr-data-dan \
    tesseract-ocr-data-fin \
    tesseract-ocr-data-nor \
    tesseract-ocr-data-swe \
    tesseract-ocr-data-ces \
    tesseract-ocr-data-hun \
    tesseract-ocr-data-pol \
    tesseract-ocr-data-ron \
    tesseract-ocr-data-rus \
    tesseract-ocr-data-slk \
    tesseract-ocr-data-slv \
    tesseract-ocr-data-ukr \
    tesseract-ocr-data-bul \
    tesseract-ocr-data-hrv \
    tesseract-ocr-data-srp \
    tesseract-ocr-data-tur \
    tesseract-ocr-data-chi_tra \
    tesseract-ocr-data-jpn \
    tesseract-ocr-data-kor \
    tesseract-ocr-data-tha \
    tesseract-ocr-data-vie \
    tesseract-ocr-data-ind \
    tesseract-ocr-data-msa \
    tesseract-ocr-data-hin \
    tesseract-ocr-data-ben \
    tesseract-ocr-data-tam \
    tesseract-ocr-data-tel \
    tesseract-ocr-data-ara \
    tesseract-ocr-data-heb \
    tesseract-ocr-data-lav \
    tesseract-ocr-data-lit \
    tesseract-ocr-data-est

# Verify tessdata directory has the expected files
RUN ls -la /usr/share/tessdata/*.traineddata 2>/dev/null | wc -l | xargs -I {} echo "Installed {} OCR language packs"

# =============================================================================
# Install Fonts at Build-Time (faster container startup)
# =============================================================================
# These fonts are normally installed at runtime by installFonts.sh, but
# pre-installing them significantly speeds up container startup time.
# The init script still runs apk but finds packages already installed.
#
# Source: https://github.com/Stirling-Tools/Stirling-PDF/blob/main/scripts/installFonts.sh
RUN apk add --no-cache \
    font-terminus \
    font-dejavu \
    font-noto \
    font-noto-cjk \
    font-awesome \
    font-noto-extra \
    font-noto-arabic \
    font-noto-thai \
    font-noto-tibetan \
    font-noto-devanagari \
    font-noto-hebrew \
    font-noto-tamil \
    font-noto-telugu \
    font-noto-bengali \
    font-vollkorn \
    font-misc-cyrillic \
    font-mutt-misc \
    font-screen-cyrillic \
    font-winitzki-cyrillic \
    font-cronyx-cyrillic \
    font-isas-misc \
    font-ipa \
    font-sony-misc \
    font-jis-misc \
    && fc-cache -f

# =============================================================================
# Custom Entrypoint (Base64 certificate support)
# =============================================================================
# Our entrypoint wraps the original init.sh to decode KEYSTORE_P12_BASE64

COPY scripts/entrypoint.sh /scripts/custom-entrypoint.sh
RUN chmod +x /scripts/custom-entrypoint.sh

# =============================================================================
# Build-time Branding (optional) - V2 Compatible
# =============================================================================
# When INCLUDE_BRANDING=true (default), branding assets are baked into image.
#
# IMPORTANT: Branding files are stored in /branding-template/ at build time,
# then copied to /customFiles/ at runtime by the entrypoint script.
# This is necessary because /customFiles is typically mounted as a volume,
# which would otherwise overwrite the image files with an empty directory.

COPY branding/ /tmp/branding/
COPY patches/ /tmp/patches/

RUN if [ "$INCLUDE_BRANDING" = "true" ]; then \
        echo "Applying build-time branding (V2)..."; \
        chmod +x /tmp/branding/*.sh /tmp/patches/*.sh 2>/dev/null || true; \
        # Create branding template directory (will be copied to /customFiles and /configs at runtime)
        # This is necessary because /customFiles and /configs are mounted as volumes
        mkdir -p /branding-template/static/modern-logo /branding-template/static/classic-logo /branding-template/translations /branding-template/configs; \
        # Apply patches (patches that modify /scripts/ and create custom_settings.yml in branding-template)
        if [ -f /tmp/patches/apply-patches.sh ]; then \
            PATCHES_DIR=/tmp/patches STIRLING_DIR=/configs BRANDING_DIR=/tmp/branding CONFIGS_DIR=/branding-template/configs /tmp/patches/apply-patches.sh || true; \
        fi; \
        # Apply translations (output to branding-template)
        if [ -f /tmp/branding/apply-translations.sh ]; then \
            BRANDING_DIR=/tmp/branding CUSTOM_FILES_DIR=/branding-template /tmp/branding/apply-translations.sh || true; \
        fi; \
        # Apply branding (V2 logo structure, CSS) to branding-template
        if [ -f /tmp/branding/apply-branding.sh ]; then \
            BRANDING_DIR=/tmp/branding CUSTOM_FILES_DIR=/branding-template/static /tmp/branding/apply-branding.sh || true; \
        fi; \
        # Verify branding was applied
        echo ""; \
        echo "=== Checking branding template files ==="; \
        ls -la /branding-template/static/ 2>/dev/null || echo "  branding-template/static not found"; \
        ls -la /branding-template/static/modern-logo/ 2>/dev/null || echo "  modern-logo not found"; \
        echo ""; \
        echo "=== Checking custom_settings.yml (in branding-template) ==="; \
        cat /branding-template/configs/custom_settings.yml 2>/dev/null || echo "  custom_settings.yml not found"; \
        echo ""; \
        echo "Build-time branding prepared in /branding-template/"; \
        echo "Branding will be copied to /customFiles/ and /configs/ at container startup."; \
    else \
        echo "Branding disabled - mount assets via volumes if needed."; \
    fi && \
    rm -rf /tmp/branding /tmp/patches

# Note: Do NOT set USER here - the base image entrypoint (init.sh) handles
# user switching after installing fonts/tessdata at runtime as root.

# =============================================================================
# Environment Defaults (V2)
# =============================================================================
# These are the BAUER GROUP defaults for this custom image.
# All can be overridden via docker-compose environment or .env file.
#
# Note: In V2, appName and homeDescription are set via custom_settings.yml (patch 002)
# and can be adjusted via Admin UI. UI_APPNAMENAVBAR still works as env var.

# -- Analytics: Disabled by default --
ENV SYSTEM_ENABLEANALYTICS=false

# -- UI Branding (V2) --
# UI_APPNAMENAVBAR controls the navbar text
ENV UI_APPNAMENAVBAR="PDF Toolbox [BAUER GROUP]"
# UI_LOGOSTYLE determines which logo directory is used (modern or classic)
ENV UI_LOGOSTYLE=modern

# -- Security Defaults --
ENV SECURITY_CSRF_DISABLED=false

# -- Visibility --
ENV SYSTEM_GOOGLEVISIBILITY=false
ENV SYSTEM_SHOWUPDATE=false
ENV SYSTEM_SHOWUPDATEONLYADMIN=true

# =============================================================================
# Health Check
# =============================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/api/v1/info/status || exit 1

# =============================================================================
# Custom Entrypoint (overrides original)
# =============================================================================
# Our entrypoint handles Base64 certificate decoding before calling original init
# The CMD is passed through to init.sh which uses it with su-exec
ENTRYPOINT ["tini", "--", "/scripts/custom-entrypoint.sh"]
CMD ["sh", "-c", "java -Dfile.encoding=UTF-8 -Djava.io.tmpdir=/tmp/stirling-pdf -jar /app.jar & /opt/venv/bin/unoserver --port 2003 --interface 127.0.0.1"]
