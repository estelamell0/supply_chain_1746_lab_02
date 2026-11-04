<#
.SYNOPSIS
    Script de Inicializacao e Reset do Laboratorio 02 de Supply Chain Security
    PowerShell Native Driver para Windows (100% paridade com setup_lab.sh).
#>

param(
    [switch]$Clean
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# 0. Limpeza de artefatos temporários
$DistDir = Join-Path $ScriptDir "dist"
$ExfiltratedLog = Join-Path $ScriptDir "attacks_simulation/exfiltrated_data.log"

if (Test-Path -LiteralPath $ExfiltratedLog) {
    Remove-Item -LiteralPath $ExfiltratedLog -Force
}

if ($Clean) {
    if (Test-Path -LiteralPath $DistDir) {
        Remove-Item -LiteralPath $DistDir -Recurse -Force
    }
    Write-Host "[OK] Artefatos do Laboratorio 02 limpos com sucesso!" -ForegroundColor Green
    exit 0
}

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " INICIALIZANDO AMBIENTE DO LABORATORIO 02 (DEPENDENCIAS & SBOM)    " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# 1. Garantir pasta dist/
if (-not (Test-Path -LiteralPath $DistDir)) {
    New-Item -ItemType Directory -Path $DistDir | Out-Null
    Write-Host "[*] Diretorio dist/ criado para armazenar relatorios e SBOMs." -ForegroundColor Green
}

# 2. Diagnóstico de Ferramental (Docker vs Host)
Write-Host "`n[*] Verificando ecossistema de execucao..." -ForegroundColor Yellow

$DockerFound = $false
try {
    $dockerVer = & docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $DockerFound = $true
        Write-Host " [OK] Docker detectado: $dockerVer" -ForegroundColor Green
    }
} catch {
    $DockerFound = $false
}

if ($DockerFound) {
    Write-Host "`n>>> MODO RECOMENDADO DISPONIVEL (CONTAINER):" -ForegroundColor Cyan
    Write-Host "    Para entrar no ambiente hermetico com todas as ferramentas instaladas, execute:" -ForegroundColor White
    Write-Host "    docker compose run --rm lab`n" -ForegroundColor Yellow
} else {
    Write-Host " [INFO] Docker nao detectado ou inativo. Execucao em modo Host direto." -ForegroundColor Cyan
    Write-Host "        Consulte SETUP_AMBIENTE.md para instrucoes detalhadas de instalacao." -ForegroundColor Cyan
}

Write-Host "------------------------------------------------------------------"
Write-Host "[OK] Ambiente do Laboratorio 02 pronto para execucao!" -ForegroundColor Green
Write-Host "Consulte README.md para iniciar o roteiro pratico."

