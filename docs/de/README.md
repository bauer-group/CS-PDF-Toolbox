# PDF Toolbox Dokumentation

Willkommen zur deutschen Dokumentation für PDF Toolbox, basierend auf [Stirling PDF](https://stirlingpdf.com).

## Schnellstart

```bash
# Repository klonen
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox

# Konfiguration erstellen
cp .env.example .env

# Secrets generieren
./scripts/generate-secrets.sh

# Container starten
docker compose -f docker-compose.development.yml up -d
```

Zugriff: <http://localhost:8080>

## Dokumentation

| Thema | Beschreibung |
|-------|--------------|
| [Installation](Installation.md) | Deployment & Schnellstart |
| [Konfiguration](Konfiguration.md) | Umgebungsvariablen & Einstellungen |
| [Sicherheit](Sicherheit.md) | Login, OAuth & API-Authentifizierung |
| [PDF-Signatur](PDF-Signatur.md) | Digitale Signaturen & Zertifikate |
| [Branding](Branding.md) | Anpassungen & Whitelabeling |
| [API](API.md) | REST-API Dokumentation |

## Funktionen

PDF Toolbox bietet umfassende PDF-Verarbeitung:

### Grundfunktionen

- Zusammenführen & Aufteilen
- Rotieren & Anordnen
- Komprimieren
- Extrahieren (Bilder, Text)

### Konvertierung

- Office zu PDF (Word, Excel, PowerPoint)
- Bilder zu PDF
- HTML zu PDF
- PDF zu Bildern

### Sicherheit

- Passwortschutz
- Berechtigungen
- Digitale Signaturen
- Metadaten entfernen

### OCR

- Text aus gescannten Dokumenten
- Mehrsprachig (40+ Sprachen)
- Durchsuchbare PDFs erstellen

## Deployment-Optionen

| Methode | Datei | Beschreibung |
|---------|-------|--------------|
| Entwicklung | `docker-compose.development.yml` | Lokaler Test ohne HTTPS |
| Traefik | `docker-compose.traefik.yml` | Produktion mit Let's Encrypt |
| Coolify | `docker-compose.coolify.yml` | PaaS-Deployment |

## Support

- **Stirling PDF**: [GitHub Issues](https://github.com/Stirling-Tools/Stirling-PDF/issues)
- **Deployment**: [GitHub Issues](https://github.com/bauer-group/CS-PDF-Toolbox/issues)
- **Dokumentation**: [docs.stirlingpdf.com](https://docs.stirlingpdf.com)

## Lizenz

Dieses Deployment-Projekt steht unter der MIT-Lizenz.
Stirling PDF verwendet ein Open-Core-Modell mit MIT-Lizenz.

Siehe [NOTICE.md](../../NOTICE.md) für vollständige Lizenzinformationen.
