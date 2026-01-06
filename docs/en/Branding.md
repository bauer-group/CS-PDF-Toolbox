# Branding & Customization

Documentation for customizing the appearance of PDF Toolbox.

> **Note:** This documentation applies to **Stirling PDF V2** (React frontend).
> V2 introduced significant changes to how branding works compared to V1.

## Branding Options

Stirling PDF V2 offers several levels of customization:

| Method | Effort | Restart Required |
|--------|--------|------------------|
| Environment variables | Low | Yes |
| custom_settings.yml | Low | Yes |
| Custom CSS | Medium | No (Hot-Reload) |
| Static assets (logos) | Medium | No |
| Whitelabel build | High | Yes (Rebuild) |

## V2 Branding Changes

**Important changes from V1 to V2:**

| V1 (deprecated) | V2 (current) | Notes |
|-----------------|--------------|-------|
| `UI_APP_NAME` | Admin UI / custom_settings.yml | No longer via env var |
| `UI_HOME_DESCRIPTION` | Admin UI / custom_settings.yml | No longer via env var |
| N/A | `UI_APPNAMENAVBAR` | Navbar text (env var works) |
| N/A | `UI_LOGOSTYLE` | `modern` or `classic` |
| `/customFiles/static/logo.svg` | `/customFiles/static/modern-logo/*.svg` | V2 logo structure |

## Environment Variables

### Available UI Variables (V2)

```bash
# .env
UI_APPNAMENAVBAR=PDF Toolbox [BAUER GROUP]
UI_LOGOSTYLE=modern
```

| Variable | Description |
|----------|-------------|
| `UI_APPNAMENAVBAR` | Text displayed in navbar |
| `UI_LOGOSTYLE` | Logo style: `modern` or `classic` |

> **Note:** `UI_APP_NAME` and `UI_HOME_DESCRIPTION` no longer work in V2.
> Use `custom_settings.yml` or the Admin UI instead.

### Legal Links

```bash
LEGAL_TERMSANDCONDITIONS=https://go.bauer-group.com/pdf-terms
LEGAL_PRIVACYPOLICY=https://go.bauer-group.com/pdf-privacy
LEGAL_IMPRESSUM=https://go.bauer-group.com/impressum
LEGAL_ACCESSIBILITYSTATEMENT=
LEGAL_COOKIEPOLICY=
```

## custom_settings.yml (V2)

For settings that can't be configured via environment variables, create `/configs/custom_settings.yml`:

```yaml
# /configs/custom_settings.yml
ui:
  appName: "PDF Toolbox [BAUER GROUP]"
  homeDescription: "Comprehensive PDF processing and conversion tools"
  appNameNavbar: "PDF Toolbox [BAUER GROUP]"
  logoStyle: "modern"
  showSocialIcons: false

system:
  defaultLocale: "en-GB"
  googleVisibility: false
  showUpdate: false
  showUpdateOnlyAdmin: true
  enableAnalytics: false

security:
  enableLogin: true
  csrfDisabled: false
```

**Settings priority (lowest to highest):**
1. `settings.yml` (regenerated on startup)
2. `custom_settings.yml` (preserved on updates)
3. Environment variables

## Custom CSS

For color adjustments and layout changes:

### Create CSS File

Create `/customFiles/static/custom.css`:

```css
:root {
  /* BAUER GROUP Primary Color (Orange) */
  --primary-color: #FF8500;
  --primary-color-hover: #EA6D00;
  --primary-color-light: #FFEDD5;
  --primary-color-dark: #C2570A;

  /* MUI/React overrides */
  --mui-palette-primary-main: #FF8500;
  --mui-palette-primary-light: #FFEDD5;
  --mui-palette-primary-dark: #C2570A;
}

/* Hide unwanted footer links */
footer a[href*="discord"],
footer a[href*="github.com/Stirling"],
a[href*="discord.gg"] {
  display: none !important;
}
```

### Volume Mount

```yaml
volumes:
  - './src/branding/assets/custom.css:/customFiles/static/custom.css:ro'
```

## Static Assets (V2 Logo Structure)

### V2 Logo Directory Structure

Stirling PDF V2 expects logos in a specific structure:

```text
/customFiles/static/
├── modern-logo/                      # For UI_LOGOSTYLE=modern
│   ├── StirlingPDFLogoBlackText.svg  # Light mode with text
│   ├── StirlingPDFLogoWhiteText.svg  # Dark mode with text
│   ├── StirlingPDFLogoGreyText.svg   # Grey variant
│   ├── StirlingPDFLogoNoTextLight.svg # Icon only (light bg)
│   ├── StirlingPDFLogoNoTextDark.svg  # Icon only (dark bg)
│   ├── logo-tooltip.svg              # Small tooltip icon
│   └── favicon.ico                   # Style-specific favicon
├── classic-logo/                     # For UI_LOGOSTYLE=classic
│   └── (same structure as modern-logo)
├── favicon.svg                       # Main favicon (SVG preferred)
├── favicon.ico                       # Fallback favicon
├── favicon-16x16.png
├── favicon-32x32.png
├── apple-touch-icon.png
└── custom.css                        # Custom styles
```

### Logo Source Files

For the whitelabel build, provide:

```text
src/branding/
├── logo-source-wide.svg    # Wide logo (with text) → copied to *Text.svg files
├── logo-source-square.svg  # Square logo (icon) → copied to *NoText*.svg files
└── assets/
    ├── favicon.ico
    ├── favicon-16x16.png
    ├── favicon-32x32.png
    └── apple-touch-icon.png
```

### Generate Assets

The project includes a script for generating all assets from source files:

```bash
# Place logo sources
# src/branding/logo-source-wide.svg (wide logo with text)
# src/branding/logo-source-square.svg (square icon)

# Generate assets
./tools/run.sh -s './scripts/generate-assets.sh'
```

