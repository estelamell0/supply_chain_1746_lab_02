# ==============================================================================
# Dockerfile — Ambiente Integrado do Laboratório 02 (Supply Chain Security)
# Baseado em Alpine Linux (musl) + Multi-Stage Copy para máxima velocidade
# e imunidade ao bug de DNS dual-stack (glibc/192.168.65.7) no Docker Desktop.
#
# Ferramentas incluídas:
# - Syft v1.19.0 (Anchore) — Engenharia de SBOM (CycloneDX 1.6 & SPDX 3.0)
# - Trivy v0.58.2 (Aqua Security) — Scanner de Vulnerabilidades, Imagens e Licenças
# - OSV-Scanner v1.9.2 (Google) — Auditoria de CVEs baseada em ecossistemas abertos
# - Node.js 18 + npm — Gerenciamento de dependências e lockfiles
# - Python 3 — Execução de scripts de auditoria e validação NTIA
# - Docker CLI + jq + git + bash — Ferramental completo de DevSecOps
# ==============================================================================

FROM anchore/syft:v1.19.0 AS syft_bin
FROM aquasec/trivy:0.58.2 AS trivy_bin

FROM node:18-alpine

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SYFT_CHECK_FOR_APP_UPDATE=false
ENV TRIVY_SKIP_VERSION_CHECK=true
ENV TRIVY_DISABLE_TELEMETRY=true

# 1. Instalar utilitários essenciais do sistema via APK (rápido e resiliente a DNS)
RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    wget \
    git \
    jq \
    python3 \
    docker-cli \
    tar \
    gzip

# 2. Copiar binários oficiais do Syft e Trivy via Multi-Stage (zero risco de curl | sh falhar)
COPY --from=syft_bin /syft /usr/local/bin/syft
COPY --from=trivy_bin /usr/local/bin/trivy /usr/local/bin/trivy

# 3. Instalar OSV-Scanner (binário estático Go compatível com Alpine)
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then OSV_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then OSV_ARCH="arm64"; \
    else OSV_ARCH="amd64"; fi && \
    curl -fsSL "https://github.com/google/osv-scanner/releases/download/v1.9.2/osv-scanner_linux_${OSV_ARCH}" -o /usr/local/bin/osv-scanner && \
    chmod +x /usr/local/bin/osv-scanner

# 4. Configurar diretório de trabalho compartilhado
WORKDIR /workspace

# 5. Inicialização padrão com Bash interativo
CMD ["/bin/bash"]
