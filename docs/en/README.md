# PDF Toolbox Documentation

Welcome to the English documentation for PDF Toolbox, based on [Stirling PDF](https://stirlingpdf.com).

## Quick Start

```bash
# Clone repository
git clone https://github.com/bauer-group/CS-PDF-Toolbox.git
cd CS-PDF-Toolbox

# Create configuration
cp .env.example .env

# Generate secrets
./scripts/generate-secrets.sh

# Start container
docker compose -f docker-compose.development.yml up -d
```

Access: <http://localhost:8080>

## Documentation

| Topic | Description |
|-------|-------------|
| [Installation](Installation.md) | Deployment & Quick Start |
| [Configuration](Configuration.md) | Environment Variables & Settings |
| [Security](Security.md) | Login, OAuth & API Authentication |
| [PDF Signing](PDF-Signing.md) | Digital Signatures & Certificates |
| [Branding](Branding.md) | Customization & Whitelabeling |
| [API](API.md) | REST API Documentation |

## Features

PDF Toolbox provides comprehensive PDF processing:

### Basic Operations

- Merge & Split
- Rotate & Rearrange
- Compress
- Extract (Images, Text)

### Conversion

- Office to PDF (Word, Excel, PowerPoint)
- Images to PDF
- HTML to PDF
- PDF to Images

### Security

- Password Protection
- Permissions
- Digital Signatures
- Remove Metadata

### OCR

- Text from scanned documents
- Multi-language (40+ languages)
- Create searchable PDFs

## Deployment Options

| Method | File | Description |
|--------|------|-------------|
| Development | `docker-compose.development.yml` | Local testing without HTTPS |
| Traefik | `docker-compose.traefik.yml` | Production with Let's Encrypt |
| Coolify | `docker-compose.coolify.yml` | PaaS deployment |

## Support

- **Stirling PDF**: [GitHub Issues](https://github.com/Stirling-Tools/Stirling-PDF/issues)
- **Deployment**: [GitHub Issues](https://github.com/bauer-group/CS-PDF-Toolbox/issues)
- **Documentation**: [docs.stirlingpdf.com](https://docs.stirlingpdf.com)

## License

This deployment project is distributed under the MIT License.
Stirling PDF uses an open-core model with MIT License.

See [NOTICE.md](../../NOTICE.md) for complete license information.
