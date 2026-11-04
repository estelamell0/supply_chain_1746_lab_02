# ==============================================================================
# Dockerfile — Ambiente Integrado do Laboratório 02 (Supply Chain Security)
# Fornece todas as ferramentas da indústria pré-instaladas:
# - Syft (Anchore) — Engenharia de SBOM (CycloneDX 1.6 & SPDX 3.0)
# - Trivy (Aqua Security) — Scanner de Vulnerabilidades e Licenças
# - OSV-Scanner (Google) — Auditoria de CVEs baseada em ecossistemas abertos
# - Node.js 18 + npm — Gerenciamento de dependências e lockfiles
# - Python 3 + pip — Execução de scripts de auditoria e validação NTIA
# - jq & curl — Manipulação cirúrgica de JSON e chamadas de API
# ==============================================================================

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 1. Instalar dependências essenciais do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    gnupg \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Instalar Syft (Anchore) — Ferramenta oficial para geração de SBOM
RUN curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin v1.19.0

# 3. Instalar Trivy (Aqua Security) — Scanner de SBOM, vulnerabilidades e licenças
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.58.2

# 4. Instalar OSV-Scanner (Google) — Detecção de vulnerabilidades via Open Source Vulnerabilities
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then OSV_ARCH="amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then OSV_ARCH="arm64"; \
    else OSV_ARCH="amd64"; fi && \
    curl -fsSL "https://github.com/google/osv-scanner/releases/download/v1.9.2/osv-scanner_linux_${OSV_ARCH}" -o /usr/local/bin/osv-scanner && \
    chmod +x /usr/local/bin/osv-scanner

# 5. Configurar diretório de trabalho compartilhado
WORKDIR /workspace

# 6. Inicialização padrão
CMD ["/bin/bash"]

