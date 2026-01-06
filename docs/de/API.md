# API-Dokumentation

Stirling PDF bietet eine umfassende REST-API für die Automatisierung von PDF-Operationen.

## API-Übersicht

### Basis-URL

| Umgebung | URL |
|----------|-----|
| Entwicklung | `http://localhost:8080/api/v1` |
| Produktion | `https://pdf.app.bauer-group.com/api/v1` |

### Swagger-Dokumentation

Interaktive API-Dokumentation verfügbar unter:

- **Swagger UI**: `/swagger-ui/index.html`
- **OpenAPI JSON**: `/v3/api-docs`

## Authentifizierung

### API-Key (empfohlen)

```bash
# Header-basiert
curl -H "X-Api-Key: your-api-key" \
  https://pdf.app.bauer-group.com/api/v1/info/status
```

### Globaler API-Key

In `.env` konfigurieren:

```bash
SECURITY_CUSTOM_GLOBAL_API_KEY=your-secure-api-key
```

### Benutzer-API-Key

Jeder Benutzer kann im Web-Interface einen eigenen API-Key erstellen.

## Endpunkte

### System-Information

```bash
# Status prüfen
GET /api/v1/info/status

# Anwendungsinformationen
GET /api/v1/info/app

# Verfügbare Sprachen
GET /api/v1/info/languages
```

**Beispiel:**

```bash
curl https://pdf.app.bauer-group.com/api/v1/info/status
```

**Antwort:**

```json
{
  "status": "UP",
  "version": "0.32.0"
}
```

### PDF-Operationen

#### Zusammenführen

```bash
POST /api/v1/general/merge-pdfs
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file[]` | PDF-Dateien zum Zusammenführen |

**Beispiel:**

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@document1.pdf" \
  -F "fileInput=@document2.pdf" \
  https://pdf.app.bauer-group.com/api/v1/general/merge-pdfs \
  -o merged.pdf
```

#### Aufteilen

```bash
POST /api/v1/general/split-pdf-by-pages
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `pageNumbers` | `string` | Seitenbereiche (z.B. "1-5,10,15-20") |

#### Rotieren

```bash
POST /api/v1/general/rotate-pdf
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `angle` | `integer` | Winkel (90, 180, 270) |

### Konvertierung

#### PDF zu Bild

```bash
POST /api/v1/convert/pdf/img
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `imageFormat` | `string` | Format (png, jpg, gif, webp) |
| `colorType` | `string` | Farbtyp (color, gray, bw) |
| `dpi` | `integer` | Auflösung (Standard: 300) |

#### Bild zu PDF

```bash
POST /api/v1/convert/img/pdf
```

#### Office zu PDF

```bash
POST /api/v1/convert/file/pdf
```

Unterstützte Formate: DOCX, XLSX, PPTX, ODT, ODS, ODP, etc.

#### HTML zu PDF

```bash
POST /api/v1/convert/html/pdf
```

### OCR

```bash
POST /api/v1/misc/ocr-pdf
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `languages` | `string[]` | OCR-Sprachen (eng, deu, fra, etc.) |
| `sidecar` | `boolean` | Text-Datei erstellen |
| `deskew` | `boolean` | Seiten ausrichten |
| `clean` | `boolean` | Hintergrund bereinigen |

**Beispiel:**

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@scanned-document.pdf" \
  -F "languages=deu" \
  -F "sidecar=true" \
  https://pdf.app.bauer-group.com/api/v1/misc/ocr-pdf \
  -o ocr-result.pdf
```

### Sicherheit

#### Passwort hinzufügen

```bash
POST /api/v1/security/add-password
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `password` | `string` | Passwort |
| `keyLength` | `integer` | Schlüssellänge (40, 128, 256) |

#### Passwort entfernen

```bash
POST /api/v1/security/remove-password
```

#### Metadaten entfernen

```bash
POST /api/v1/security/sanitize-pdf
```

### Wasserzeichen

```bash
POST /api/v1/misc/add-watermark
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `watermarkText` | `string` | Wasserzeichen-Text |
| `fontSize` | `integer` | Schriftgröße |
| `rotation` | `integer` | Rotation (0-360) |
| `opacity` | `float` | Transparenz (0-1) |

