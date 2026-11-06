# ==============================================================================
# Dockerfile.app — Imagem de Release do Microsserviço de Pagamentos
# Usado na Fase 4 do Lab 02 para demonstrar o SBOM em camadas (OS + Aplicação).
# ==============================================================================

FROM node:18-alpine

WORKDIR /app

# Instalar pacotes de sistema adicionais (simulando requisitos de infraestrutura)
RUN apk add --no-cache curl ca-certificates dumb-init

# Copiar manifestos, lockfile determinístico e árvore de pacotes
COPY src/ ./

# Executar como usuário não-root (boa prática DevSecOps)
USER node

EXPOSE 3000

ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "app.js"]
