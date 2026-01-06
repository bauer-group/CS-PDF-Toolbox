# PDF-Signatur

Dokumentation zur digitalen Signierung von PDF-Dokumenten mit Stirling PDF.

## Übersicht

Stirling PDF unterstützt das digitale Signieren von PDFs mit:

- **Selbstsignierten Zertifikaten**: Für interne Dokumente
- **CA-signierten Zertifikaten**: Für externe Dokumente mit Vertrauenskette

Die Zertifikate werden im P12-Format (PKCS#12) verwendet.

## Einbindungsmethoden

Es gibt drei Methoden, ein Signaturzertifikat einzubinden:

| Methode | Beschreibung | Empfohlen für |
|---------|--------------|---------------|
| **A: Umgebungsvariable** | `KEYSTORE_P12_BASE64` (Base64) | Coolify, CI/CD, Cloud |
| **B: Volume-Mount** | Datei nach `/configs/keystore.p12` | Lokale Entwicklung |
| **C: Benutzer-Zertifikate** | `/customFiles/signatures/` | Individuelle Auswahl |

## Zertifikat erstellen

### Option 1: Selbstsigniertes Zertifikat

Schnell und einfach für interne Verwendung:

```bash
# Mit Tools-Container
./tools/run.sh -s './scripts/generate-cert.sh'

# Oder direkt
./scripts/generate-cert.sh
```

**Interaktive Eingaben:**

- Organisation: BAUER GROUP
- Land: DE
- Gültigkeitsdauer: 3 Jahre (Standard)
- Schlüsselgröße: 4096 bit (empfohlen)

**Ergebnis:**

```text
certs/
├── cert.p12           # Zertifikat für Stirling PDF (Backup)
├── cert.crt           # Öffentliches Zertifikat
├── cert.key           # Privater Schlüssel (SICHER AUFBEWAHREN!)
└── .passphrase        # Zertifikat-Passwort

.env (automatisch aktualisiert):
├── KEYSTORE_PASSWORD      # Zertifikat-Passwort
└── KEYSTORE_P12_BASE64    # Base64-kodiertes P12-Zertifikat
```

### Option 2: CA-signiertes Zertifikat

Für Dokumente, die von Dritten verifiziert werden sollen:

```bash
./scripts/ca-cert-workflow.sh
```

**Schritt 1: CSR erstellen**

```bash
# Wählen Sie Option 1
./scripts/ca-cert-workflow.sh
# → Eingabe der Zertifikatsinformationen
# → Erstellt: certs/signing-request.csr und certs/signing-request.key
```

**Schritt 2: CSR an CA senden**

Senden Sie `certs/signing-request.csr` an Ihre Zertifizierungsstelle.

**Schritt 3: Signiertes Zertifikat importieren**

```bash
# Wählen Sie Option 2
./scripts/ca-cert-workflow.sh
# → Pfad zum signierten Zertifikat angeben
# → Optional: CA-Chain importieren
# → Erstellt: certs/cert.p12
```

## Zertifikat einbinden

### Methode A: Umgebungsvariablen (Empfohlen für Coolify/CI)

Das Zertifikat wird als Base64 in einer Umgebungsvariable gespeichert. Der Container-Entrypoint dekodiert es beim Start automatisch nach `/configs/keystore.p12`.

**Vorteile:**

- Keine Datei-Mounts nötig
- Perfekt für Coolify, CI/CD, Kubernetes
- Zertifikat als Secret speicherbar

**In .env (vom Script automatisch gesetzt):**

```bash
# Server-Zertifikat aktivieren
SYSTEM_SERVERCERTIFICATE_ENABLED=true

# Name der Organisation (wird in UI angezeigt)
SYSTEM_SERVERCERTIFICATE_ORGANIZATIONNAME=BAUER GROUP

# Passwort für das P12-Zertifikat
KEYSTORE_PASSWORD=auto-generiert-vom-script

# Base64-kodiertes P12-Zertifikat (vom Script automatisch gesetzt)
KEYSTORE_P12_BASE64=MIIxxxxx...
```

**Funktionsweise:**

1. `./scripts/generate-cert.sh` erstellt das Zertifikat
2. Script schreibt `KEYSTORE_PASSWORD` und `KEYSTORE_P12_BASE64` in `.env`
3. Container startet → Entrypoint dekodiert Base64 → schreibt `/configs/keystore.p12`
4. Stirling PDF verwendet das Zertifikat zum Signieren

### Methode B: Volume-Mount (Lokale Entwicklung)

Alternativ kann die P12-Datei direkt gemountet werden.

**In docker-compose.yml:**

```yaml
volumes:
  - './certs/cert.p12:/configs/keystore.p12:ro'
```

**In .env:**

```bash
SYSTEM_SERVERCERTIFICATE_ENABLED=true
SYSTEM_SERVERCERTIFICATE_ORGANIZATIONNAME=BAUER GROUP
KEYSTORE_PASSWORD=ihr-passwort-hier
```

> **Hinweis:** Der Entrypoint prüft zuerst, ob `/configs/keystore.p12` bereits existiert (gemountet). Falls ja, wird `KEYSTORE_P12_BASE64` ignoriert.

### Methode C: Benutzer-Zertifikate

Für individuelle Zertifikate, die Benutzer in der UI auswählen können.

**Globales Zertifikat (alle Benutzer):**

```yaml
volumes:
  - './certs/cert.p12:/customFiles/signatures/ALL_USERS/cert.p12:ro'
```

**Benutzerspezifische Zertifikate:**

```yaml
volumes:
  - './certs/users/max.mustermann/cert.p12:/customFiles/signatures/max.mustermann/cert.p12:ro'
```

**Struktur im Container:**

```text
/customFiles/signatures/
├── ALL_USERS/               # Für alle Benutzer verfügbar
│   └── company-cert.p12
└── max.mustermann/          # Nur für Benutzer "max.mustermann"
    └── personal-cert.p12
```

## Zertifikat verwenden

### Bei Server-Zertifikat (Methode A)

1. **PDF hochladen** im Web-Interface
2. **Zertifikat signieren** Tool wählen
3. **"Signieren mit BAUER GROUP"** erscheint automatisch
4. **Signieren** und herunterladen

### Bei Benutzer-Zertifikaten (Methode B)

1. **PDF hochladen** im Web-Interface
2. **Zertifikat signieren** Tool wählen
3. **Zertifikat auswählen** aus der Dropdown-Liste
4. **Passphrase eingeben**
5. **Signieren** und herunterladen

## Zertifikat konvertieren

### PEM zu P12

Wenn Sie bereits ein PEM-Zertifikat haben:

```bash
./scripts/convert-to-p12.sh
# → Pfad zum Zertifikat (.crt/.pem)
# → Pfad zum privaten Schlüssel (.key)
# → Optional: CA-Chain
```

## Zertifikat-Details anzeigen

```bash
# P12-Inhalt anzeigen
openssl pkcs12 -in certs/cert.p12 -info -noout

# Zertifikat-Details
openssl pkcs12 -in certs/cert.p12 -clcerts -nokeys | \
  openssl x509 -noout -text

# Ablaufdatum prüfen
openssl pkcs12 -in certs/cert.p12 -clcerts -nokeys | \
  openssl x509 -noout -enddate
```

## Signatur verifizieren

### Im Browser (Adobe Acrobat Reader)

1. PDF öffnen in Adobe Acrobat Reader
2. Signatur-Panel öffnen (linke Seitenleiste)
3. Signatur-Details anzeigen

### Kommandozeile

```bash
# Mit pdfsig (Poppler-Utils)
pdfsig signed-document.pdf

# Mit qpdf
qpdf --show-xref signed-document.pdf
```

## Best Practices

### Schlüssel-Sicherheit

1. **Privaten Schlüssel schützen**: `chmod 600 cert.key`
2. **Passphrase sicher aufbewahren**: Nicht in Repositories!
3. **Regelmäßige Erneuerung**: Vor Ablauf neues Zertifikat erstellen
4. **KEYSTORE_PASSWORD**: Als Secret in Coolify/CI-System speichern

### Gültigkeitsdauer

| Verwendung | Empfohlene Gültigkeit |
|------------|----------------------|
| Test/Entwicklung | 1 Jahr |
| Interne Dokumente | 3 Jahre |
| Externe Dokumente | 1-2 Jahre |

### Schlüsselgröße

| Größe | Sicherheit | Empfehlung |
|-------|------------|------------|
| 2048 bit | Gut | Minimum |
| 4096 bit | Sehr gut | **Empfohlen** |

## Troubleshooting

### Zertifikat wird nicht erkannt

```bash
# Berechtigungen prüfen
docker exec pdf_SERVER ls -la /configs/keystore.p12
docker exec pdf_SERVER ls -la /customFiles/signatures/

# Container neu starten
docker compose restart stirling-pdf
```

### Passphrase-Fehler

```bash
# Passphrase testen
openssl pkcs12 -in certs/cert.p12 -passin pass:"$(cat certs/.passphrase)" -info -noout
```

### Server-Zertifikat erscheint nicht

1. Prüfen Sie `SYSTEM_SERVERCERTIFICATE_ENABLED=true`
2. Prüfen Sie `KEYSTORE_PASSWORD` ist gesetzt
3. Prüfen Sie Volume-Mount auf `/configs/keystore.p12`

### Signatur nicht vertrauenswürdig

Bei selbstsignierten Zertifikaten ist dies normal. Für vertrauenswürdige Signaturen:

1. CA-signiertes Zertifikat verwenden
2. Root-CA im PDF-Reader importieren

## Weiterführende Dokumentation

- [Installation](Installation.md)
- [Sicherheit & Login](Sicherheit.md)
- [Konfiguration](Konfiguration.md)
- [Stirling PDF Certificate Signing](https://docs.stirlingpdf.com/Functionality/Security/Certificate-Signing/)
