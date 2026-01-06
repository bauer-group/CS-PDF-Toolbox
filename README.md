# PDF Toolbox (Stirling PDF)

> **[Deutsche Version / German Version](README_DE.md)**

Docker Compose deployment for [Stirling PDF](https://stirlingpdf.com) with custom branding, Traefik integration, and certificate-based PDF signing.

## Features

- **Custom Branding** (Logo, Favicon, App Name)
- Custom Docker Image with pre-installed OCR languages
- Traefik Integration with Let's Encrypt
- PDF Signing with Server Certificate (Base64 Environment Variable)
- OAuth/OIDC Support (optional)
- Coolify-compatible

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox
```

### 2. Start Tools Container

```bash
# Windows
.\tools\run.ps1
# Linux/macOS
./tools/run.sh
```

### 3. Generate Secrets

```bash
# Inside tools container:
./scripts/generate-secrets.sh
```

> **Note:** The script automatically creates `.env` from `.env.example` and generates a secure admin password.

### 4. Customize .env (optional)

```bash
# Edit .env for custom settings
nano .env
```

### 5. Customize Branding (optional)

Place logos in `src/branding/`:

- `logo.png` (Logo for navbar)
- `favicon.png` (Browser tab icon)

```bash
# Inside tools container:
./scripts/generate-assets.sh
```

See [Branding Documentation](docs/en/Branding.md) for details.

### 6. Create Signing Certificate (optional)

```bash
# Inside tools container:
./scripts/generate-cert.sh

# Or for CA-signed certificates:
./scripts/ca-cert-workflow.sh
```

> **Note:** The script writes `KEYSTORE_PASSWORD` and `KEYSTORE_P12_BASE64` automatically to `.env`. The container decodes the certificate at startup.

See [PDF Signing Documentation](docs/en/PDF-Signing.md) for details.

### 7. Start

```bash
# Development (http://localhost:8080)
docker compose -f docker-compose.development.yml up -d --build

# Production with Traefik
docker compose -f docker-compose.traefik.yml up -d --build

# Coolify
docker compose -f docker-compose.coolify.yml up -d --build
```

## Access

| Environment | URL |
|-------------|-----|
| Development | <http://localhost:8080> |
| Production | <https://pdf.app.bauer-group.com> |
| API Docs | /swagger-ui/index.html |
| Health | /api/v1/info/status |

## Documentation

| Document | Description |
|----------|-------------|
| [Installation](docs/en/Installation.md) | Deployment & Quick Start |
| [Configuration](docs/en/Configuration.md) | Environment Variables |
| [Security](docs/en/Security.md) | Login & OAuth |
| [PDF-Signing](docs/en/PDF-Signing.md) | Digital Signatures |
| [Branding](docs/en/Branding.md) | Custom Branding |
| [API](docs/en/API.md) | REST API |

## Directory Structure

```text
.
├── docker-compose.yml              # Alias for development
├── docker-compose.development.yml  # Development (with ports)
├── docker-compose.traefik.yml      # Production (with Traefik)
├── docker-compose.coolify.yml      # Coolify PaaS
├── .env.example                    # Example configuration
├── certs/                          # Signing certificates (gitignored)
├── docs/
│   ├── en/                         # English documentation
│   └── de/                         # German documentation
├── scripts/
│   ├── generate-assets.sh          # Generate branding assets
│   ├── generate-cert.sh            # Generate certificate
│   ├── generate-secrets.sh         # Generate secrets
│   ├── ca-cert-workflow.sh         # CA certificate workflow
│   └── convert-to-p12.sh           # Convert PEM to P12
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

The tools container includes ImageMagick, OpenSSL, and all required utilities:

```bash
# Start (builds automatically if needed)
.\tools\run.ps1        # Windows PowerShell
.\tools\run.cmd        # Windows CMD
./tools/run.sh         # Linux/macOS

# Force rebuild
.\tools\run.ps1 -Build
./tools/run.sh --build

# Run script directly
./tools/run.sh -s './scripts/generate-cert.sh'
```

## Commands

```bash
# Start (development)
docker compose -f docker-compose.development.yml up -d --build

# Start (production with Traefik)
docker compose -f docker-compose.traefik.yml up -d --build

# Logs
docker compose -f docker-compose.development.yml logs -f stirling-pdf

# Container status
docker compose -f docker-compose.development.yml ps

# Stop
docker compose -f docker-compose.development.yml down

# Rebuild without cache
docker compose -f docker-compose.development.yml build --no-cache
```

## License

This deployment project is licensed under the MIT License.
Stirling PDF uses an open-core model with MIT License.

## Official Documentation

- [Stirling PDF Docs](https://docs.stirlingpdf.com)
- [GitHub Repository](https://github.com/Stirling-Tools/Stirling-PDF)
- [Docker Hub](https://hub.docker.com/r/stirlingtools/stirling-pdf)
