#!/usr/bin/env python3
"""Adversarial mutation harness for VERSE OS static artifacts.

The harness does not mutate the working tree. It copies the CAmkES assembly to a
temporary directory, applies small miswiring mutations, and verifies that the
capability audit catches them.
"""

from __future__ import annotations

import shutil
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ASSEMBLY = ROOT / "verse_unified" / "verse_unified.camkes"
AUDITOR = ROOT / "tools" / "capability_audit.py"


MUTATIONS = {
    "bypass_sentinel": (
        "connection seL4RPCCall rpc(from client.h, to sentinel.client_h);",
        "connection seL4RPCCall rpc(from client.h, to hello.h);",
    ),
    "drop_restart": (
        "connection seL4SharedData rf(from procman.restart_flag, to testworker.restart_flag);",
        "/* removed restart connection */",
    ),
    "swap_codex_reader": (
        "connection seL4SharedData fstore(from codexfs.store, to readclient.store);",
        "connection seL4SharedData fstore(from writeclient.logbuf, to readclient.store);",
    ),
}


def run_audit(path: Path) -> int:
    return subprocess.run([str(AUDITOR), str(path)], cwd=ROOT, check=False).returncode


def main() -> int:
    if not ASSEMBLY.exists():
        print(f"missing assembly: {ASSEMBLY}")
        return 2

    baseline = run_audit(ASSEMBLY)
    if baseline != 0:
        print("baseline audit failed; refusing chaos mutations")
        return baseline

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp)
        failures = 0
        for name, (old, new) in MUTATIONS.items():
            mutated = tmp_path / f"{name}.camkes"
            shutil.copyfile(ASSEMBLY, mutated)
            text = mutated.read_text(encoding="utf-8")
            if old not in text:
                print(f"{name}: mutation target not found")
                failures += 1
                continue
            mutated.write_text(text.replace(old, new), encoding="utf-8")
            rc = run_audit(mutated)
            if rc == 0:
                print(f"{name}: audit failed to catch mutation")
                failures += 1
            else:
                print(f"{name}: caught")

    if failures:
        return 1
    print("CHAOS_MONKEY_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

