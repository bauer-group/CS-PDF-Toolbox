# PDF Signing

Documentation for digitally signing PDF documents with Stirling PDF.

## Overview

Stirling PDF supports digital signing of PDFs with:

- **Self-signed certificates**: For internal documents
- **CA-signed certificates**: For external documents with trust chain

Certificates are used in P12 format (PKCS#12).

## Integration Methods

There are three methods to integrate a signing certificate:

| Method | Description | Recommended for |
|--------|-------------|-----------------|
| **A: Environment Variable** | `KEYSTORE_P12_BASE64` (Base64) | Coolify, CI/CD, Cloud |
| **B: Volume Mount** | File to `/configs/keystore.p12` | Local development |
| **C: User Certificates** | `/customFiles/signatures/` | Individual selection |

## Create Certificate

### Option 1: Self-Signed Certificate

Quick and easy for internal use:

```bash
# With tools container
./tools/run.sh -s './scripts/generate-cert.sh'

# Or directly
./scripts/generate-cert.sh
```

**Interactive inputs:**

- Organization: BAUER GROUP
- Country: DE
- Validity: 3 years (default)
- Key size: 4096 bit (recommended)

**Result:**

```text
certs/
├── cert.p12           # Certificate for Stirling PDF (backup)
├── cert.crt           # Public certificate
├── cert.key           # Private key (KEEP SECURE!)
└── .passphrase        # Certificate password

.env (automatically updated):
├── KEYSTORE_PASSWORD      # Certificate passphrase
└── KEYSTORE_P12_BASE64    # Base64-encoded P12 certificate
```

### Option 2: CA-Signed Certificate

For documents that need to be verified by third parties:

```bash
./scripts/ca-cert-workflow.sh
```

**Step 1: Create CSR**

```bash
# Choose option 1
./scripts/ca-cert-workflow.sh
# → Enter certificate information
# → Creates: certs/signing-request.csr and certs/signing-request.key
```

**Step 2: Submit CSR to CA**

Send `certs/signing-request.csr` to your Certificate Authority.

**Step 3: Import Signed Certificate**

```bash
# Choose option 2
./scripts/ca-cert-workflow.sh
# → Specify path to signed certificate
# → Optional: Import CA chain
# → Creates: certs/cert.p12
```

## Integrate Certificate

### Method A: Environment Variables (Recommended for Coolify/CI)

The certificate is stored as Base64 in an environment variable. The container entrypoint automatically decodes it at startup to `/configs/keystore.p12`.

**Benefits:**

- No file mounts required
- Perfect for Coolify, CI/CD, Kubernetes
- Certificate can be stored as secret

**In .env (automatically set by script):**

```bash
# Enable server certificate
SYSTEM_SERVERCERTIFICATE_ENABLED=true

# Organization name (shown in UI)
SYSTEM_SERVERCERTIFICATE_ORGANIZATIONNAME=BAUER GROUP

# Password for the P12 certificate
KEYSTORE_PASSWORD=auto-generated-by-script

# Base64-encoded P12 certificate (automatically set by script)
KEYSTORE_P12_BASE64=MIIxxxxx...
```

**How it works:**

1. `./scripts/generate-cert.sh` creates the certificate
2. Script writes `KEYSTORE_PASSWORD` and `KEYSTORE_P12_BASE64` to `.env`
3. Container starts → Entrypoint decodes Base64 → writes `/configs/keystore.p12`
4. Stirling PDF uses the certificate for signing

### Method B: Volume Mount (Local Development)

Alternatively, the P12 file can be mounted directly.

**In docker-compose.yml:**

```yaml
volumes:
  - './certs/cert.p12:/configs/keystore.p12:ro'
```

**In .env:**

```bash
SYSTEM_SERVERCERTIFICATE_ENABLED=true
SYSTEM_SERVERCERTIFICATE_ORGANIZATIONNAME=BAUER GROUP
KEYSTORE_PASSWORD=your-password-here
```

> **Note:** The entrypoint first checks if `/configs/keystore.p12` already exists (mounted). If so, `KEYSTORE_P12_BASE64` is ignored.

### Method C: User Certificates

For individual certificates that users can select in the UI.

**Global certificate (all users):**

```yaml
volumes:
  - './certs/cert.p12:/customFiles/signatures/ALL_USERS/cert.p12:ro'
```

**User-specific certificates:**

```yaml
volumes:
  - './certs/users/john.doe/cert.p12:/customFiles/signatures/john.doe/cert.p12:ro'
```

**Structure in container:**

```text
/customFiles/signatures/
├── ALL_USERS/               # Available for all users
│   └── company-cert.p12
└── john.doe/                # Only for user "john.doe"
    └── personal-cert.p12
```

## Use Certificate

### With Server Certificate (Method A)

1. **Upload PDF** in web interface
2. **Select Certificate Sign** tool
3. **"Sign with BAUER GROUP"** appears automatically
4. **Sign** and download

### With User Certificates (Method B)

1. **Upload PDF** in web interface
2. **Select Certificate Sign** tool
3. **Choose certificate** from dropdown list
4. **Enter passphrase**
5. **Sign** and download

## Convert Certificates

### PEM to P12

If you already have a PEM certificate:

```bash
./scripts/convert-to-p12.sh
# → Path to certificate (.crt/.pem)
# → Path to private key (.key)
# → Optional: CA chain
```

## View Certificate Details

```bash
# Show P12 contents
openssl pkcs12 -in certs/cert.p12 -info -noout

# Certificate details
openssl pkcs12 -in certs/cert.p12 -clcerts -nokeys | \
  openssl x509 -noout -text

# Check expiration date
openssl pkcs12 -in certs/cert.p12 -clcerts -nokeys | \
  openssl x509 -noout -enddate
```

## Verify Signature

### In Browser (Adobe Acrobat Reader)

1. Open PDF in Adobe Acrobat Reader
2. Open signature panel (left sidebar)
3. View signature details

### Command Line

```bash
# With pdfsig (Poppler-Utils)
pdfsig signed-document.pdf

# With qpdf
qpdf --show-xref signed-document.pdf
```

## Best Practices

### Key Security

1. **Protect private key**: `chmod 600 cert.key`
2. **Store passphrase securely**: Not in repositories!
3. **Regular renewal**: Create new certificate before expiration
4. **KEYSTORE_PASSWORD**: Store as secret in Coolify/CI system

### Validity Period

| Usage | Recommended Validity |
|-------|---------------------|
| Test/Development | 1 year |
| Internal documents | 3 years |
| External documents | 1-2 years |

### Key Size

| Size | Security | Recommendation |
|------|----------|----------------|
| 2048 bit | Good | Minimum |
| 4096 bit | Very good | **Recommended** |

## Troubleshooting

### Certificate Not Recognized

```bash
# Check permissions
docker exec pdf_SERVER ls -la /configs/keystore.p12
docker exec pdf_SERVER ls -la /customFiles/signatures/

# Restart container
docker compose restart stirling-pdf
```

### Passphrase Error

```bash
# Test passphrase
openssl pkcs12 -in certs/cert.p12 -passin pass:"$(cat certs/.passphrase)" -info -noout
```

### Server Certificate Not Showing

1. Check `SYSTEM_SERVERCERTIFICATE_ENABLED=true`
2. Check `KEYSTORE_PASSWORD` is set
3. Check volume mount to `/configs/keystore.p12`

### Signature Not Trusted

This is normal for self-signed certificates. For trusted signatures:

1. Use CA-signed certificate
2. Import root CA in PDF reader

## Further Documentation

- [Installation](Installation.md)
- [Security & Login](Security.md)
- [Configuration](Configuration.md)
- [Stirling PDF Certificate Signing](https://docs.stirlingpdf.com/Functionality/Security/Certificate-Signing/)
