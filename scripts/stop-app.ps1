# Derruba a aplicacao (qualquer versao) e remove volumes do Redis.
#
# Uso:
#   .\scripts\stop-app.ps1 -Version python
#   .\scripts\stop-app.ps1 -Version ruby

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("python", "ruby")]
    [string]$Version
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$compose = "$root\docker\docker-compose.$Version.yml"

Write-Host "==> Parando Link Extractor versao '$Version'..." -ForegroundColor Cyan
docker compose -f $compose down -v
Write-Host "Stack derrubada." -ForegroundColor Green
