# Limpa o Redis (FLUSHALL) para garantir cache vazio antes de cada cenario.
# Roda contra o container 'lx-redis' subido pelos compose files.
#
# Uso:
#   .\scripts\clear-cache.ps1

$ErrorActionPreference = "Stop"

Write-Host "==> Executando FLUSHALL no Redis..." -ForegroundColor Cyan
docker exec lx-redis redis-cli FLUSHALL | Out-Null
Write-Host "Cache do Redis limpo." -ForegroundColor Green
