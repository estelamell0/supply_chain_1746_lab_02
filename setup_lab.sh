#!/usr/bin/env bash
# Script de Inicialização e Reset do Laboratório 02 de Supply Chain Security
# Bash Native Driver para Linux / macOS / WSL / Git Bash (100% paridade com setup_lab.ps1).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

DIST_DIR="$SCRIPT_DIR/dist"
NODE_MODULES_DIR="$SCRIPT_DIR/src/node_modules"
EXFIL_LOG="$SCRIPT_DIR/attacks_simulation/exfiltrated_data.log"

# Limpeza
rm -f "$EXFIL_LOG"

if [[ "${1:-}" == "--clean" || "${1:-}" == "-Clean" ]]; then
    rm -rf "$DIST_DIR" "$NODE_MODULES_DIR"
    echo "[OK] Artefatos do Laboratório 02 limpos com sucesso!"
    exit 0
fi

echo "=================================================================="
echo " INICIALIZANDO AMBIENTE DO LABORATÓRIO 02 (DEPENDÊNCIAS & SBOM)    "
echo "=================================================================="

# 1. Garantir pasta dist/
mkdir -p "$DIST_DIR"
echo "[*] Diretório dist/ preparado para armazenar relatórios e SBOMs."

# 2. Preparar árvore de metadados offline em src/node_modules (para Trivy License & Syft SBOM)
mkdir -p "$NODE_MODULES_DIR/express" "$NODE_MODULES_DIR/lodash" "$NODE_MODULES_DIR/gpl-math-lib" "$NODE_MODULES_DIR/@corp/payment-vault"

cat << 'EOF' > "$NODE_MODULES_DIR/express/package.json"
{
  "name": "express",
  "version": "4.18.2",
  "license": "MIT",
  "author": "TJ Holowaychuk"
}
EOF

cat << 'EOF' > "$NODE_MODULES_DIR/lodash/package.json"
{
  "name": "lodash",
  "version": "4.17.20",
  "license": "MIT",
  "author": "John-David Dalton"
}
EOF

cat << 'EOF' > "$NODE_MODULES_DIR/gpl-math-lib/package.json"
{
  "name": "gpl-math-lib",
  "version": "1.0.0",
  "license": "GPL-3.0",
  "author": "Free Software Math Group"
}
EOF

cat << 'EOF' > "$NODE_MODULES_DIR/@corp/payment-vault/package.json"
{
  "name": "@corp/payment-vault",
  "version": "1.0.0",
  "license": "Proprietary",
  "author": "Corp FinTech Security"
}
EOF
echo "[*] Árvore de metadados de pacotes sincronizada em src/node_modules/."

# 3. Diagnóstico de Ferramental
echo ""
echo "[*] Verificando ecossistema de execução..."

if command -v docker &> /dev/null; then
    DOCKER_VER=$(docker --version)
    echo " [OK] Docker detectado: $DOCKER_VER"
    echo ""
    echo ">>> MODO RECOMENDADO DISPONÍVEL (CONTAINER):"
    echo "    Para entrar no ambiente hermético com todas as ferramentas instaladas, execute:"
    echo "    docker compose run --rm --build lab"
    echo ""
else
    echo " [INFO] Docker não detectado ou inativo. Execução em modo Host direto."
    echo "        Consulte SETUP_AMBIENTE.md para instruções detalhadas de instalação."
fi

# Tornar scripts executáveis
chmod +x tools/*.py attacks_simulation/malicious_lifecycle_pkg/*.js 2>/dev/null || true

echo "------------------------------------------------------------------"
echo "[OK] Ambiente do Laboratório 02 pronto para execução!"
echo "Consulte README.md para iniciar o roteiro prático."
