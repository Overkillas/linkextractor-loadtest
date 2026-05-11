# Setup único — rode uma vez antes de qualquer teste.
#
# Pré-requisitos manuais (instalar antes):
#   - Docker Desktop for Windows (com WSL2 backend)
#   - Python 3.11+ (marque "Add to PATH" no instalador)
#   - Git for Windows
#
# Este script:
#   1. Cria um virtualenv local em .venv
#   2. Instala Locust + dependências de análise
#   3. Faz pull das imagens Docker da aplicação Link Extractor
#
# Uso:
#   .\scripts\setup.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "==> Verificando ferramentas..." -ForegroundColor Cyan
foreach ($tool in @("docker", "python", "git")) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Error "Ferramenta '$tool' nao encontrada no PATH. Instale antes de rodar."
    }
    Write-Host "    OK $tool -> $($cmd.Source)"
}

Write-Host "==> Criando virtualenv em .venv..." -ForegroundColor Cyan
if (-not (Test-Path "$root\.venv")) {
    python -m venv "$root\.venv"
}

Write-Host "==> Atualizando pip e instalando dependencias..." -ForegroundColor Cyan
& "$root\.venv\Scripts\python.exe" -m pip install --upgrade pip
& "$root\.venv\Scripts\python.exe" -m pip install -r "$root\locust\requirements.txt"
& "$root\.venv\Scripts\python.exe" -m pip install -r "$root\analysis\requirements.txt"

Write-Host "==> Baixando imagem Redis..." -ForegroundColor Cyan
docker pull redis:7-alpine

Write-Host "==> Buildando imagem Python (step5 do repo ibnesayeed/linkextractor)..." -ForegroundColor Cyan
$tmpPy = Join-Path $env:TEMP "lx-py-$(Get-Random)"
git clone --depth 1 --branch step5 -c core.autocrlf=false https://github.com/ibnesayeed/linkextractor.git $tmpPy
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao clonar repo para step5." }
docker build -t ibnesayeed/linkextractor:api-python "$tmpPy\api"
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao buildar imagem Python." }
Remove-Item -Recurse -Force $tmpPy

Write-Host "==> Buildando imagem Ruby (step6 do repo ibnesayeed/linkextractor)..." -ForegroundColor Cyan
$tmpRb = Join-Path $env:TEMP "lx-rb-$(Get-Random)"
git clone --depth 1 --branch step6 -c core.autocrlf=false https://github.com/ibnesayeed/linkextractor.git $tmpRb
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao clonar repo para step6." }
docker build -t ibnesayeed/linkextractor:api-ruby "$tmpRb\api"
if ($LASTEXITCODE -ne 0) { Write-Error "Falha ao buildar imagem Ruby." }
Remove-Item -Recurse -Force $tmpRb

Write-Host ""
Write-Host "Setup concluido. Para rodar os testes:" -ForegroundColor Green
Write-Host "  .\scripts\start-app.ps1 -Version python"
Write-Host "  .\scripts\run-all-scenarios.ps1"
