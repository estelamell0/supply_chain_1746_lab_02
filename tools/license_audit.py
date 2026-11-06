#!/usr/bin/env python3
"""
Auditor de Licenças de Código Aberto (Open Source License Governance)
Suporta CycloneDX (JSON), SPDX (JSON) e Lockfiles npm (package-lock.json)
para detectar riscos de contaminação por Copyleft Viral (GPL/AGPL).
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


def classify_license(lic: str) -> str:
    lic_clean = lic.lower().strip()
    if lic_clean in STRONG_COPYLEFT:
        return "CRITICAL (Strong Copyleft / Virality Risk)"
    elif lic_clean in WEAK_COPYLEFT:
        return "MEDIUM (Weak Copyleft / Boundary Restriction)"
    elif lic_clean in PERMISSIVE_LICENSES:
        return "LOW (Permissive / Approved)"
    elif lic_clean in {"proprietary", "private", "unlicensed"}:
        return "LOW (Internal / Proprietary)"
    else:
        return "HIGH (Unknown / Unreviewed License)"


def analyze_cyclonedx(data: Dict[str, Any]) -> List[Dict[str, str]]:
    findings = []
    for c in data.get("components", []):
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
            findings.append({
                "component": name,
                "version": version,
                "purl": purl,
                "license": lic,
                "risk": classify_license(lic)
            })
    return findings


def analyze_npm_lockfile(data: Dict[str, Any]) -> List[Dict[str, str]]:
    findings = []
    packages = data.get("packages", {})
    for pkg_path, pkg_info in packages.items():
        if not pkg_path:  # Ignorar pacote raiz ""
            continue
        name = pkg_info.get("name") or pkg_path.replace("node_modules/", "")
        version = pkg_info.get("version", "unknown")
        lic = pkg_info.get("license", "UNKNOWN")
        purl_name = name.replace("@", "%40") if name.startswith("@") else name
        purl = f"pkg:npm/{purl_name}@{version}"

        findings.append({
            "component": name,
            "version": version,
            "purl": purl,
            "license": lic,
            "risk": classify_license(lic)
        })
    return findings


def analyze_spdx(data: Dict[str, Any]) -> List[Dict[str, str]]:
    findings = []
    for p in data.get("packages", []):
        name = p.get("name", "unknown")
        version = p.get("versionInfo", "unknown")
        lic = p.get("licenseConcluded") or p.get("licenseDeclared") or "NOASSERTION"
        purl = f"pkg:generic/{name}@{version}"
        for ref in p.get("externalRefs", []):
            if ref.get("referenceType", "").endswith("purl"):
                purl = ref.get("referenceLocator", purl)
                break
        findings.append({
            "component": name,
            "version": version,
            "purl": purl,
            "license": lic,
            "risk": classify_license(lic)
        })
    return findings


def main():
    parser = argparse.ArgumentParser(description="Auditor de Licenças Open Source em SBOM ou Lockfile")
    parser.add_argument("--sbom", required=True, help="Caminho do SBOM JSON ou package-lock.json")
    parser.add_argument("--fail-on-copyleft", action="store_true", help="Falhar com erro se encontrar licenças GPL/AGPL")
    args = parser.parse_args()

    try:
        with open(args.sbom, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"{RED}[ERRO]{RESET} Falha ao ler arquivo: {e}", file=sys.stderr)
        sys.exit(1)

    if "bomFormat" in data and str(data["bomFormat"]).lower() == "cyclonedx":
        findings = analyze_cyclonedx(data)
    elif "spdxVersion" in data:
        findings = analyze_spdx(data)
    elif "lockfileVersion" in data or "packages" in data:
        findings = analyze_npm_lockfile(data)
    else:
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
