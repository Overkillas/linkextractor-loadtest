# Roda UM cenario de teste de carga e gera CSVs em results/raw/.
#
# Uso:
#   .\scripts\run-scenario.ps1 -Version python -Cache warm -Users 50
#   .\scripts\run-scenario.ps1 -Version ruby   -Cache cold -Users 100
#
# Os arquivos sao nomeados com o padrao:
#   <version>_<cache>_<users>u_<runtime>
# Ex: results/raw/python_warm_50u_2m_stats.csv

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("python", "ruby")]
    [string]$Version,

    [Parameter(Mandatory = $true)]
    [ValidateSet("warm", "cold")]
    [string]$Cache,

    [Parameter(Mandatory = $true)]
    [ValidateRange(1, 1000)]
    [int]$Users,

    [int]$SpawnRate = 0,
    [string]$RunTime = "2m"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

# Spawn rate default: ~1/5 dos usuarios por segundo
if ($SpawnRate -le 0) {
    $SpawnRate = [Math]::Max(1, [int]($Users / 5))
}

$apiPort = if ($Version -eq "python") { 5000 } else { 4567 }
$host_ = "http://localhost:$apiPort"

$tag = "${Version}_${Cache}_${Users}u_$RunTime"
$csvBase = "$root\results\raw\$tag"

Write-Host "==> Limpando cache do Redis antes do cenario..." -ForegroundColor Cyan
& "$root\scripts\clear-cache.ps1"

Write-Host "==> Cenario: versao=$Version cache=$Cache users=$Users spawn=$SpawnRate dur=$RunTime" -ForegroundColor Cyan
Write-Host "    host=$host_  csv=$csvBase"

$env:CACHE_MODE = $Cache

& "$root\.venv\Scripts\locust.exe" `
    -f "$root\locust\locustfile.py" `
    --host $host_ `
    --headless `
    -u $Users `
    -r $SpawnRate `
    -t $RunTime `
    --csv $csvBase `
    --only-summary

if ($LASTEXITCODE -ne 0) {
    Write-Error "Locust retornou codigo $LASTEXITCODE"
}

Write-Host "Cenario '$tag' concluido. CSVs em results/raw/" -ForegroundColor Green
