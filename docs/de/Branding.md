# Branding & Anpassungen

Dokumentation zur Anpassung des Erscheinungsbilds von PDF Toolbox.

> **Hinweis:** Diese Dokumentation gilt für **Stirling PDF V2** (React-Frontend).
> V2 hat wesentliche Änderungen am Branding-System gegenüber V1 eingeführt.

## Branding-Optionen

Stirling PDF V2 bietet mehrere Ebenen der Anpassung:

| Methode | Aufwand | Neustart erforderlich |
|---------|---------|----------------------|
| Umgebungsvariablen | Gering | Ja |
| custom_settings.yml | Gering | Ja |
| Custom CSS | Mittel | Nein (Hot-Reload) |
| Statische Assets (Logos) | Mittel | Nein |
| Whitelabel-Build | Hoch | Ja (Rebuild) |

## V2 Branding-Änderungen

**Wichtige Änderungen von V1 zu V2:**

| V1 (veraltet) | V2 (aktuell) | Hinweise |
|---------------|--------------|----------|
| `UI_APP_NAME` | Admin UI / custom_settings.yml | Nicht mehr via Env-Var |
| `UI_HOME_DESCRIPTION` | Admin UI / custom_settings.yml | Nicht mehr via Env-Var |
| N/A | `UI_APPNAMENAVBAR` | Navbar-Text (Env-Var funktioniert) |
| N/A | `UI_LOGOSTYLE` | `modern` oder `classic` |
| `/customFiles/static/logo.svg` | `/customFiles/static/modern-logo/*.svg` | V2 Logo-Struktur |

## Umgebungsvariablen

### Verfügbare UI-Variablen (V2)

```bash
# .env
UI_APPNAMENAVBAR=PDF Toolbox [BAUER GROUP]
UI_LOGOSTYLE=modern
```

| Variable | Beschreibung |
|----------|--------------|
| `UI_APPNAMENAVBAR` | Text in der Navigationsleiste |
| `UI_LOGOSTYLE` | Logo-Stil: `modern` oder `classic` |

> **Hinweis:** `UI_APP_NAME` und `UI_HOME_DESCRIPTION` funktionieren in V2 nicht mehr.
> Verwenden Sie stattdessen `custom_settings.yml` oder die Admin-Oberfläche.

### Legal-Links

```bash
LEGAL_TERMSANDCONDITIONS=https://go.bauer-group.com/pdf-terms
LEGAL_PRIVACYPOLICY=https://go.bauer-group.com/pdf-privacy
LEGAL_IMPRESSUM=https://go.bauer-group.com/impressum
LEGAL_ACCESSIBILITYSTATEMENT=
LEGAL_COOKIEPOLICY=
```

## custom_settings.yml (V2)

Für Einstellungen, die nicht über Umgebungsvariablen konfiguriert werden können, erstellen Sie `/configs/custom_settings.yml`:

```yaml
# /configs/custom_settings.yml
ui:
  appName: "PDF Toolbox [BAUER GROUP]"
  homeDescription: "Umfassende PDF-Verarbeitungs- und Konvertierungswerkzeuge"
  appNameNavbar: "PDF Toolbox [BAUER GROUP]"
  logoStyle: "modern"
  showSocialIcons: false

system:
  defaultLocale: "de-DE"
  googleVisibility: false
  showUpdate: false
  showUpdateOnlyAdmin: true
  enableAnalytics: false

security:
  enableLogin: true
  csrfDisabled: false
```

**Einstellungspriorität (niedrigste bis höchste):**

1. `settings.yml` (wird beim Start regeneriert)
2. `custom_settings.yml` (bleibt bei Updates erhalten)
3. Umgebungsvariablen

## Custom CSS

Für Farbanpassungen und Layout-Änderungen:

### CSS-Datei erstellen

Erstellen Sie `/customFiles/static/custom.css`:

```css
:root {
  /* BAUER GROUP Primärfarbe (Orange) */
  --primary-color: #FF8500;
  --primary-color-hover: #EA6D00;
  --primary-color-light: #FFEDD5;
  --primary-color-dark: #C2570A;

  /* MUI/React Überschreibungen */
  --mui-palette-primary-main: #FF8500;
  --mui-palette-primary-light: #FFEDD5;
  --mui-palette-primary-dark: #C2570A;
}

/* Unerwünschte Footer-Links ausblenden */
footer a[href*="discord"],
footer a[href*="github.com/Stirling"],
a[href*="discord.gg"] {
  display: none !important;
}
```

### Volume-Mount

