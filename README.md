# Laboratório Prático CLI: Governança de Dependências, SCA e Engenharia de SBOM

**Disciplina:** Supply Chain Security & DevSecOps Architecture (Ada Tech)  
**Foco:** Aulas 02 e 03 (Dependency Confusion, Lifecycle Hooks, Análise SCA com OSV-Scanner, Auditoria de Licenças Copyleft, Engenharia de SBOM com Syft e Trivy, CycloneDX 1.6, SPDX 3.0 e Conformidade NTIA / EO 14028)

---

## 1. Visão Geral do Laboratório

A integridade do software moderno depende de dois pilares complementares de governança de dependências:
1. **Segurança Ativa no Gerenciamento de Pacotes (Aula 02):** Proteger a esteira contra o sequestro de namespaces públicos (*Dependency Confusion*), neutralizar a execução de códigos maliciosos não autorizados durante a resolução de pacotes (*Lifecycle Scripts*) e detectar vulnerabilidades conhecidas (CVEs) e contaminação de licenças restritivas (*Copyleft*) com ferramentas reais de Software Composition Analysis (SCA).
2. **Transparência e Rastreabilidade Formal de Inventário (Aula 03):** Gerar, inspecionar e auditar **Software Bill of Materials (SBOM)** nos padrões oficiais da indústria (**SPDX** e **CycloneDX 1.6**) utilizando **Syft** e **Trivy**, catalogando desde dependências de aplicação até as camadas nativas de sistema operacional em imagens de container, garantindo conformidade com os 7 elementos mínimos exigidos pela **Executive Order 14028 (NTIA)**.

Neste laboratório hands-on, você atuará como Engenheiro Principal de DevSecOps, operando ferramentas profissionais de mercado diretamente na linha de comando.

---

## 2. Estrutura do Workspace

```text
lab_02_sbom_dependency_governance/
├── README.md                          # Este guia prático com roteiro passo a passo
├── SETUP_AMBIENTE.md                  # Instruções de setup (Modo Container vs Host)
├── .gitignore                         # Regras de exclusão para proteção e limpeza de repositório
├── .gitattributes                     # Preservação determinística de fim de linha LF
├── Dockerfile                         # Ambiente hermético com Syft, Trivy, OSV-Scanner, Docker CLI e Node.js
├── docker-compose.yml                 # Inicializador do container com 1 comando
├── setup_lab.ps1                      # Inicializador automático para Windows (PowerShell)
├── setup_lab.sh                       # Inicializador automático para Linux / macOS / WSL
├── clean_lab.ps1                      # Script de limpeza/reset completo para Windows (PowerShell)
├── clean_lab.sh                       # Script de limpeza/reset completo para Linux / macOS / Container
├── src/                               # Aplicação alvo (Microsserviço de Pagamentos)
│   ├── app.js                         # Código-fonte Express com manipulação de transações
│   ├── package.json                   # Manifesto de dependências com pacotes reais e licenças
│   ├── package-lock.json              # Lockfile determinístico com hashes SHA-512
│   └── .npmrc                         # Roteamento seguro de escopos corporativos
├── docker/                            # Infraestrutura de Container da Aplicação
│   └── Dockerfile.app                 # Imagem Alpine com camadas de SO e aplicação
├── attacks_simulation/                # Simulação controlada de ataques de dependência
│   └── malicious_lifecycle_pkg/       # Pacote demonstrando ataque via hook postinstall
│       ├── package.json
│       ├── inject.js
│       └── index.js
├── tools/                             # Ferramentas profissionais de auditoria
│   ├── ntia_validator.py              # Auditor dos 7 Elementos Mínimos do NTIA
│   └── license_audit.py               # Auditor de riscos de contaminação por Copyleft
└── dist/                              # Artefatos, relatórios de SCA e SBOMs gerados
```

---

## 3. Preparação do Ambiente (Setup) & Guia de Navegação no Terminal

