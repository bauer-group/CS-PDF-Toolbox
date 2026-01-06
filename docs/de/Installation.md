# Installation & Deployment

Diese Anleitung beschreibt die Installation und Konfiguration von PDF Toolbox (basierend auf Stirling PDF).

## Voraussetzungen

- Docker Engine 20.10+
- Docker Compose v2.0+
- Mindestens 4 GB RAM (empfohlen: 8 GB für `latest-fat` Image)
- 10 GB freier Speicherplatz

## Image-Varianten

| Image | Größe | Features | Verwendung |
|-------|-------|----------|------------|
| `latest` | ~400 MB | Basis PDF-Tools | Einfache Operationen |
| `latest-fat` | ~1.5 GB | Alle Tools inkl. OCR, LibreOffice | **Empfohlen** |
| `latest-ultra-lite` | ~200 MB | Minimale Funktionen | Resource-limitierte Umgebungen |

## Schnellstart

### 1. Repository klonen

```bash
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox
```

### 2. Konfiguration erstellen

```bash
cp .env.example .env
```

### 3. Secrets generieren

```bash
# Mit Tools-Container (empfohlen)
./tools/run.sh -s './scripts/generate-secrets.sh'

# Oder manuell
./scripts/generate-secrets.sh
```

Dies generiert automatisch:

- Admin-Passwort (`SECURITY_INITIAL_LOGIN_PASSWORD`)
- API-Schlüssel (optional)

### 4. Container starten

**Entwicklung (ohne Reverse Proxy):**

```bash
docker compose -f docker-compose.development.yml up -d
```

Zugriff: <http://localhost:8080>

**Produktion mit Traefik:**

```bash
docker compose -f docker-compose.traefik.yml up -d
```

Zugriff: <https://pdf.app.bauer-group.com>

**Coolify PaaS:**

```bash
docker compose -f docker-compose.coolify.yml up -d
```

## Verzeichnisstruktur

```text
/configs/                    # Konfigurationsdateien
├── settings.yml             # Hauptkonfiguration
├── custom_settings.yml      # Benutzerdefinierte Einstellungen
└── stirling-pdf-DB.mv.db    # H2-Datenbank (bei Login aktiviert)

/customFiles/                # Branding & Anpassungen
├── static/                  # Statische Dateien (Logos, CSS)
│   ├── favicon.ico
│   ├── logo.svg
│   └── custom.css
├── signatures/              # Signatur-Zertifikate
│   ├── ALL_USERS/           # Für alle Benutzer
│   └── {username}/          # Benutzerspezifisch
└── translations/            # Eigene Übersetzungen

/logs/                       # Anwendungslogs
├── stirling-pdf.log
└── invalid-auths.log        # Fehlgeschlagene Logins

/pipeline/                   # Automatisierung
├── watchedFolders/          # Überwachte Eingabeordner
└── finishedFolders/         # Verarbeitete Ausgaben

/usr/share/tessdata/         # OCR Sprachdaten
```

## Volume-Mounts

```yaml
volumes:
  # Pflicht
  - 'stirling-configs:/configs'

  # Empfohlen
  - 'stirling-customFiles:/customFiles'
  - 'stirling-logs:/logs'

  # Optional
  - 'stirling-tessdata:/usr/share/tessdata'  # Zusätzliche OCR-Sprachen
  - 'stirling-pipeline:/pipeline'             # Automatisierung

  # PDF-Signatur-Zertifikat
  - './certs/cert.p12:/customFiles/signatures/ALL_USERS/cert.p12:ro'
```

## Netzwerk-Konfiguration

### Ports

| Port | Dienst | Beschreibung |
|------|--------|--------------|
| 8080 | HTTP | Web-Interface & API |

### Reverse Proxy (Traefik)

Die `docker-compose.traefik.yml` enthält bereits alle notwendigen Labels für:

- Automatische HTTPS-Zertifikate (Let's Encrypt)
- HTTP zu HTTPS Redirect
- Loadbalancing

### Firewall

```bash
# UFW (Ubuntu)
ufw allow 8080/tcp  # Nur für Entwicklung

# Produktion: nur 80/443 über Reverse Proxy
ufw allow 80/tcp
ufw allow 443/tcp
```

## Erste Schritte nach Installation

1. **Öffnen Sie die Anwendung** im Browser
2. **Login mit Admin-Konto**: Benutzername `admin`, Passwort aus `.env`
3. **Admin-Passwort ändern**: Nach erstem Login unter Kontoeinstellungen
4. **Weitere Benutzer anlegen**: Im Admin-Bereich

## Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
docker logs pdf_SERVER

# Berechtigungen prüfen
docker exec pdf_SERVER ls -la /configs
```

### Speicherprobleme

```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

### OCR funktioniert nicht

```bash
# Verfügbare Sprachen prüfen
docker exec pdf_SERVER tesseract --list-langs

# Deutsche Sprachdaten sind im latest-fat Image enthalten
```

## Weiterführende Dokumentation

- [Konfiguration](Konfiguration.md)
- [Sicherheit & Login](Sicherheit.md)
- [PDF-Signatur](PDF-Signatur.md)
- [Branding & Anpassungen](Branding.md)
- [API-Dokumentation](API.md)
