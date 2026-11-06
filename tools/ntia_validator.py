#!/usr/bin/env python3
"""
Validador de Conformidade com os 7 Elementos Mínimos do NTIA (EO 14028)
Suporta SBOMs em padrão CycloneDX (JSON) e SPDX (JSON).
"""

import argparse
import json
import sys
from typing import Dict, Any, List

# Códigos ANSI para saída formatada no terminal
CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
RED = "\033[1;31m"
RESET = "\033[0m"
BOLD = "\033[1m"


class NtiaSbomValidator:
    def __init__(self, sbom_path: str):
        self.sbom_path = sbom_path
        self.data: Dict[str, Any] = {}
        self.format_type = "UNKNOWN"
        self.results: Dict[str, bool] = {
            "1. Supplier Name (Fornecedor)": False,
            "2. Component Name (Nome do Componente)": False,
            "3. Version String (Versão)": False,
            "4. Unique Identifiers (PURL / CPE)": False,
            "5. Dependency Relationships (Grafo de Dependências)": False,
            "6. Author of SBOM Metadata (Autor/Ferramenta)": False,
            "7. Timestamp (Carimbo de Data/Hora)": False,
        }
        self.deficiencies: List[str] = []

    def load(self) -> bool:
        try:
            with open(self.sbom_path, "r", encoding="utf-8") as f:
                self.data = json.load(f)

            if "bomFormat" in self.data and str(self.data["bomFormat"]).lower() == "cyclonedx":
                self.format_type = f"CycloneDX v{self.data.get('specVersion', '1.x')}"
            elif "spdxVersion" in self.data:
                self.format_type = f"SPDX {self.data.get('spdxVersion', '2.x/3.x')}"
            else:
                self.format_type = "Generic JSON"
            return True
        except Exception as e:
            print(f"{RED}[ERRO]{RESET} Falha ao carregar arquivo de SBOM: {e}", file=sys.stderr)
            return False

    def validate(self) -> bool:
        if "bomFormat" in self.data and str(self.data["bomFormat"]).lower() == "cyclonedx":
            return self._validate_cyclonedx()
        elif "spdxVersion" in self.data:
            return self._validate_spdx()
        else:
            self.deficiencies.append("Formato não reconhecido como CycloneDX ou SPDX oficial.")
            return False

    def _validate_cyclonedx(self) -> bool:
        meta = self.data.get("metadata", {})
        components = self.data.get("components", [])

        # 1. Supplier (explícito ou inferido de namespace PURL/CPE/Tools)
        has_supplier = any(
            c.get("supplier") or c.get("publisher") or c.get("author") or c.get("group") or c.get("cpe")
            for c in components
        )
        if meta.get("supplier") or meta.get("manufacture") or meta.get("tools"):
            has_supplier = True
        self.results["1. Supplier Name (Fornecedor)"] = has_supplier
        if not has_supplier:
            self.deficiencies.append("Nenhum fornecedor/autor (supplier/publisher) encontrado nos metadados ou componentes.")

        # 2. Component Name
        has_names = len(components) > 0 and all("name" in c and bool(c["name"]) for c in components)
        self.results["2. Component Name (Nome do Componente)"] = has_names
        if not has_names:
            self.deficiencies.append("Existem componentes sem campo 'name' definido.")

        # 3. Version String
        has_versions = len(components) > 0 and all("version" in c and bool(c["version"]) for c in components)
        self.results["3. Version String (Versão)"] = has_versions
        if not has_versions:
            self.deficiencies.append("Existem componentes sem campo 'version' definido.")

        # 4. Unique Identifiers (PURL ou CPE)
        has_purls = len(components) > 0 and any("purl" in c or "cpe" in c for c in components)
        self.results["4. Unique Identifiers (PURL / CPE)"] = has_purls
        if not has_purls:
            self.deficiencies.append("Nenhum identificador universal (PURL ou CPE) encontrado nos componentes.")

        # 5. Dependency Relationships (Grafo explícito ou referências bom-ref vinculadas ao root component)
        has_deps = ("dependencies" in self.data and len(self.data.get("dependencies", [])) > 0) or (
            bool(meta.get("component")) and len(components) > 0 and all("bom-ref" in c for c in components)
        )
        self.results["5. Dependency Relationships (Grafo de Dependências)"] = has_deps
        if not has_deps:
            self.deficiencies.append("Seção 'dependencies' ausente ou vazia (falha no mapeamento de relações).")

        # 6. Author of SBOM
        has_author = bool(meta.get("authors")) or bool(meta.get("tools"))
        self.results["6. Author of SBOM Metadata (Autor/Ferramenta)"] = has_author
        if not has_author:
            self.deficiencies.append("Metadados não especificam 'authors' nem 'tools' geradoras.")

        # 7. Timestamp
        has_timestamp = bool(meta.get("timestamp"))
        self.results["7. Timestamp (Carimbo de Data/Hora)"] = has_timestamp
        if not has_timestamp:
            self.deficiencies.append("Metadados não possuem 'timestamp' ISO-8601 de geração.")

        return all(self.results.values())

    def _validate_spdx(self) -> bool:
        packages = self.data.get("packages", [])
        creation = self.data.get("creationInfo", {})

        # 1. Supplier
        has_supplier = any(p.get("supplier") or p.get("originator") for p in packages) or bool(creation.get("creators"))
        self.results["1. Supplier Name (Fornecedor)"] = has_supplier
        if not has_supplier:
            self.deficiencies.append("Nenhum 'supplier' ou 'originator' especificado nos pacotes SPDX.")

        # 2. Name
        has_names = len(packages) > 0 and all("name" in p for p in packages)
        self.results["2. Component Name (Nome do Componente)"] = has_names
        if not has_names:
            self.deficiencies.append("Existem pacotes SPDX sem campo 'name'.")

        # 3. Version
        has_versions = len(packages) > 0 and all("versionInfo" in p for p in packages)
        self.results["3. Version String (Versão)"] = has_versions
        if not has_versions:
            self.deficiencies.append("Existem pacotes SPDX sem campo 'versionInfo'.")

        # 4. Identifiers
        has_ids = any(
            any(ref.get("referenceType", "").endswith("purl") or "cpe" in ref.get("referenceType", "")
                for ref in p.get("externalRefs", []))
            for p in packages
        )
        self.results["4. Unique Identifiers (PURL / CPE)"] = has_ids
        if not has_ids:
            self.deficiencies.append("Nenhum externalRef do tipo PURL ou CPE encontrado nos pacotes.")

        # 5. Relationships
        has_relationships = len(self.data.get("relationships", [])) > 0
        self.results["5. Dependency Relationships (Grafo de Dependências)"] = has_relationships
        if not has_relationships:
            self.deficiencies.append("Seção 'relationships' ausente ou vazia no documento SPDX.")

        # 6. Author
        has_creators = len(creation.get("creators", [])) > 0
        self.results["6. Author of SBOM Metadata (Autor/Ferramenta)"] = has_creators
        if not has_creators:
            self.deficiencies.append("'creationInfo.creators' ausente.")

        # 7. Timestamp
        has_created = bool(creation.get("created"))
        self.results["7. Timestamp (Carimbo de Data/Hora)"] = has_created
        if not has_created:
            self.deficiencies.append("'creationInfo.created' ausente.")

        return all(self.results.values())

    def print_report(self):
        print(f"\n{BOLD}{CYAN}========================================================================{RESET}")
        print(f"{BOLD}{CYAN} AUDITORIA DE CONFORMIDADE NTIA — 7 ELEMENTOS MÍNIMOS (EO 14028)        {RESET}")
        print(f"{BOLD}{CYAN}========================================================================{RESET}")
        print(f"Arquivo Auditado: {BOLD}{self.sbom_path}{RESET}")
        print(f"Padrão Detectado: {BOLD}{self.format_type}{RESET}\n")

        passed_count = sum(1 for v in self.results.values() if v)
        total_count = len(self.results)
        score_percent = (passed_count / total_count) * 100

        for elem, passed in self.results.items():
            status = f"{GREEN}[CONFORME]{RESET}" if passed else f"{RED}[DEFICIENTE]{RESET}"
            print(f" {status}  {elem}")

        print(f"\n{BOLD}Conformidade Geral:{RESET} {passed_count}/{total_count} ({score_percent:.1f}%)")

        if self.deficiencies:
            print(f"\n{YELLOW}{BOLD}Apontamentos de Auditoria & Não Conformidades:{RESET}")
            for d in self.deficiencies:
                print(f" - {d}")

        if score_percent == 100.0:
            print(f"\n{GREEN}{BOLD}[STATUS FINAL] APROVADO — O SBOM cumpre 100% dos requisitos mínimos regulatórios.{RESET}\n")
        else:
            print(f"\n{RED}{BOLD}[STATUS FINAL] REPROVADO — O documento não atende aos requisitos da EO 14028.{RESET}\n")


def main():
    parser = argparse.ArgumentParser(description="Validador de SBOM NTIA Minimum Elements")
    parser.add_argument("--sbom", required=True, help="Caminho para o arquivo JSON do SBOM (CycloneDX ou SPDX)")
    args = parser.parse_args()

    validator = NtiaSbomValidator(args.sbom)
    if not validator.load():
        sys.exit(1)

    is_compliant = validator.validate()
    validator.print_report()

    sys.exit(0 if is_compliant else 2)


if __name__ == "__main__":
    main()
