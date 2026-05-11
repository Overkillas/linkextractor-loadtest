# Sobe a aplicacao Link Extractor (versao Python OU Ruby) via Docker Compose.
#
# Uso:
#   .\scripts\start-app.ps1 -Version python
#   .\scripts\start-app.ps1 -Version ruby
#
# Aguarda ate a API responder antes de retornar (health check simples).

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("python", "ruby")]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$compose = "$root\docker\docker-compose.$Version.yml"
$apiPort = if ($Version -eq "python") { 5000 } else { 4567 }

Write-Host "==> Subindo Link Extractor versao '$Version'..." -ForegroundColor Cyan
docker compose -f $compose up -d

Write-Host "==> Aguardando API em http://localhost:$apiPort/ ..." -ForegroundColor Cyan
# Codificamos a URL de teste para evitar que "://" seja colapsado no caminho HTTP.
$encoded = [uri]::EscapeDataString("https://example.com/")
$ready = $false
for ($i = 1; $i -le 30; $i++) {
    try {
        $resp = Invoke-WebRequest -Uri "http://localhost:$apiPort/api/$encoded" `
            -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($resp.StatusCode -eq 200) {
            $ready = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 2
    }
}

if (-not $ready) {
    Write-Error "API '$Version' nao respondeu em 60s. Veja 'docker compose logs'."
}

Write-Host "API '$Version' pronta em http://localhost:$apiPort/" -ForegroundColor Green
