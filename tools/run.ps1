# =============================================================================
# Development Tools Container Launcher (PowerShell)
# Starts an interactive Linux container with all required tools
# =============================================================================

param(
    [switch]$Build,
    [string]$Script
)

$ErrorActionPreference = "Stop"

# Configuration - get project dir (parent of tools folder)
$ToolsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ToolsDir
$ImageName = "pdf-toolbox-tools"
$ContainerName = "pdf-toolbox-tools-shell"

# Check if Docker is running
try {
    docker info 2>&1 | Out-Null
} catch {
    Write-Host "[ERROR] Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

# Check if image exists
docker image inspect $ImageName 2>&1 | Out-Null
$imageExists = $LASTEXITCODE -eq 0

# Build if explicitly requested with -Build flag, or if image doesn't exist
if ($Build) {
    Write-Host "[INFO] Rebuilding tools container..." -ForegroundColor Cyan
    docker build -t $ImageName "$ToolsDir"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to build tools container" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
} elseif (-not $imageExists) {
    Write-Host "[INFO] Tools image not found. Building..." -ForegroundColor Cyan
    docker build -t $ImageName "$ToolsDir"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Failed to build tools container" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# If a script is specified, run it directly
if ($Script) {
    Write-Host "[INFO] Running: $Script" -ForegroundColor Cyan
    docker run --rm `
        -v "${ProjectDir}:/workspace" `
        -v /var/run/docker.sock:/var/run/docker.sock `
        -w /workspace `
        $ImageName `
        /bin/bash -c $Script
    exit $LASTEXITCODE
}

# Interactive mode
Write-Host ""
Write-Host "===========================================" -ForegroundColor Green
Write-Host " PDF Toolbox Development Tools" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Available scripts:"
Write-Host "  ./scripts/generate-assets.sh    - Generate logos & favicons from source" -ForegroundColor Yellow
Write-Host "  ./scripts/generate-secrets.sh   - Generate admin password & API key" -ForegroundColor Yellow
Write-Host ""
Write-Host "Certificate Management:"
Write-Host "  ./scripts/generate-cert.sh      - Create self-signed PDF signing certificate" -ForegroundColor Cyan
Write-Host "  ./scripts/ca-cert-workflow.sh   - CA-signed certificate (CSR + import)" -ForegroundColor Cyan
Write-Host "  ./scripts/convert-to-p12.sh     - Convert PEM cert to P12 format" -ForegroundColor Cyan
Write-Host ""
Write-Host "Asset Generation:"
Write-Host "  Place logo files in src/branding/logo-source-*.{eps,svg,png}"
Write-Host "  Run generate-assets.sh to create favicons, app icons, etc."
Write-Host ""
Write-Host "Type 'exit' to leave the container."
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

# Run interactive container
docker run -it --rm `
    --name $ContainerName `
    -v "${ProjectDir}:/workspace" `
    -v /var/run/docker.sock:/var/run/docker.sock `
    -w /workspace `
    $ImageName
