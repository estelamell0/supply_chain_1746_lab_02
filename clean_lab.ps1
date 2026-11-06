<#
.SYNOPSIS
    Script de Limpeza e Reset Completo do Laboratorio 02 (Dependencias & SBOM)
.DESCRIPTION
    Remove todos os artefatos gerados (SBOMs, logs de exfiltracao, caches) e limpa
    containers/imagens Docker criados durante o laboratorio, deixando o ambiente
    100% zerado para uma nova execucao ou demonstracao em aula.
.PARAMETER FullDockerPurge
    Se informado, remove tambem a imagem base do laboratorio (supply-chain-lab02:latest).
    Por padrao, apenas a imagem do exercicio (payment-api:v1.0.0) e os containers sao removidos
    para manter a reentrada rapida na aula.
#>
param(
    [switch]$FullDockerPurge
)

$ErrorActionPreference = "Continue"

Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host " LIMPANDO AMBIENTE DO LABORATORIO 02 (RESET PARA ESTADO INICIAL)  " -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

$LabRoot = $PSScriptRoot
Set-Location -Path $LabRoot

# 1. Limpeza de artefatos gerados em dist/
if (Test-Path -Path "dist") {
    Get-ChildItem -Path "dist" -File -Recurse | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Artefatos de SBOM e relatorios em dist/ removidos." -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path "dist" | Out-Null
    Write-Host "[OK] Diretorio dist/ recriado vazio." -ForegroundColor Green
}

# 2. Limpeza de rastros da Fase 1 (Simulacao de Ataque)
$AttackFiles = @(
    "attacks_simulation\exfiltrated_data.log",
    "attacks_simulation\malicious_lifecycle_pkg\package-lock.json",
    "attacks_simulation\malicious_lifecycle_pkg\node_modules"
)
foreach ($item in $AttackFiles) {
    if (Test-Path -Path $item) {
        Remove-Item -Path $item -Recurse -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "[OK] Logs de exfiltracao e artefatos da Fase 1 removidos." -ForegroundColor Green

# 3. Limpeza de caches Python
if (Test-Path -Path "tools\__pycache__") {
    Remove-Item -Path "tools\__pycache__" -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Limpeza cuidadosa do Docker (Containers e Imagens do Lab)
$DockerCmd = Get-Command docker -ErrorAction SilentlyContinue
if ($null -ne $DockerCmd) {
    Write-Host ""
    Write-Host "[*] Limpando recursos Docker do Laboratorio 02..." -ForegroundColor Yellow

    # Encerrar servicos do docker compose e containers orfaos deste diretorio
    docker compose down --remove-orphans 2>$null | Out-Null

    # Remover eventuais containers interativos remanescentes criados via 'docker compose run'
    $RunningContainers = docker ps -a --filter "ancestor=supply-chain-lab02:latest" -q 2>$null
    if ($RunningContainers) {
        docker rm -f $RunningContainers 2>$null | Out-Null
        Write-Host " [OK] Containers ativos/parados do Lab 02 removidos." -ForegroundColor Green
    } else {
        Write-Host " [OK] Nenhum container residual do Lab 02 encontrado." -ForegroundColor Green
    }

    # Remover a imagem da aplicacao construida na Fase 4 (payment-api:v1.0.0)
    $AppImage = docker images -q payment-api:v1.0.0 2>$null
    if ($AppImage) {
        docker rmi -f payment-api:v1.0.0 2>$null | Out-Null
        Write-Host " [OK] Imagem da Fase 4 (payment-api:v1.0.0) removida." -ForegroundColor Green
    } else {
        Write-Host " [OK] Imagem payment-api:v1.0.0 ja estava limpa." -ForegroundColor Green
    }

    # Opcional: Remover tambem a imagem de ferramentas do Lab 02
    if ($FullDockerPurge) {
        $LabImage = docker images -q supply-chain-lab02:latest 2>$null
        if ($LabImage) {
            docker rmi -f supply-chain-lab02:latest 2>$null | Out-Null
            Write-Host " [OK] Imagem base (supply-chain-lab02:latest) removida (-FullDockerPurge)." -ForegroundColor Green
        }
    } else {
        Write-Host " [i] Imagem base 'supply-chain-lab02:latest' mantida em cache para inicio instantaneo." -ForegroundColor DarkGray
        Write-Host "     (Use '.\clean_lab.ps1 -FullDockerPurge' se quiser apaga-la tambem)." -ForegroundColor DarkGray
    }
}

Write-Host "------------------------------------------------------------------" -ForegroundColor Cyan
Write-Host "[OK] Laboratorio 02 100% limpo e pronto para uma nova execucao!" -ForegroundColor Green
Write-Host "Para entrar novamente no container: docker compose run --rm lab" -ForegroundColor White