```yaml
volumes:
  - './src/branding/assets/custom.css:/customFiles/static/custom.css:ro'
```

## Statische Assets (V2 Logo-Struktur)

### V2 Logo-Verzeichnisstruktur

Stirling PDF V2 erwartet Logos in einer spezifischen Struktur:

```text
/customFiles/static/
├── modern-logo/                      # Für UI_LOGOSTYLE=modern
│   ├── StirlingPDFLogoBlackText.svg  # Heller Modus mit Text
│   ├── StirlingPDFLogoWhiteText.svg  # Dunkler Modus mit Text
│   ├── StirlingPDFLogoGreyText.svg   # Graue Variante
│   ├── StirlingPDFLogoNoTextLight.svg # Nur Icon (heller Hintergrund)
│   ├── StirlingPDFLogoNoTextDark.svg  # Nur Icon (dunkler Hintergrund)
│   ├── logo-tooltip.svg              # Kleines Tooltip-Icon
│   └── favicon.ico                   # Stil-spezifisches Favicon
├── classic-logo/                     # Für UI_LOGOSTYLE=classic
│   └── (gleiche Struktur wie modern-logo)
├── favicon.svg                       # Haupt-Favicon (SVG bevorzugt)
├── favicon.ico                       # Fallback-Favicon
├── favicon-16x16.png
├── favicon-32x32.png
├── apple-touch-icon.png
└── custom.css                        # Custom Styles
```

### Logo-Quelldateien

Für den Whitelabel-Build stellen Sie bereit:

```text
src/branding/
├── logo-source-wide.svg    # Breites Logo (mit Text) → kopiert zu *Text.svg
├── logo-source-square.svg  # Quadratisches Logo (Icon) → kopiert zu *NoText*.svg
└── assets/
    ├── favicon.ico
    ├── favicon-16x16.png
    ├── favicon-32x32.png
    └── apple-touch-icon.png
```

### Assets generieren

Das Projekt enthält ein Script zur Generierung aller Assets aus Quelldateien:

```bash
# Logo-Quellen platzieren
# src/branding/logo-source-wide.svg (breites Logo mit Text)
# src/branding/logo-source-square.svg (quadratisches Icon)

# Assets generieren
./tools/run.sh -s './scripts/generate-assets.sh'
```

## Whitelabel-Build

Für tiefgreifende Anpassungen können Sie ein eigenes Image mit integriertem Branding bauen:

### Build-Befehl

```bash
# Mit Branding bauen (Standard)
docker build -t pdf-toolbox:latest ./src/

# Ohne Branding bauen
docker build --build-arg INCLUDE_BRANDING=false -t pdf-toolbox:latest ./src/
```

### Wie Build-Zeit-Branding funktioniert

Wenn `INCLUDE_BRANDING=true` (Standard):

1. **Patches** (`src/patches/`) werden angewendet:
   - `001-skip-font-installation.sh` - Überspringt Laufzeit-Font-Installation (vorinstalliert)
   - `002-set-ui-settings.sh` - Erstellt `custom_settings.yml` mit UI-Einstellungen

2. **Übersetzungen** (`src/branding/apply-translations.sh`) werden kopiert:
   - Eigene `messages_*.properties` Dateien nach `/customFiles/translations/`

3. **Branding** (`src/branding/apply-branding.sh`) wird angewendet:
   - V2 Logo-Struktur wird in `/customFiles/static/modern-logo/` erstellt
   - Custom CSS wird mit Markenfarben generiert
   - Favicons werden kopiert

### Anpassbare Dateien

```text
src/
├── branding/
│   ├── branding.env           # Farben und App-Name für Build
│   ├── apply-branding.sh      # V2 Branding-Logik
│   ├── apply-translations.sh  # Übersetzungsdatei-Handling
│   ├── logo-source-wide.svg   # Breites Logo-Quelle
│   ├── logo-source-square.svg # Quadratische Logo-Quelle
│   ├── translations/          # Eigene .properties Dateien
│   └── assets/                # Favicon-Assets
└── patches/
    ├── apply-patches.sh       # Patch-Orchestrator
    ├── 001-skip-font-installation.sh
    └── 002-set-ui-settings.sh
```

## branding.env

Konfiguration für Build-Zeit-Branding:

