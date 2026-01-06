# Konfiguration

Umfassende Dokumentation aller Konfigurationsoptionen für PDF Toolbox.

## Umgebungsvariablen

Die Konfiguration erfolgt primär über Umgebungsvariablen in der `.env` Datei.

### Stack-Identifikation

```bash
# Eindeutiger Name für den Docker-Stack
STACK_NAME=pdf_app_bauer-group_com

# Image-Version: latest-fat (empfohlen), latest, latest-ultra-lite
STIRLING_VERSION=latest-fat

# Zeitzone
TIME_ZONE=Europe/Berlin
```

### Netzwerk

```bash
# Internes Subnetz (letztes Oktett)
PRIVATESUBNET=252

# Port für Entwicklung (ohne Reverse Proxy)
EXPOSED_APP_PORT=8080

# Traefik-Konfiguration
SERVICE_HOSTNAME=pdf.app.bauer-group.com
PROXY_NETWORK=EDGEPROXY
```

### System-Einstellungen

```bash
# Sprachen (alle verfügbaren aktiviert)
LANGS=en_GB,de_DE,fr_FR,es_ES,it_IT,pt_BR,zh_CN,ja_JP,ko_KR,ar_AR,bg_BG,ca_CA,cs_CZ,da_DK,el_GR,eu_ES,fa_IR,fi_FI,ga_IE,hi_IN,hr_HR,hu_HU,id_ID,nl_NL,no_NB,pl_PL,pt_PT,ro_RO,ru_RU,sk_SK,sl_SI,sr_LATN_RS,sv_SE,th_TH,tr_TR,uk_UA,vi_VN,zh_TW

# Standard-Sprache
SYSTEM_DEFAULT_LOCALE=en-GB

# Maximale Dateigröße in MB
SYSTEM_MAX_FILE_SIZE=2000

# Root-Pfad der Anwendung
SYSTEM_ROOT_URI_PATH=/

# Verbindungs-Timeout in Minuten
SYSTEM_CONNECTION_TIMEOUT_MINUTES=5
```

### UI-Branding

```bash
# Anwendungsname in Navbar und Titel
UI_APP_NAME=PDF Toolbox [BAUER GROUP]

# Beschreibung auf der Startseite
UI_HOME_DESCRIPTION=Comprehensive PDF processing and conversion tools
```

### Sichtbarkeit & Updates

```bash
# Für Suchmaschinen ausblenden
SYSTEM_GOOGLE_VISIBILITY=false

# Update-Benachrichtigungen
SYSTEM_SHOW_UPDATE=false
SYSTEM_SHOW_UPDATE_ONLY_ADMIN=true
```

### Analytics & Telemetrie

```bash
# Master-Schalter für alle Analytics (PostHog + Scarf)
SYSTEM_ENABLE_ANALYTICS=false
```

### Sicherheit

Siehe [Sicherheit & Login](Sicherheit.md) für detaillierte Konfiguration.

```bash
# Login aktivieren (empfohlen für Produktion)
SECURITY_ENABLE_LOGIN=true

# Initiale Admin-Zugangsdaten
SECURITY_INITIAL_LOGIN_USERNAME=admin
SECURITY_INITIAL_LOGIN_PASSWORD=  # Von generate-secrets.sh generiert

# CSRF-Schutz (niemals in Produktion deaktivieren!)
SECURITY_CSRF_DISABLED=false
```

### Legal-Links (Footer)

```bash
LEGAL_TERMS_URL=https://go.bauer-group.com/pdf-terms
LEGAL_PRIVACY_URL=https://go.bauer-group.com/pdf-privacy
LEGAL_IMPRESSUM_URL=
```

### OCR-Einstellungen

```bash
# Standard OCR-Sprache (ISO 639-3)
OCR_DEFAULT_LANGUAGE=eng
```

Verfügbare Sprachen im `latest-fat` Image:

| Code | Sprache |
|------|---------|
| `eng` | Englisch |
| `deu` | Deutsch |
| `fra` | Französisch |
| `spa` | Spanisch |
| `ita` | Italienisch |

### Endpoint-Anpassung

```bash
# Bestimmte Tools deaktivieren (kommagetrennte Tool-IDs)
ENDPOINTS_TO_REMOVE=

# Tool-Gruppen deaktivieren
ENDPOINTS_GROUPS_TO_REMOVE=
```

Verfügbare Gruppen:

- `LibreOffice` - Office-Konvertierungen
- `Python` - Python-basierte Tools
- `OpenCV` - Bildverarbeitung
- `OCRmyPDF` - OCR-Funktionen
- `Weasyprint` - HTML zu PDF
- `Calibre` - E-Book-Konvertierung
- `QPDF` - PDF-Manipulation
- `Ghostscript` - PostScript/PDF-Verarbeitung

### SMTP-Einstellungen

```bash
MAIL_ENABLED=false
MAIL_HOST=mx1.simply-send.com
MAIL_PORT=587
MAIL_USERNAME=no-reply@message.bauer-group.com
MAIL_PASSWORD=CHANGE_ME_SMTP_PASSWORD
MAIL_TLS_ENABLED=true
MAIL_FROM=no-reply@message.bauer-group.com
```

### Logging

```bash
# Log-Level: TRACE, DEBUG, INFO, WARN, ERROR
LOGGING_LEVEL=INFO

# OAuth-Debugging
# LOGGING_LEVEL_ORG_SPRINGFRAMEWORK_SECURITY_OAUTH2=DEBUG
```

## Konfigurationsdateien

### settings.yml

Die Hauptkonfiguration in `/configs/settings.yml`:

```yaml
security:
  enableLogin: true
  csrfDisabled: false
  loginMethod: all

system:
  defaultLocale: en-GB
  googleVisibility: false
  showUpdate: false
  enableAnalytics: false

ui:
  appName: "PDF Toolbox [BAUER GROUP]"
  homeDescription: "Comprehensive PDF processing and conversion tools"
```

### custom_settings.yml

Benutzerdefinierte Einstellungen in `/configs/custom_settings.yml`:

```yaml
# Diese Datei überschreibt settings.yml
ui:
  appName: "Mein PDF Tool"
```

## Resource-Limits

### Nach Benutzerzahl

| Benutzer | Memory | CPUs |
|----------|--------|------|
| 5-20 | 4 GB | 2.0 |
| 20-100 | 8 GB | 4.0 |
| 100+ | 16 GB | 8.0 |

### Docker Compose Konfiguration

```yaml
deploy:
  resources:
    limits:
      memory: 8G
      cpus: '4.0'
    reservations:
      memory: 4G
      cpus: '2.0'
```

## Zugriffspunkte

| Umgebung | URL |
|----------|-----|
| Entwicklung | <http://localhost:8080> |
| Produktion | <https://pdf.app.bauer-group.com> |
| API-Dokumentation | <https://pdf.app.bauer-group.com/swagger-ui/index.html> |
| Health-Check | <https://pdf.app.bauer-group.com/api/v1/info/status> |

## Weiterführende Dokumentation

- [Installation](Installation.md)
- [Sicherheit & Login](Sicherheit.md)
- [PDF-Signatur](PDF-Signatur.md)
- [API-Dokumentation](API.md)
