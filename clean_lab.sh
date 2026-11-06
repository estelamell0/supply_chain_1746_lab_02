#!/usr/bin/env bash
# ==============================================================================
# Script de Limpeza e Reset Completo do Laboratorio 02 (Dependencias & SBOM)
# Pode ser executado tanto no Host (Linux/macOS/WSL) quanto dentro do Container!
# ==============================================================================
set -e

PURGE_ALL=false
if [ "${1:-}" = "--purge-images" ] || [ "${1:-}" = "--all" ]; then
    PURGE_ALL=true
fi

echo "=================================================================="
echo " LIMPANDO AMBIENTE DO LABORATORIO 02 (RESET PARA ESTADO INICIAL)  "
echo "=================================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 1. Limpeza de artefatos gerados em dist/
mkdir -p dist
rm -rf dist/*.json dist/*.spdx dist/*.cdx dist/*.txt dist/*.log 2>/dev/null || true
echo "[OK] Artefatos de SBOM e relatorios em dist/ removidos."

# 2. Limpeza de rastros da Fase 1 (Simulacao de Ataque)
rm -f attacks_simulation/exfiltrated_data.log
rm -f attacks_simulation/malicious_lifecycle_pkg/package-lock.json
rm -rf attacks_simulation/malicious_lifecycle_pkg/node_modules
echo "[OK] Logs de exfiltracao e artefatos da Fase 1 removidos."

# 3. Limpeza de caches Python
rm -rf tools/__pycache__

# 4. Limpeza cuidadosa do Docker
if command -v docker >/dev/null 2>&1; then
    echo ""
    echo "[*] Limpando recursos Docker do Laboratorio 02..."

    # Remover a imagem da aplicacao construida na Fase 4 (payment-api:v1.0.0)
    if [ -n "$(docker images -q payment-api:v1.0.0 2>/dev/null)" ]; then
        docker rmi -f payment-api:v1.0.0 >/dev/null 2>&1 || true
        echo " [OK] Imagem da Fase 4 (payment-api:v1.0.0) removida."
    else
        echo " [OK] Imagem payment-api:v1.0.0 ja estava limpa."
    fi

    # Se estiver rodando no Host (fora do container), limpa tambem containers remanescentes
    if [ ! -f /.dockerenv ]; then
        docker compose down --remove-orphans >/dev/null 2>&1 || true
        CONTAINERS=$(docker ps -a --filter "ancestor=supply-chain-lab02:latest" -q 2>/dev/null || true)
        if [ -n "$CONTAINERS" ]; then
            docker rm -f $CONTAINERS >/dev/null 2>&1 || true
            echo " [OK] Containers ativos/parados do Lab 02 removidos."
        fi

        if [ "$PURGE_ALL" = true ]; then
            docker rmi -f supply-chain-lab02:latest >/dev/null 2>&1 || true
            echo " [OK] Imagem base (supply-chain-lab02:latest) removida (--purge-images)."
        else
            echo " [i] Imagem base 'supply-chain-lab02:latest' mantida em cache para inicio instantaneo."
        fi
    else
        echo " [i] Executado de dentro do container: arquivos e imagem 'payment-api:v1.0.0' resetados sem encerrar sua sessao atual!"
    fi
fi

echo "------------------------------------------------------------------"
echo "[OK] Laboratorio 02 100% limpo e pronto para uma nova execucao!"