```bash
# src/branding/branding.env

# App-Identität (verwendet von 002-set-ui-settings.sh)
BRAND_APP_NAME="PDF Toolbox [BAUER GROUP]"
BRAND_APP_DESCRIPTION="Umfassende PDF-Verarbeitungs- und Konvertierungswerkzeuge"
BRAND_COMPANY_NAME="BAUER GROUP"
BRAND_COMPANY_SHORT="BG"

# BAUER GROUP Farbsystem (verwendet von apply-branding.sh für CSS)
BRAND_THEME_COLOR="#FF8500"
BRAND_ORANGE_100="#FFEDD5"
BRAND_ORANGE_500="#FF8500"
BRAND_ORANGE_600="#EA6D00"
BRAND_ORANGE_700="#C2570A"

# Textfarben
BRAND_TEXT_PRIMARY="#18181B"
BRAND_TEXT_SECONDARY="#52525B"
BRAND_TEXT_MUTED="#71717A"

# Hintergrundfarben
BRAND_BACKGROUND_COLOR="#FFFFFF"
BRAND_BACKGROUND_SUBTLE="#FAFAFA"
BRAND_BACKGROUND_MUTED="#F4F4F5"

# Rahmenfarbe
BRAND_BORDER="#E4E4E7"

# Semantische Farben
BRAND_SUCCESS_500="#22C55E"
BRAND_WARNING_500="#EAB308"
BRAND_ERROR_500="#EF4444"
BRAND_INFO_500="#3B82F6"
```

## Verzeichnisstruktur im Container

```text
/customFiles/
├── static/
│   ├── modern-logo/           # V2 Logo-Dateien
│   │   ├── StirlingPDFLogoBlackText.svg
│   │   ├── StirlingPDFLogoWhiteText.svg
│   │   └── ...
│   ├── classic-logo/          # Alternativer Logo-Stil
│   ├── favicon.svg            # Haupt-Favicon
│   ├── favicon.ico            # Fallback-Favicon
│   └── custom.css             # Custom Styles
├── translations/              # Eigene Übersetzungsdateien
│   └── messages_de_DE.properties
└── signatures/                # Benutzer-Signatur-Zertifikate

/configs/
├── settings.yml               # Basis-Einstellungen (regeneriert)
└── custom_settings.yml        # Eigene Überschreibungen (bleibt erhalten)
```

## Eigene Übersetzungen

### Übersetzungsdatei erstellen

```properties
# /customFiles/translations/messages_de_DE.properties
home.title=Willkommen bei PDF Toolbox
navbar.brand=PDF Toolbox
```

### Volume-Mount

```yaml
volumes:
  - './translations/messages_de_DE.properties:/customFiles/translations/messages_de_DE.properties:ro'
```

## Best Practices

### Farben

1. **Kontrast beachten**: WCAG 2.1 AA (4.5:1 für Text)
2. **Konsistenz**: Primärfarbe in allen Elementen
3. **Dark Mode**: Beide Modi testen

### Logos

1. **SVG bevorzugen**: Skaliert ohne Qualitätsverlust
2. **Transparenter Hintergrund**: Für alle Hintergründe geeignet
3. **Alle Varianten bereitstellen**: V2 benötigt mehrere Logo-Dateien

### Performance

1. **Assets optimieren**: SVG minifizieren, PNGs komprimieren
2. **Caching**: Statische Assets werden gecacht
3. **Build-Zeit-Branding verwenden**: Schnellerer Container-Start

## Troubleshooting

### CSS wird nicht geladen

```bash
# Pfad prüfen
docker exec pdf_SERVER ls -la /customFiles/static/

# Berechtigungen prüfen
docker exec pdf_SERVER cat /customFiles/static/custom.css
```

### Logo wird nicht angezeigt

```bash
# V2 Logo-Struktur prüfen
docker exec pdf_SERVER ls -la /customFiles/static/modern-logo/

# Alle erforderlichen Dateien prüfen
docker exec pdf_SERVER ls -la /customFiles/static/modern-logo/*.svg
```

### App-Name ändert sich nicht

In V2 funktioniert `UI_APP_NAME` nicht mehr. Stattdessen:

1. Prüfen ob `custom_settings.yml` existiert: `docker exec pdf_SERVER cat /configs/custom_settings.yml`
2. Oder über Admin UI → Einstellungen konfigurieren

### Änderungen nicht sichtbar

1. Browser-Cache leeren (Ctrl+Shift+R)
2. Container neu starten (bei Umgebungsvariablen / Einstellungsänderungen)
3. Volume-Mounts prüfen
4. `UI_LOGOSTYLE` mit Logo-Verzeichnis abgleichen

## Weiterführende Dokumentation

- [Installation](Installation.md)
- [Konfiguration](Konfiguration.md)
- [API-Dokumentation](API.md)
