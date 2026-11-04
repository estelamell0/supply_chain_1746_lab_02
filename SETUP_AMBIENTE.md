# Guia de Configuração de Ambiente — Laboratório 02

Este laboratório utiliza **ferramentas reais de mercado** para engenharia de SBOM e auditoria de dependências:
- **Syft** (Anchore)
- **Trivy** (Aqua Security)
- **OSV-Scanner** (Google)
- **Node.js 18+** e **Python 3.10+**
- **jq**

Para máxima produtividade e zero conflitos de dependências no seu sistema operacional, disponibilizamos **dois modos de execução**:

---

## Modo 1: Via Container Docker (Recomendado — Zero Fricção)

Se você possui o **Docker Desktop** (ou Docker Engine no Linux) instalado, você **não precisa instalar nenhuma ferramenta no seu computador**.

O repositório já inclui um `Dockerfile` e um `docker-compose.yml` que provisionam um container Linux contendo todas as ferramentas configuradas e prontas para uso.

### Passo a Passo (Docker):

1. Abra o terminal na pasta do laboratório:
   ```bash
   cd curso_supply_chain_security/03_exercicios/lab_02_sbom_dependency_governance
   ```

2. Execute o setup inicial para criar pastas de saída:
   ```bash
   # No Windows (PowerShell):
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\setup_lab.ps1

   # No Linux / macOS:
   chmod +x setup_lab.sh && ./setup_lab.sh
   ```

3. Inicie o container de trabalho interativo:
   ```bash
   docker compose run --rm lab
   ```

4. Pronto! O terminal agora está dentro do container `/workspace`. O volume está montado na sua pasta local, portanto todos os SBOMs e relatórios gerados serão salvos na sua máquina física em tempo real.

---

## Modo 2: Execução Direta no Host (Sem Docker)

Caso você não utilize Docker, as ferramentas podem ser instaladas diretamente no seu sistema operacional:

### 1. Syft (Anchore)
- **Windows (PowerShell como Admin via WinGet ou Scoop):**
  ```powershell
  winget install Anchore.Syft
  # ou via Scoop:
  scoop install syft
  ```
- **Linux:**
  ```bash
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo sh -s -- -b /usr/local/bin
  ```
- **macOS (Homebrew):**
  ```bash
  brew install syft
  ```
- **Validação:** `syft --version`

---

### 2. Trivy (Aqua Security)
- **Windows (PowerShell como Admin via WinGet ou Scoop):**
  ```powershell
  winget install AquaSecurity.Trivy
  # ou via Scoop:
  scoop install trivy
  ```
- **Linux (Debian/Ubuntu):**
  ```bash
  sudo apt-get install wget apt-transport-https gnupg lsb-release
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
  echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
  sudo apt-get update && sudo apt-get install -y trivy
  ```
- **macOS (Homebrew):**
  ```bash
  brew install aquasecurity/trivy/trivy
  ```
- **Validação:** `trivy --version`

---

### 3. OSV-Scanner (Google)
- **Windows / Linux / macOS (via Go ou Binário Oficial):**
  - Baixe o binário para o seu sistema em: [github.com/google/osv-scanner/releases](https://github.com/google/osv-scanner/releases)
  - Renomeie para `osv-scanner` (ou `osv-scanner.exe`) e coloque em uma pasta contida no seu `PATH`.
  - Se você já tiver Go instalado:
    ```bash
    go install github.com/google/osv-scanner/cmd/osv-scanner@latest
    ```
- **Validação:** `osv-scanner --version`

---

### 4. Node.js e Python
- **Node.js 18+:** `node --version` (disponível em [nodejs.org](https://nodejs.org/)).
- **Python 3.10+:** `python --version` (disponível em [python.org](https://www.python.org/)).

---

## Checklist de Validação Final

Antes de iniciar as 5 fases do laboratório, execute no terminal (seja no container ou no host):

```bash
syft --version
trivy --version
osv-scanner --version
node --version
python --version # ou python3 --version
```

Com essas ferramentas respondendo com sucesso, seu ambiente está 100% pronto para iniciar o [README.md](./README.md).

