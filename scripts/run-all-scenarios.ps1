# Roda os 12 cenarios completos do PDF:
#   3 niveis de carga (10, 50, 100) x 2 versoes (python, ruby) x 2 caches (warm, cold)
#
# A versao Python eh testada primeiro (todos os 6 cenarios), depois a Ruby (outros 6).
# Entre as versoes, derrubamos a stack atual e subimos a outra.
#
# Uso:
#   .\scripts\run-all-scenarios.ps1
#   .\scripts\run-all-scenarios.ps1 -RunTime 1m   # mais rapido para fumaca
#
# Tempo estimado total: ~30 min com RunTime=2m.

param(
    [int[]]$UserLevels = @(10, 50, 100),
    [string]$RunTime = "2m"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

function Run-VersionScenarios {
    param([string]$Version)

    Write-Host ""
    Write-Host "########## VERSAO: $Version ##########" -ForegroundColor Yellow
    Write-Host ""

    & "$root\scripts\start-app.ps1" -Version $Version

    foreach ($users in $UserLevels) {
        foreach ($cache in @("warm", "cold")) {
            & "$root\scripts\run-scenario.ps1" `
                -Version $Version -Cache $cache -Users $users -RunTime $RunTime
        }
    }

    & "$root\scripts\stop-app.ps1" -Version $Version
}

$start = Get-Date
Run-VersionScenarios -Version "python"
Run-VersionScenarios -Version "ruby"
$elapsed = (Get-Date) - $start

Write-Host ""
Write-Host "Todos os 12 cenarios concluidos em $($elapsed.ToString('hh\:mm\:ss'))." -ForegroundColor Green
Write-Host "Proximo passo: abrir o notebook de analise:"
Write-Host "  .\.venv\Scripts\jupyter.exe lab analysis\analise.ipynb"
