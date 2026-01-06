# API Documentation

Stirling PDF provides a comprehensive REST API for automating PDF operations.

## API Overview

### Base URL

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:8080/api/v1` |
| Production | `https://pdf.app.bauer-group.com/api/v1` |

### Swagger Documentation

Interactive API documentation available at:

- **Swagger UI**: `/swagger-ui/index.html`
- **OpenAPI JSON**: `/v3/api-docs`

## Authentication

### API Key (recommended)

```bash
# Header-based
curl -H "X-Api-Key: your-api-key" \
  https://pdf.app.bauer-group.com/api/v1/info/status
```

### Global API Key

Configure in `.env`:

```bash
SECURITY_CUSTOM_GLOBAL_API_KEY=your-secure-api-key
```

### User API Key

Each user can create their own API key in the web interface.

## Endpoints

### System Information

```bash
# Check status
GET /api/v1/info/status

# Application information
GET /api/v1/info/app

# Available languages
GET /api/v1/info/languages
```

**Example:**

```bash
curl https://pdf.app.bauer-group.com/api/v1/info/status
```

**Response:**

```json
{
  "status": "UP",
  "version": "0.32.0"
}
```

### PDF Operations

#### Merge

```bash
POST /api/v1/general/merge-pdfs
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file[]` | PDF files to merge |

**Example:**

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@document1.pdf" \
  -F "fileInput=@document2.pdf" \
  https://pdf.app.bauer-group.com/api/v1/general/merge-pdfs \
  -o merged.pdf
```

#### Split

```bash
POST /api/v1/general/split-pdf-by-pages
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `pageNumbers` | `string` | Page ranges (e.g., "1-5,10,15-20") |

#### Rotate

```bash
POST /api/v1/general/rotate-pdf
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `angle` | `integer` | Angle (90, 180, 270) |

### Conversion

#### PDF to Image

```bash
POST /api/v1/convert/pdf/img
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `imageFormat` | `string` | Format (png, jpg, gif, webp) |
| `colorType` | `string` | Color type (color, gray, bw) |
| `dpi` | `integer` | Resolution (default: 300) |

#### Image to PDF

```bash
POST /api/v1/convert/img/pdf
```

#### Office to PDF

```bash
POST /api/v1/convert/file/pdf
```

Supported formats: DOCX, XLSX, PPTX, ODT, ODS, ODP, etc.

#### HTML to PDF

```bash
POST /api/v1/convert/html/pdf
```

### OCR

```bash
POST /api/v1/misc/ocr-pdf
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `languages` | `string[]` | OCR languages (eng, deu, fra, etc.) |
| `sidecar` | `boolean` | Create text file |
| `deskew` | `boolean` | Align pages |
| `clean` | `boolean` | Clean background |

**Example:**

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@scanned-document.pdf" \
  -F "languages=eng" \
  -F "sidecar=true" \
  https://pdf.app.bauer-group.com/api/v1/misc/ocr-pdf \
  -o ocr-result.pdf
```

### Security

#### Add Password

```bash
POST /api/v1/security/add-password
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `password` | `string` | Password |
| `keyLength` | `integer` | Key length (40, 128, 256) |

#### Remove Password

```bash
POST /api/v1/security/remove-password
```

#### Remove Metadata

```bash
POST /api/v1/security/sanitize-pdf
```

### Watermark

```bash
POST /api/v1/misc/add-watermark
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `watermarkText` | `string` | Watermark text |
| `fontSize` | `integer` | Font size |
| `rotation` | `integer` | Rotation (0-360) |
| `opacity` | `float` | Transparency (0-1) |

### Compression

```bash
POST /api/v1/misc/compress-pdf
```

**Parameters:**

| Name | Type | Description |
|------|------|-------------|
| `fileInput` | `file` | PDF file |
| `optimizeLevel` | `integer` | Level (1-5, higher = smaller) |

## Batch Processing

Multiple files in one request:

```bash
curl -X POST \
  -H "X-Api-Key: your-api-key" \
  -F "fileInput=@file1.pdf" \
  -F "fileInput=@file2.pdf" \
  -F "fileInput=@file3.pdf" \
  https://pdf.app.bauer-group.com/api/v1/general/merge-pdfs \
  -o combined.pdf
```

## Error Handling

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Invalid request |
| 401 | Not authenticated |
| 403 | No permission |
| 413 | File too large |
| 500 | Server error |

### Error Response

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

| Setting | Default | Configuration |
|---------|---------|---------------|
| Max file size | 2 GB | `SYSTEM_MAX_FILE_SIZE` |
| Timeout | 5 min | `SYSTEM_CONNECTION_TIMEOUT_MINUTES` |

## SDK / Client Libraries

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

# Usage
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

// Usage
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

# Usage
Merge-Pdfs -Files @("doc1.pdf", "doc2.pdf") -OutputPath "merged.pdf"
```

## Further Documentation

- [Installation](Installation.md)
- [Security & Login](Security.md)
- [Configuration](Configuration.md)
- [Official Stirling PDF API Docs](https://stirlingpdf.com/docs/api)