### Komprimierung

```bash
POST /api/v1/misc/compress-pdf
```

**Parameter:**

| Name | Typ | Beschreibung |
|------|-----|--------------|
| `fileInput` | `file` | PDF-Datei |
| `optimizeLevel` | `integer` | Stufe (1-5, höher = kleiner) |

## Batch-Verarbeitung

Mehrere Dateien in einem Request:

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@file1.pdf" \
  -F "fileInput=@file2.pdf" \
  -F "fileInput=@file3.pdf" \
  https://pdf.app.bauer-group.com/api/v1/general/merge-pdfs \
  -o combined.pdf
```

## Fehlerbehandlung

### HTTP-Statuscodes

| Code | Beschreibung |
|------|--------------|
| 200 | Erfolg |
| 400 | Ungültige Anfrage |
| 401 | Nicht authentifiziert |
| 403 | Keine Berechtigung |
| 413 | Datei zu groß |
| 500 | Server-Fehler |

### Fehler-Antwort

```json
{
  "timestamp": "2025-01-05T10:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Invalid PDF file",
  "path": "/api/v1/general/merge-pdfs"
}
```

## Limits

| Einstellung | Standard | Konfiguration |
|-------------|----------|---------------|
| Max. Dateigröße | 2 GB | `SYSTEM_MAX_FILE_SIZE` |
| Timeout | 5 Min | `SYSTEM_CONNECTION_TIMEOUT_MINUTES` |

## SDK / Client-Libraries

### Python

```python
import requests

API_URL = "https://pdf.app.bauer-group.com/api/v1"
API_KEY = "your-api-key"

def merge_pdfs(files, output_path):
    response = requests.post(
        f"{API_URL}/general/merge-pdfs",
        headers={"X-Api-Key": API_KEY},
        files=[("fileInput", open(f, "rb")) for f in files]
    )
    with open(output_path, "wb") as f:
        f.write(response.content)

# Verwendung
merge_pdfs(["doc1.pdf", "doc2.pdf"], "merged.pdf")
```

### JavaScript/Node.js

```javascript
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

const API_URL = 'https://pdf.app.bauer-group.com/api/v1';
const API_KEY = 'your-api-key';

async function mergePdfs(files, outputPath) {
  const form = new FormData();
  files.forEach(file => {
    form.append('fileInput', fs.createReadStream(file));
  });

  const response = await axios.post(
    `${API_URL}/general/merge-pdfs`,
    form,
    {
      headers: {
        'X-Api-Key': API_KEY,
        ...form.getHeaders()
      },
      responseType: 'arraybuffer'
    }
  );

  fs.writeFileSync(outputPath, response.data);
}

// Verwendung
mergePdfs(['doc1.pdf', 'doc2.pdf'], 'merged.pdf');
```

### PowerShell

```powershell
$ApiUrl = "https://pdf.app.bauer-group.com/api/v1"
$ApiKey = "your-api-key"

function Merge-Pdfs {
    param(
        [string[]]$Files,
        [string]$OutputPath
    )

    $form = @{}
    $Files | ForEach-Object {
        $form["fileInput"] = Get-Item $_
    }

    Invoke-RestMethod `
        -Uri "$ApiUrl/general/merge-pdfs" `
        -Method Post `
        -Headers @{"X-Api-Key" = $ApiKey} `
        -Form $form `
        -OutFile $OutputPath
}

# Verwendung
Merge-Pdfs -Files @("doc1.pdf", "doc2.pdf") -OutputPath "merged.pdf"
```

## Weiterführende Dokumentation

- [Installation](Installation.md)
- [Sicherheit & Login](Sicherheit.md)
- [Konfiguration](Konfiguration.md)
- [Offizielle Stirling PDF API-Docs](https://stirlingpdf.com/docs/api)
