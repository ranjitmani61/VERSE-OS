#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

INSERTIONS = [
    "0x100: testworker_testworker_0_control_tcb",
    "0x101: testworker_fault_ep (R)",
    "0x102: procman_cnode (guard: 0, guard_size: 55)",
    "0x104: verse_spare_worker_tcb_1",
    "0x105: testworker_cnode (guard: 0, guard_size: 61)",
    "0x106: testworker_group_bin_pd",
    "0x107: testworker_frame__camkes_ipc_buffer_testworker_0_control (RW)",
    "0x108: testworker_fault_ep (RWP)",
    "0x109: verse_spare_worker_tcb_2",
    "0x10a: verse_spare_worker_tcb_3",
]

SPARE_TCB_DECLS = [
    "verse_spare_worker_tcb_1 = tcb",
    "verse_spare_worker_tcb_2 = tcb",
    "verse_spare_worker_tcb_3 = tcb",
]

REQUIRED_OBJECTS = [
    "procman_cnode",
    "testworker_testworker_0_control_tcb",
    "testworker_fault_ep",
    "testworker_cnode",
    "testworker_group_bin_pd",
    "testworker_frame__camkes_ipc_buffer_testworker_0_control",
]

def die(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    raise SystemExit(1)

def find_block(lines: list[str], header: str) -> tuple[int, int]:
    start = None
    for i, line in enumerate(lines):
        if re.match(rf"^\s*{re.escape(header)}\s*\{{\s*$", line):
            start = i
            break
    if start is None:
        die(f"block not found: {header}")

    for j in range(start + 1, len(lines)):
        if re.match(r"^\s*}\s*$", lines[j]):
            return start, j

    die(f"unterminated block: {header}")

def main() -> int:
    if len(sys.argv) != 3:
        print("usage: tools/inject_tcb_handoff.py <input.cdl> <output.cdl>", file=sys.stderr)
        return 2

    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])

    if not in_path.exists():
        die(f"input missing: {in_path}")

    text = in_path.read_text(errors="replace")

    # ProcMan handoff uses slots 0x100..0x108, so ProcMan CNode must be at
    # least 9 bits. Generated CAmkES default is normally 3 bits.
    text = text.replace("procman_cnode = cnode (3 bits)", "procman_cnode = cnode (9 bits)")

    # A 9-bit CNode needs a 55-bit guard on x86_64 instead of the generated
    # 61-bit guard used for 3-bit CNodes.
    text = text.replace(
        "cspace: procman_cnode (guard: 0, guard_size: 61)",
        "cspace: procman_cnode (guard: 0, guard_size: 55)"
    )

    for obj in REQUIRED_OBJECTS:
        if obj not in text:
            die(f"required generated object missing: {obj}")

    lines = text.splitlines()

    # Add spare TCB declarations into objects block if absent.
    obj_start, obj_end = find_block(lines, "objects")
    for decl in reversed(SPARE_TCB_DECLS):
        if decl not in text and decl not in lines:
            lines.insert(obj_end, decl)

    # Recompute after object insertion.
    proc_start, proc_end = find_block(lines, "procman_cnode")
    proc_body = "\n".join(lines[proc_start:proc_end + 1])

    for forbidden in ["0x100:", "0x101:", "0x102:", "0x104:", "0x105:", "0x106:", "0x107:", "0x108:", "0x109:", "0x10a:"]:
        if re.search(rf"(?m)^\s*{re.escape(forbidden)}", proc_body):
            die(f"procman_cnode already has slot {forbidden}")

    insertion_lines = [f"    {line}" for line in INSERTIONS]
    lines[proc_end:proc_end] = insertion_lines

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines) + "\n")

    print(f"WROTE {out_path}")
    print("Injected ProcMan TCB handoff slots 0x100,0x101,0x102,0x104,0x105,0x106,0x107,0x108,0x109,0x10a")
    print("Injected spare TCB pool for bounded repeated recovery")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