## Whitelabel Build

For deep customizations, build a custom image with branding baked in:

### Build Command

```bash
# Build with branding (default)
docker build -t pdf-toolbox:latest ./src/

# Build without branding
docker build --build-arg INCLUDE_BRANDING=false -t pdf-toolbox:latest ./src/
```

### How Build-Time Branding Works

When `INCLUDE_BRANDING=true` (default):

1. **Patches** (`src/patches/`) are applied:
   - `001-skip-font-installation.sh` - Skip runtime font install (pre-installed)
   - `002-set-ui-settings.sh` - Creates `custom_settings.yml` with UI settings

2. **Translations** (`src/branding/apply-translations.sh`) are copied:
   - Custom `messages_*.properties` files to `/customFiles/translations/`

3. **Branding** (`src/branding/apply-branding.sh`) is applied:
   - V2 logo structure created in `/customFiles/static/modern-logo/`
   - Custom CSS generated with brand colors
   - Favicons copied

### Customizable Files

```text
src/
├── branding/
│   ├── branding.env           # Colors and app name for build
│   ├── apply-branding.sh      # V2 branding logic
│   ├── apply-translations.sh  # Translation file handling
│   ├── logo-source-wide.svg   # Wide logo source
│   ├── logo-source-square.svg # Square logo source
│   ├── translations/          # Custom .properties files
│   └── assets/                # Favicon assets
└── patches/
    ├── apply-patches.sh       # Patch orchestrator
    ├── 001-skip-font-installation.sh
    └── 002-set-ui-settings.sh
```

## branding.env

Configuration for build-time branding:

```bash
# src/branding/branding.env

# App identity (used by 002-set-ui-settings.sh)
BRAND_APP_NAME="PDF Toolbox [BAUER GROUP]"
BRAND_APP_DESCRIPTION="Comprehensive PDF processing and conversion tools"
BRAND_COMPANY_NAME="BAUER GROUP"
BRAND_COMPANY_SHORT="BG"

# BAUER GROUP Color System (used by apply-branding.sh for CSS)
BRAND_THEME_COLOR="#FF8500"
BRAND_ORANGE_100="#FFEDD5"
BRAND_ORANGE_500="#FF8500"
BRAND_ORANGE_600="#EA6D00"
BRAND_ORANGE_700="#C2570A"

# Text colors
BRAND_TEXT_PRIMARY="#18181B"
BRAND_TEXT_SECONDARY="#52525B"
BRAND_TEXT_MUTED="#71717A"

# Background colors
BRAND_BACKGROUND_COLOR="#FFFFFF"
BRAND_BACKGROUND_SUBTLE="#FAFAFA"
BRAND_BACKGROUND_MUTED="#F4F4F5"

# Border color
BRAND_BORDER="#E4E4E7"

# Semantic colors
BRAND_SUCCESS_500="#22C55E"
BRAND_WARNING_500="#EAB308"
BRAND_ERROR_500="#EF4444"
BRAND_INFO_500="#3B82F6"
```

## Directory Structure in Container

```text
/customFiles/
├── static/
│   ├── modern-logo/           # V2 logo files
│   │   ├── StirlingPDFLogoBlackText.svg
│   │   ├── StirlingPDFLogoWhiteText.svg
│   │   └── ...
│   ├── classic-logo/          # Alternative logo style
│   ├── favicon.svg            # Main favicon
│   ├── favicon.ico            # Fallback favicon
│   └── custom.css             # Custom styles
├── translations/              # Custom translation files
│   └── messages_en_GB.properties
└── signatures/                # User signature certificates

/configs/
├── settings.yml               # Base settings (regenerated)
└── custom_settings.yml        # Custom overrides (preserved)
```

## Custom Translations

### Create Translation File

```properties
# /customFiles/translations/messages_en_GB.properties
home.title=Welcome to PDF Toolbox
navbar.brand=PDF Toolbox
```

### Volume Mount

```yaml
volumes:
  - './translations/messages_en_GB.properties:/customFiles/translations/messages_en_GB.properties:ro'
```

## Best Practices

### Colors

1. **Consider contrast**: WCAG 2.1 AA (4.5:1 for text)
2. **Consistency**: Primary color in all elements
3. **Dark mode**: Test both modes

### Logos

1. **Prefer SVG**: Scales without quality loss
2. **Transparent background**: Suitable for all backgrounds
3. **Provide all variants**: V2 needs multiple logo files

### Performance

1. **Optimize assets**: Minify SVG, compress PNGs
2. **Caching**: Static assets are cached
3. **Use build-time branding**: Faster container startup

## Troubleshooting

### CSS Not Loading

```bash
# Check path
docker exec pdf_SERVER ls -la /customFiles/static/

# Check permissions
docker exec pdf_SERVER cat /customFiles/static/custom.css
```

### Logo Not Displayed

```bash
# Check V2 logo structure
docker exec pdf_SERVER ls -la /customFiles/static/modern-logo/

# Verify all required files exist
docker exec pdf_SERVER ls -la /customFiles/static/modern-logo/*.svg
```

### App Name Not Changing

In V2, `UI_APP_NAME` no longer works. Instead:

1. Check `custom_settings.yml` exists: `docker exec pdf_SERVER cat /configs/custom_settings.yml`
2. Or configure via Admin UI → Settings

### Changes Not Visible

1. Clear browser cache (Ctrl+Shift+R)
2. Restart container (for environment variables / settings changes)
3. Check volume mounts
4. Verify `UI_LOGOSTYLE` matches your logo directory

## Further Documentation

- [Installation](Installation.md)
- [Configuration](Configuration.md)
- [API Documentation](API.md)
