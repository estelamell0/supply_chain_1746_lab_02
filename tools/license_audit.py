#!/usr/bin/env python3
"""
Auditor de Licenças de Código Aberto (Open Source License Governance)
Analisa CycloneDX ou SPDX para detectar riscos de contaminação por Copyleft (GPL/AGPL).
"""

import argparse
import json
import sys
from typing import Dict, Any, List

CYAN = "\033[1;36m"
GREEN = "\033[1;32m"
YELLOW = "\033[1;33m"
RED = "\033[1;31m"
RESET = "\033[0m"
BOLD = "\033[1m"

PERMISSIVE_LICENSES = {"mit", "apache-2.0", "bsd-2-clause", "bsd-3-clause", "isc", "cc0-1.0", "unlicense"}
WEAK_COPYLEFT = {"lgpl-2.1", "lgpl-3.0", "mpl-2.0", "epl-2.0"}
STRONG_COPYLEFT = {"gpl-2.0", "gpl-3.0", "agpl-3.0", "gpl-2.0-only", "gpl-3.0-only", "agpl-3.0-only", "sspl"}


def analyze_cyclonedx(data: Dict[str, Any]) -> List[Dict[str, str]]:
    findings = []
    components = data.get("components", [])

    for c in components:
        name = c.get("name", "unknown")
        version = c.get("version", "unknown")
        purl = c.get("purl", f"pkg:generic/{name}@{version}")

        licenses_list = []
        for lic_entry in c.get("licenses", []):
            if "license" in lic_entry:
                lic_obj = lic_entry["license"]
                lic_id = lic_obj.get("id") or lic_obj.get("name") or "NOASSERTION"
                licenses_list.append(lic_id)
            elif "expression" in lic_entry:
                licenses_list.append(lic_entry["expression"])

        if not licenses_list:
            licenses_list = ["UNKNOWN"]

        for lic in licenses_list:
            lic_clean = lic.lower().strip()
            if lic_clean in STRONG_COPYLEFT:
                risk = "CRITICAL (Strong Copyleft / Virality Risk)"
            elif lic_clean in WEAK_COPYLEFT:
                risk = "MEDIUM (Weak Copyleft / Boundary Restriction)"
            elif lic_clean in PERMISSIVE_LICENSES:
                risk = "LOW (Permissive / Approved)"
            else:
                risk = "HIGH (Unknown / Unreviewed License)"

            findings.append({
                "component": name,
                "version": version,
                "purl": purl,
                "license": lic,
                "risk": risk
            })
    return findings


def main():
    parser = argparse.ArgumentParser(description="Auditor de Licenças Open Source em SBOM")
    parser.add_argument("--sbom", required=True, help="Caminho do SBOM JSON")
    parser.add_argument("--fail-on-copyleft", action="store_true", help="Falhar com erro se encontrar licenças GPL/AGPL")
    args = parser.parse_args()

    try:
        with open(args.sbom, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"{RED}[ERRO]{RESET} Falha ao ler SBOM: {e}", file=sys.stderr)
        sys.exit(1)

    findings = analyze_cyclonedx(data)

    print(f"\n{BOLD}{CYAN}========================================================================{RESET}")
    print(f"{BOLD}{CYAN} AUDITORIA DE LICENÇAS OPEN SOURCE & RISCO DE CONTAMINAÇÃO (COPYLEFT)   {RESET}")
    print(f"{BOLD}{CYAN}========================================================================{RESET}\n")

    has_critical = False

    for item in findings:
        risk_color = GREEN if "LOW" in item["risk"] else (YELLOW if "MEDIUM" in item["risk"] else RED)
        if "CRITICAL" in item["risk"]:
            has_critical = True

        print(f"Componente: {BOLD}{item['component']}@{item['version']}{RESET}")
        print(f" PURL:    {item['purl']}")
        print(f" Licença: {item['license']}")
        print(f" Risco:   {risk_color}{item['risk']}{RESET}\n")

    if has_critical and args.fail_on_copyleft:
        print(f"{RED}{BOLD}[FALHA DE COMPLIANCE] Detectada dependência com licença Copyleft Viral!{RESET}")
        print(f"{YELLOW}Aviso Jurídico:{RESET} O uso de bibliotecas GPL-3.0/AGPL em código comercial fechado pode forçar a abertura de código da aplicação.")
        sys.exit(2)
    else:
        print(f"{GREEN}[OK] Auditoria de licenças concluída.{RESET}")
        sys.exit(0)


if __name__ == "__main__":
    main()

