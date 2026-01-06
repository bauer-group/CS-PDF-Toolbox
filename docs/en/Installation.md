# Installation & Deployment

This guide describes the installation and configuration of PDF Toolbox (based on Stirling PDF).

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2.0+
- At least 4 GB RAM (recommended: 8 GB for `latest-fat` image)
- 10 GB free disk space

## Image Variants

| Image | Size | Features | Usage |
|-------|------|----------|-------|
| `latest` | ~400 MB | Basic PDF tools | Simple operations |
| `latest-fat` | ~1.5 GB | All tools incl. OCR, LibreOffice | **Recommended** |
| `latest-ultra-lite` | ~200 MB | Minimal features | Resource-limited environments |

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox
```

### 2. Create Configuration

```bash
cp .env.example .env
```

### 3. Generate Secrets

```bash
# With tools container (recommended)
./tools/run.sh -s './scripts/generate-secrets.sh'

# Or directly
./scripts/generate-secrets.sh
```

This automatically generates:

- Admin password (`SECURITY_INITIAL_LOGIN_PASSWORD`)
- API key (optional)

### 4. Start Container

**Development (without reverse proxy):**

```bash
docker compose -f docker-compose.development.yml up -d
```

Access: <http://localhost:8080>

**Production with Traefik:**

```bash
docker compose -f docker-compose.traefik.yml up -d
```

Access: <https://pdf.app.bauer-group.com>

**Coolify PaaS:**

```bash
docker compose -f docker-compose.coolify.yml up -d
```

## Directory Structure

```text
/configs/                    # Configuration files
├── settings.yml             # Main configuration
├── custom_settings.yml      # Custom settings
└── stirling-pdf-DB.mv.db    # H2 database (when login enabled)

/customFiles/                # Branding & customizations
├── static/                  # Static files (logos, CSS)
│   ├── favicon.ico
│   ├── logo.svg
│   └── custom.css
├── signatures/              # Signature certificates
│   ├── ALL_USERS/           # For all users
│   └── {username}/          # User-specific
└── translations/            # Custom translations

/logs/                       # Application logs
├── stirling-pdf.log
└── invalid-auths.log        # Failed login attempts

/pipeline/                   # Automation
├── watchedFolders/          # Watched input folders
└── finishedFolders/         # Processed outputs

/usr/share/tessdata/         # OCR language data
```

## Volume Mounts

```yaml
volumes:
  # Required
  - 'stirling-configs:/configs'

  # Recommended
  - 'stirling-customFiles:/customFiles'
  - 'stirling-logs:/logs'

  # Optional
  - 'stirling-tessdata:/usr/share/tessdata'  # Additional OCR languages
  - 'stirling-pipeline:/pipeline'             # Automation

  # PDF signing certificate
  - './certs/cert.p12:/customFiles/signatures/ALL_USERS/cert.p12:ro'
```

## Network Configuration

### Ports

| Port | Service | Description |
|------|---------|-------------|
| 8080 | HTTP | Web interface & API |

### Reverse Proxy (Traefik)

The `docker-compose.traefik.yml` includes all necessary labels for:

- Automatic HTTPS certificates (Let's Encrypt)
- HTTP to HTTPS redirect
- Load balancing

### Firewall

```bash
# UFW (Ubuntu)
ufw allow 8080/tcp  # Development only

# Production: only 80/443 via reverse proxy
ufw allow 80/tcp
ufw allow 443/tcp
```

## First Steps After Installation

1. **Open the application** in browser
2. **Login with admin account**: Username `admin`, password from `.env`
3. **Change admin password**: After first login in account settings
4. **Create additional users**: In admin area

## Troubleshooting

### Container doesn't start

```bash
# Check logs
docker logs pdf_SERVER

# Check permissions
docker exec pdf_SERVER ls -la /configs
```

### Memory issues

```yaml
# In docker-compose.yml
deploy:
  resources:
    limits:
      memory: 8G
    reservations:
      memory: 4G
```

### OCR not working

```bash
# Check available languages
docker exec pdf_SERVER tesseract --list-langs

# German language data is included in latest-fat image
```

## Further Documentation

- [Configuration](Configuration.md)
- [Security & Login](Security.md)
- [PDF Signing](PDF-Signing.md)
- [Branding & Customization](Branding.md)
- [API Documentation](API.md)
