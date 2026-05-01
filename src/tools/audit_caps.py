#!/usr/bin/env python3
"""Generic CAmkES capability graph inventory for recovered VERSE OS apps."""

from __future__ import annotations

import argparse
import os
import re
from pathlib import Path


def strip_comments(text: str) -> str:
    text = re.sub(r"//.*", "", text)
    return re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)


def parse_camkes_file(path: Path):
    text = strip_comments(path.read_text(encoding="utf-8"))
    imports = re.findall(r'import\s+"([^"]+)"', text)
    instances = re.findall(r"component\s+(\w+)\s+(\w+)\s*;", text)
    connections = re.findall(
        r"connection\s+(\w+)\s+(\w+)\s*"
        r"\(\s*from\s+(\w+)\.(\w+)\s*,\s*to\s+(\w+)\.(\w+)\s*\)",
        text,
    )
    return imports, instances, connections


def parse_component_def(path: Path):
    text = strip_comments(path.read_text(encoding="utf-8"))
    name = re.search(r"component\s+(\w+)", text)
    provides = re.findall(r"provides\s+(\w+)\s+(\w+)\s*;", text)
    uses = re.findall(r"uses\s+(\w+)\s+(\w+)\s*;", text)
    dataports = re.findall(r"dataport\s+(\w+)\s+(\w+)\s*;", text)
    return {
        "name": name.group(1) if name else "unknown",
        "provides": provides,
        "uses": uses,
        "dataports": dataports,
        "control": "control" in text,
    }


def find_assembly(app_dir: Path) -> Path:
    preferred = app_dir / f"{app_dir.name}.camkes"
    if preferred.exists():
        return preferred
    candidates = sorted(p for p in app_dir.iterdir() if p.suffix == ".camkes")
    if not candidates:
        raise FileNotFoundError(f"no top-level .camkes assembly in {app_dir}")
    return candidates[0]


def audit_app(app_dir: Path) -> int:
    assembly = find_assembly(app_dir)
    imports, instances, connections = parse_camkes_file(assembly)
    comp_defs = {}
    for imp in imports:
        path = assembly.parent / imp
        if path.exists() and "components/" in imp:
            component = parse_component_def(path)
            comp_defs[component["name"]] = component

    print(f"APP {app_dir.name}")
    print(f"ASSEMBLY {assembly}")
    print(f"COMPONENTS {len(instances)}")
    for ctype, iname in instances:
        component = comp_defs.get(ctype, {})
        markers = []
        if component.get("control"):
            markers.append("control")
        if component.get("provides"):
            markers.append("provides=" + ",".join(name for _, name in component["provides"]))
        if component.get("uses"):
            markers.append("uses=" + ",".join(name for _, name in component["uses"]))
        if component.get("dataports"):
            markers.append("dataports=" + ",".join(name for _, name in component["dataports"]))
        print(f"  {iname}:{ctype}" + (f" [{' ; '.join(markers)}]" if markers else ""))

    print(f"CONNECTIONS {len(connections)}")
    for kind, name, src, src_if, dst, dst_if in connections:
        print(f"  {name}: {kind} {src}.{src_if} -> {dst}.{dst_if}")

    connected = {src for _, _, src, _, _, _ in connections} | {dst for _, _, _, _, dst, _ in connections}
    isolated = sorted(iname for _, iname in instances if iname not in connected)
    if isolated:
        print("WARN isolated components: " + ", ".join(isolated))
        return 1
    print("AUDIT_OK")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("app_dir", type=Path)
    args = parser.parse_args()
    return audit_app(args.app_dir)


if __name__ == "__main__":
    raise SystemExit(main())