Você pode executar este laboratório de **duas formas**:
- **Opção A (Recomendada — Via Container Docker):** Não requer instalação manual de nenhuma ferramenta na máquina física. Todas as 5 fases rodam dentro do container.
- **Opção B (Direto no Host):** Requer `syft`, `trivy`, `osv-scanner`, `jq`, `node` e `python3` instalados no seu `PATH` (veja instruções em [SETUP_AMBIENTE.md](./SETUP_AMBIENTE.md)).

### Como Saber Onde Você Está (Terminal Local vs. Container Docker)

Observe sempre o final do prompt do seu terminal:

| Prompt Exibido | Onde você está? | O que executar aqui? |
| :--- | :--- | :--- |
| `PS C:\...\lab_02_sbom_dependency_governance>` | 🖥️ **Terminal Local (Fora do Container)** | Apenas o `setup_lab`, o comando para entrar no container (`docker compose run...`) e a limpeza (`clean_lab`). |
| `62fcf3d8890e:/workspace#` *(termina com `#`)* | 🐳 **Dentro do Container do Laboratório** | **TODAS as 5 Fases do Laboratório (Fases 1, 2, 3, 4 e 5)!** Você não precisa sair do container em nenhum momento até concluir a Fase 5. |

---

### Passo 1: Inicialização do Workspace (🖥️ No seu Terminal Local)

Abra o terminal na pasta `lab_02_sbom_dependency_governance` e execute:

