# PDF Toolbox (Stirling PDF)

> **[English Version](README.md)**

Docker Compose Deployment für [Stirling PDF](https://stirlingpdf.com) mit Custom Branding, Traefik-Integration und Zertifikat-basierter PDF-Signierung.

## Features

- **Custom Branding** (Logo, Favicon, App-Name)
- Custom Docker Image mit vorinstallierten OCR-Sprachen
- Traefik Integration mit Let's Encrypt
- PDF-Signatur mit Server-Zertifikat (Base64 Environment Variable)
- OAuth/OIDC Support (optional)
- Coolify-kompatibel

## Schnellstart

### 1. Repository klonen

```bash
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox
```

### 2. Tools-Container starten

```bash
# Windows
.\tools\run.ps1
# Linux/macOS
./tools/run.sh
```

### 3. Secrets generieren

```bash
# Im Tools-Container:
./scripts/generate-secrets.sh
```

> **Hinweis:** Das Script erstellt automatisch `.env` aus `.env.example` und generiert ein sicheres Admin-Passwort.

### 4. .env anpassen (optional)

```bash
# .env bearbeiten für individuelle Einstellungen
nano .env
```

### 5. Branding anpassen (optional)

Logos in `src/branding/` ablegen:

- `logo.png` (Logo für Navbar)
- `favicon.png` (Browser-Tab Icon)

```bash
# Im Tools-Container:
./scripts/generate-assets.sh
```

Siehe [Branding Dokumentation](docs/de/Branding.md) für Details.

### 6. Signing-Zertifikat erstellen (optional)

```bash
# Im Tools-Container:
./scripts/generate-cert.sh

# Oder für CA-signierte Zertifikate:
./scripts/ca-cert-workflow.sh
```

> **Hinweis:** Das Script schreibt `KEYSTORE_PASSWORD` und `KEYSTORE_P12_BASE64` automatisch in `.env`. Der Container dekodiert das Zertifikat beim Start.

Siehe [PDF-Signatur Dokumentation](docs/de/PDF-Signatur.md) für Details.

### 7. Starten

```bash
# Entwicklung (http://localhost:8080)
docker compose -f docker-compose.development.yml up -d --build

# Produktion mit Traefik
docker compose -f docker-compose.traefik.yml up -d --build

# Coolify
docker compose -f docker-compose.coolify.yml up -d --build
```

## Zugriff

| Umgebung | URL |
|----------|-----|
| Entwicklung | http://localhost:8080 |
| Produktion | https://pdf.app.bauer-group.com |
| API Docs | /swagger-ui/index.html |
| Health | /api/v1/info/status |

## Dokumentation

| Dokument | Beschreibung |
|----------|--------------|
| [Installation](docs/de/Installation.md) | Deployment & Schnellstart |
| [Konfiguration](docs/de/Konfiguration.md) | Umgebungsvariablen |
| [Sicherheit](docs/de/Sicherheit.md) | Login & OAuth |
| [PDF-Signatur](docs/de/PDF-Signatur.md) | Digitale Signaturen |
| [Branding](docs/de/Branding.md) | Custom Branding |
| [API](docs/de/API.md) | REST-API |

## Verzeichnisstruktur

```
.
├── docker-compose.yml              # Alias für development
├── docker-compose.development.yml  # Entwicklung (mit Ports)
├── docker-compose.traefik.yml      # Produktion (mit Traefik)
├── docker-compose.coolify.yml      # Coolify PaaS
├── .env.example                    # Beispiel-Konfiguration
├── certs/                          # Signing-Zertifikate (gitignored)
├── docs/
│   ├── en/                         # Englische Dokumentation
│   └── de/                         # Deutsche Dokumentation
├── scripts/
│   ├── generate-assets.sh          # Branding-Assets generieren
│   ├── generate-cert.sh            # Zertifikat generieren
│   ├── generate-secrets.sh         # Secrets generieren
│   ├── ca-cert-workflow.sh         # CA-Zertifikat Workflow
│   └── convert-to-p12.sh           # PEM zu P12 konvertieren
├── tools/                          # Development Tools Container
│   ├── run.sh / run.cmd / run.ps1
│   └── Dockerfile
└── src/
    ├── branding/                   # Custom Branding Assets
    │   ├── logo.png
    │   └── favicon.png
    ├── scripts/
    │   └── entrypoint.sh           # Custom Entrypoint (Base64 Cert)
    └── Dockerfile                  # Custom Image
```

## Tools Container

Der Tools-Container enthält ImageMagick, OpenSSL und alle benötigten Werkzeuge:

```bash
# Starten (baut automatisch wenn nötig)
.\tools\run.ps1        # Windows PowerShell
.\tools\run.cmd        # Windows CMD
./tools/run.sh         # Linux/macOS

# Force Rebuild
.\tools\run.ps1 -Build
./tools/run.sh --build

# Script direkt ausführen
./tools/run.sh -s './scripts/generate-cert.sh'
```

## Befehle

```bash
# Starten (Entwicklung)
docker compose -f docker-compose.development.yml up -d --build

# Starten (Produktion mit Traefik)
docker compose -f docker-compose.traefik.yml up -d --build

# Logs
docker compose -f docker-compose.development.yml logs -f stirling-pdf

# Container Status
docker compose -f docker-compose.development.yml ps

# Stoppen
docker compose -f docker-compose.development.yml down

# Rebuild ohne Cache
docker compose -f docker-compose.development.yml build --no-cache
```

## Lizenz

Dieses Deployment-Projekt steht unter der MIT-Lizenz.
Stirling PDF verwendet ein Open-Core-Modell mit MIT-Lizenz.

## Offizielle Dokumentation

- [Stirling PDF Docs](https://docs.stirlingpdf.com)
- [GitHub Repository](https://github.com/Stirling-Tools/Stirling-PDF)
- [Docker Hub](https://hub.docker.com/r/stirlingtools/stirling-pdf)
