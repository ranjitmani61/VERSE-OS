#!/usr/bin/env python3
"""Static capability graph audit for the VERSE OS CAmkES assembly.

This is intentionally conservative. It parses `connection ... (from A.iface,
to B.iface)` edges and checks them against the current expected policy.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


EDGE_RE = re.compile(
    r"connection\s+(?P<kind>\w+)\s+(?P<name>\w+)\s*"
    r"\(\s*from\s+(?P<src>\w+)\.(?P<src_if>\w+)\s*,\s*"
    r"to\s+(?P<dst>\w+)\.(?P<dst_if>\w+)\s*\)"
)

EXPECTED = {
    ("sentinel", "logring", "seL4SharedData"),
    ("hello", "logring", "seL4SharedData"),
    ("client", "logring", "seL4SharedData"),
    ("cortexmm", "logring", "seL4SharedData"),
    ("memclient", "logring", "seL4SharedData"),
    ("worker_a", "logring", "seL4SharedData"),
    ("worker_b", "logring", "seL4SharedData"),
    ("dharmanet", "logring", "seL4SharedData"),
    ("codexfs", "logring", "seL4SharedData"),
    ("writeclient", "logring", "seL4SharedData"),
    ("readclient", "logring", "seL4SharedData"),
    ("testworker", "logring", "seL4SharedData"),
    ("watchdog", "logring", "seL4SharedData"),
    ("procman", "logring", "seL4SharedData"),
    ("client", "sentinel", "seL4RPCCall"),
    ("sentinel", "hello", "seL4RPCCall"),
    ("cortexmm", "memclient", "seL4SharedData"),
    ("worker_a", "dharmanet", "seL4SharedData"),
    ("worker_b", "dharmanet", "seL4SharedData"),
    ("writeclient", "codexfs", "seL4RPCCall"),
    ("readclient", "codexfs", "seL4RPCCall"),
    ("codexfs", "readclient", "seL4SharedData"),
    ("testworker", "watchdog", "seL4SharedData"),
    ("watchdog", "procman", "seL4SharedData"),
    ("procman", "testworker", "seL4SharedData"),
    ("dharmanet", "procman", "seL4SharedData"),
}


def parse_edges(path: Path) -> list[tuple[str, str, str, str, str, str]]:
    text = path.read_text(encoding="utf-8")
    edges = []
    for match in EDGE_RE.finditer(text):
        edges.append(
            (
                match.group("src"),
                match.group("dst"),
                match.group("kind"),
                match.group("name"),
                match.group("src_if"),
                match.group("dst_if"),
            )
        )
    return edges


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "assembly",
        nargs="?",
        default="verse_unified/verse_unified.camkes",
        help="CAmkES assembly to audit",
    )
    args = parser.parse_args()
    path = Path(args.assembly)
    if not path.exists():
        print(f"missing assembly: {path}", file=sys.stderr)
        return 2

    edges = parse_edges(path)
    observed = {(src, dst, kind) for src, dst, kind, _, _, _ in edges}
    extra = sorted(observed - EXPECTED)
    missing = sorted(EXPECTED - observed)

    print(f"audited {path}: {len(edges)} connection declarations")
    for src, dst, kind, name, src_if, dst_if in edges:
        print(f"{name}: {kind} {src}.{src_if} -> {dst}.{dst_if}")

    if extra:
        print("\nUnexpected edges:")
        for edge in extra:
            print(f"  {edge[2]} {edge[0]} -> {edge[1]}")
    if missing:
        print("\nMissing expected edges:")
        for edge in missing:
            print(f"  {edge[2]} {edge[0]} -> {edge[1]}")

    if extra or missing:
        return 1
    print("\nCAPABILITY_AUDIT_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