**No Windows (PowerShell):**
```powershell
.\setup_lab.ps1
```
*(Se o PowerShell bloquear a execução do script, rode: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; .\setup_lab.ps1`).*

**No Linux / macOS / WSL:**
```bash
chmod +x setup_lab.sh clean_lab.sh && ./setup_lab.sh
```

### Passo 2: Entrar no Container do Laboratório (🖥️ No seu Terminal Local)

Execute o comando abaixo para abrir o terminal interativo do container:

```powershell
docker compose run --rm --build lab
```

Assim que o prompt mudar para `:/workspace#`, você estará **dentro do container** e pronto para iniciar a Fase 1!

> 💡 **Dicas Rápidas (Como Sair e Como Limpar o Laboratório):**
> - **Para sair do container** ao terminar o laboratório (ou quando desejar voltar ao PowerShell): digite `exit` (ou pressione `Ctrl + D`).
> - **Para limpar/resetar todo o laboratório** (apagando os SBOMs gerados, logs e a imagem construída na Fase 4):
>   - De dentro do container (`:/workspace#`): `sh clean_lab.sh`
>   - De fora do container (PowerShell): `.\clean_lab.ps1`

---

## 4. Roteiro Prático Passo a Passo (5 Fases)

> 🐳 **Atenção:** Se você está usando o Modo Docker (Recomendado), execute **todas as 5 fases abaixo diretamente dentro do terminal do container (`:/workspace#`)**, sem precisar sair dele!

---

### Fase 1: O Ataque de Dependency Confusion & Injeção de Scripts de Ciclo de Vida

#### O Problema
No ataque de *Dependency Confusion* (documentado por Alex Birsan em 2021), gerenciadores de pacotes configurados sem escopo rígido consultam tanto o registro interno privado quanto o registro público (`npmjs.org`). Se um invasor registrar na internet um pacote público com o mesmo nome e uma versão mais alta (ex: `99.9.9`), o instalador baixa o pacote do invasor.

Pior: gerenciadores como o `npm` executam ganchos de ciclo de vida automáticos (`preinstall`, `postinstall`) com privilégios totais do usuário que executou o comando, permitindo roubo instantâneo de variáveis de ambiente.

#### Execução Prática (🐳 No prompt `:/workspace#`)

1. Inspecione o manifesto da aplicação em `src/package.json` com `jq`:
   ```bash
   jq . src/package.json
   ```
   *Observe:* O pacote `@corp/payment-vault` possui o prefixo de escopo corporativo `@corp`.

2. Inspecione como o arquivo `src/.npmrc` bloqueia o Dependency Confusion:
   ```bash
   grep -v '^#' src/.npmrc
   ```
   *Explicação:* A regra `@corp:registry=https://npm.corp.internal/` instrui o gerenciador a consultar **exclusivamente** o servidor privado para qualquer pacote `@corp/*`, impedindo que o `npm` consulte a internet pública para resolver esse namespace.

3. Agora, simule o que acontece quando um pacote malicioso usa o gancho `postinstall` para roubar segredos de ambiente durante a instalação. Entre na pasta da simulação:
   ```bash
   cd attacks_simulation/malicious_lifecycle_pkg
   ```

4. Simule uma instalação comum desprotegida:
   ```bash
   npm install
   ```
   *Observe com atenção:* O terminal exibe `[ALERTA CRÍTICO] Gancho POSTINSTALL malicioso executado com sucesso!`, mas logo abaixo o `npm` informa **`found 0 vulnerabilities`**. Isso ocorre porque o `npm audit` verifica apenas CVEs públicas conhecidas e é completamente cego para scripts maliciosos (*malware*) embutidos em ganchos de instalação!

5. Inspecione os segredos exfiltrados com `jq`:
   ```bash
   jq . ../exfiltrated_data.log
   ```
   *Resultado:* O `jq` revela o JSON com as variáveis capturadas (`USER`, `HOSTNAME`, `GITHUB_TOKEN`, `AWS_SECRET_ACCESS_KEY`, `NPM_TOKEN`, `HOME`, `PATH`).

6. Agora, execute o comando com a **prática mandatória de esteira DevSecOps blindada**:
   ```bash
   rm -f ../exfiltrated_data.log && npm install --ignore-scripts
   ```
   *Resultado:* A instalação ocorre normalmente, mas **nenhum código malicioso é executado**, e o arquivo `exfiltrated_data.log` não é criado.

7. Retorne para a raiz do laboratório (`/workspace`):
   ```bash
   cd ../..
   ```

---

### Fase 2: Análise de Composição de Software (SCA) & Auditoria de Licenças

#### O Problema
Mesmo que o código próprio da aplicação seja impecável, bibliotecas de terceiros trazem vulnerabilidades conhecidas (CVEs) e riscos jurídicos (contaminação por licenças Copyleft virais como GPL-3.0/AGPL em código proprietário fechado).

#### Execução Prática (🐳 No prompt `:/workspace#`)

1. Execute o **Google OSV-Scanner** diretamente contra o lockfile determinístico da aplicação:
   ```bash
   osv-scanner --lockfile=src/package-lock.json
   ```
   *Resultado da Análise:* O OSV-Scanner analisa os 4 pacotes do lockfile contra a base distribuída da OpenSSF/Google e aponta **6 vulnerabilidades** (2 no `express@4.18.2` e 4 no `lodash@4.17.20`, chegando a CVSS 8.1), exibindo links diretos para os advisories oficiais.

2. Execute o **Trivy** com foco em auditoria de licenças de código aberto:
   ```bash
   trivy fs --scanners license --format table src/
   ```
   *Resultado da Análise:* O Trivy classifica as licenças de cada pacote (`MIT` como `LOW`, `Proprietary` como `UNKNOWN`) e destaca a presença de `GPL-3.0` (`Restricted` / severidade `HIGH`) no pacote `gpl-math-lib`.

3. Execute a ferramenta de governança corporativa de licenças do laboratório:
   ```bash
   python3 tools/license_audit.py --sbom src/package-lock.json --fail-on-copyleft
   ```
   *Resultado:* O auditor alerta com `[FALHA DE COMPLIANCE]` devido ao risco de virilidade da GPL-3.0 em uma aplicação comercial proprietária, retornando código de erro para barrar a esteira no CI/CD.

---

### Fase 3: Engenharia de SBOM com Syft — CycloneDX 1.6 vs SPDX

#### O Problema
Como fornecer a clientes e auditores um "rótulo nutricional" formal e legível por máquina de todos os componentes do software sem depender de relatórios manuais em PDF?

#### Execução Prática (🐳 No prompt `:/workspace#`)

1. Utilize o **Syft** (Anchore) para gerar um SBOM completo do código-fonte no padrão **CycloneDX 1.6 (JSON)** (declarando explicitamente o nome e a versão do artefato-raiz):
   ```bash
   syft dir:src --source-name payment-api-service --source-version 1.0.0 -o cyclonedx-json=dist/sbom-app-cyclonedx.json
   ```

2. Gere o mesmo inventário no padrão internacional **SPDX (JSON)**:
   ```bash
   syft dir:src --source-name payment-api-service --source-version 1.0.0 -o spdx-json=dist/sbom-app-spdx.json
   ```

3. Compare o tamanho dos dois documentos gerados (`5.5K` no CycloneDX vs `10.1K` no SPDX):
   ```bash
   ls -lh dist/
   ```

4. Use o **`jq`** para inspecionar os metadados do SBOM CycloneDX (ferramenta geradora, timestamp e componente-raiz):
   ```bash
   jq '.metadata' dist/sbom-app-cyclonedx.json
   ```

5. Use o **`jq`** para listar o nome, a versão e o identificador universal **PURL (Package URL)** de cada um dos 5 componentes catalogados:
   ```bash
   jq '.components[] | {name: .name, version: .version, purl: .purl}' dist/sbom-app-cyclonedx.json
   ```
   *Conceito Chave:* O **PURL** (`pkg:npm/express@4.18.2`) é a string canônica que permite a qualquer ferramenta de segurança no mundo correlacionar o pacote com bases de vulnerabilidade de forma inequívoca.

---

### Fase 4: SBOM de Imagem de Container — Camadas de SO vs Aplicação

#### O Problema
Gerar SBOM apenas da pasta de código (`src/`) enxerga somente as dependências do Node.js. Mas e as vulnerabilidades do Linux, do `libcurl` e das bibliotecas do sistema operacional empacotadas no container que vai para a nuvem?

#### Execução Prática (🐳 Continue no prompt `:/workspace#` — não precisa sair do container!)

1. Construa a imagem de container da aplicação:
   ```bash
   docker build -f docker/Dockerfile.app -t payment-api:v1.0.0 .
   ```

2. Utilize o **Trivy** para gerar o SBOM formal da **imagem inteira de container**:
   ```bash
   trivy image --format cyclonedx --output dist/sbom-container-cyclonedx.json payment-api:v1.0.0
   ```

3. Conte a quantidade de componentes no SBOM apenas do código da aplicação:
   ```bash
   echo "Componentes da Aplicação:" && jq '.components | length' dist/sbom-app-cyclonedx.json
   ```
   *(Saída esperada: `5`)*

4. Agora, conte a quantidade de componentes no SBOM da Imagem de Container Completa (SO + Aplicação):
   ```bash
   echo "Componentes do Container Completo:" && jq '.components | length' dist/sbom-container-cyclonedx.json
   ```
   *(Saída esperada: `238`)*

5. Filtre com `jq` para visualizar os pacotes de sistema operacional (camada Alpine Linux `pkg:apk/`) catalogados no container:
   ```bash
   jq '.components[] | select(.purl? // "" | startswith("pkg:apk/")) | {name: .name, version: .version}' dist/sbom-container-cyclonedx.json | head -n 25
   ```
   *Conclusão Técnica:* Enquanto o código da aplicação possui 5 componentes, o container completo possui **238 componentes**, capturando pacotes nativos de infraestrutura (`alpine-baselayout`, `apk-tools`, `brotli-libs`, `libcurl`, `musl`, `busybox`) que nenhum scanner de código-fonte tradicional conseguiria detectar.

---

### Fase 5: Auditoria Regulatória NTIA (Executive Order 14028)

#### O Problema
A Ordem Executiva 14028 dos EUA e as diretrizes do NIST/NTIA estipulam que um SBOM só é legalmente válido se contiver os **7 Elementos Mínimos**:
1. *Supplier Name* (Nome do Fornecedor)
2. *Component Name* (Nome do Componente)
3. *Version String* (Versão do Componente)
4. *Unique Identifiers* (PURL / CPE)
5. *Dependency Relationship* (Relação e Grafo de Dependências)
6. *Author of SBOM Data* (Autor ou Ferramenta Geradora)
7. *Timestamp* (Carimbo de Data/Hora)

#### Execução Prática (🐳 No prompt `:/workspace#`)

1. Execute o validador regulatório do laboratório contra o SBOM gerado pelo Syft:
   ```bash
   python3 tools/ntia_validator.py --sbom dist/sbom-app-cyclonedx.json
   ```
   *Resultado Esperado:*
   ```text
   ========================================================================
    AUDITORIA DE CONFORMIDADE NTIA — 7 ELEMENTOS MÍNIMOS (EO 14028)        
   ========================================================================
   Arquivo Auditado: dist/sbom-app-cyclonedx.json
   Padrão Detectado: CycloneDX v1.6

    [CONFORME]  1. Supplier Name (Fornecedor)
    [CONFORME]  2. Component Name (Nome do Componente)
    [CONFORME]  3. Version String (Versão)
    [CONFORME]  4. Unique Identifiers (PURL / CPE)
    [CONFORME]  5. Dependency Relationships (Grafo de Dependências)
    [CONFORME]  6. Author of SBOM Metadata (Autor/Ferramenta)
    [CONFORME]  7. Timestamp (Carimbo de Data/Hora)

   Conformidade Geral: 7/7 (100.0%)

   [STATUS FINAL] APROVADO — O SBOM cumpre 100% dos requisitos mínimos regulatórios.
   ```

2. Simule a rejeição em esteira de um SBOM deficiente fornecido por um terceiro. Crie e audite um SBOM incompleto de teste:
   ```bash
   echo '{"bomFormat":"CycloneDX","specVersion":"1.6","components":[{"name":"unknown-pkg"}]}' > dist/sbom-invalido.json && python3 tools/ntia_validator.py --sbom dist/sbom-invalido.json
   ```
   *Resultado Esperado:* O validador aponta `Conformidade Geral: 1/7 (14.3%)`, lista as 6 deficiências regulatórias e reprova com código de saída `2`, bloqueando a ingestão de pacotes opacos de terceiros na esteira corporativa.

3. Ao concluir todas as fases, saia do container para retornar ao seu terminal local:
   ```bash
   exit
   ```

---

## 5. Questões Técnicas de Autoavaliação e Fixação

Ao finalizar a execução prática, consolide seu aprendizado respondendo tecnicamente às seguintes questões:

1. **Como o mecanismo de resolução de dependências no ecossistema npm prioriza pacotes quando um escopo (`@empresa`) não é explicitamente declarado e por que o uso do `.npmrc` com roteamento estrito de registros mitiga o risco de *Dependency Confusion*?**
2. **Qual é o vetor de ataque explorado por pacotes maliciosos que definem o gancho `postinstall` no `package.json`, por que o `npm audit` reporta `0 vulnerabilities` mesmo diante desse ataque, e de que forma a instrução `npm ci --ignore-scripts` neutraliza esse risco em esteiras de CI/CD?**
3. **Qual a diferença fundamental de escopo e visibilidade entre um SBOM gerado a partir do código-fonte (`syft dir:src`) e um SBOM gerado a partir de uma imagem de container (`trivy image ...`)? Cite exemplos práticos de componentes visíveis apenas no segundo.**
4. **O que é uma Package URL (PURL) e qual a sua função crítica para a interoperabilidade entre ferramentas de SBOM (como Syft e Trivy) e bancos de dados de vulnerabilidades (como o Google OSV e o NVD)?**
5. **No contexto da conformidade com a Executive Order 14028 e o framework NTIA, por que um SBOM que omite o grafo de relacionamentos (*Dependency Relationships*) ou o carimbo de data/hora (*Timestamp*) é considerado tecnicamente reprovado?**

> 💡 **Critérios de Autoavaliação:** Ao formular suas respostas, utilize as evidências coletadas nas 5 fases do laboratório (hashes, PURLs extraídas com `jq`, saídas do OSV-Scanner e relatórios do NTIA Validator) para fundamentar as justificativas técnicas.
