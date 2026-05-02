#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

REQUIRED_PRESENT_PROC_SLOTS = {
    "0x100": ("TestWorker TCB cap for ProcMan suspend authority", "testworker_testworker_0_control_tcb"),
    "0x101": ("ProcMan receive cap for TestWorker fault endpoint", "testworker_fault_ep"),
    "0x102": ("ProcMan CNode destination root for Retype", "procman_cnode"),
    "0x103": ("Untyped memory for fresh TCB", None),
    "0x105": ("TestWorker CSpace root", "testworker_cnode"),
    "0x106": ("TestWorker VSpace root", "testworker_group_bin_pd"),
    "0x107": ("TestWorker IPC buffer frame", "testworker_frame__camkes_ipc_buffer_testworker_0_control"),
    "0x108": ("TestWorker fault endpoint cap for TCB_Configure", "testworker_fault_ep"),
}

REQUIRED_EMPTY_PROC_SLOTS = {
    "0x104": "Empty destination slot for fresh TCB created by seL4_Untyped_Retype",
}

def find_cnode_blocks(text: str) -> list[tuple[str, str]]:
    blocks: list[tuple[str, str]] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        if re.search(r"=\s*cnode\b", line, re.I) or re.search(r"\bcnode\b", line, re.I):
            name = line.strip()
            body = [line]
            j = i + 1
            brace_seen = "{" in line
            while j < len(lines):
                body.append(lines[j])
                if "{" in lines[j]:
                    brace_seen = True
                if brace_seen and "}" in lines[j]:
                    break
                if j - i > 500:
                    break
                j += 1
            blocks.append((name, "\n".join(body)))
            i = j
        i += 1
    return blocks

def relevant_procman_blocks(text: str) -> list[tuple[str, str]]:
    blocks = find_cnode_blocks(text)
    return [(name, body) for name, body in blocks if re.search(r"procman", name + "\n" + body, re.I)]

def main() -> int:
    if len(sys.argv) != 2:
        print("usage: tools/check_tcb_handoff.py <generated.cdl|capdl_spec.c>")
        return 2

    path = Path(sys.argv[1])
    if not path.exists():
        print(f"FAIL generated file missing: {path}")
        return 1

    text = path.read_text(errors="replace")
    print(f"Audit target: {path}")
    print(f"Bytes: {len(text)}")
    print()

    basic_checks = {
        "ProcMan marker": re.search(r"procman", text, re.I),
        "TestWorker marker": re.search(r"testworker", text, re.I),
        "TCB marker": re.search(r"\btcb\b|_tcb|TCB", text),
        "CNode marker": re.search(r"\bcnode\b|CNode|_cnode", text),
        "Endpoint/fault marker": re.search(r"\bep\b|endpoint|fault", text, re.I),
    }

    failures = 0
    print("== Basic generated artifact markers ==")
    for label, ok in basic_checks.items():
        print(f"{'PASS' if ok else 'FAIL'} {label}")
        if not ok:
            failures += 1

    print()
    print("== ProcMan CNode block search ==")
    proc_blocks = relevant_procman_blocks(text)
    if proc_blocks:
        print(f"PASS found {len(proc_blocks)} ProcMan-like CNode block(s)")
    else:
        print("FAIL no ProcMan-like CNode block found")
        failures += 1

    combined = "\n\n".join(body for _, body in proc_blocks)
    print()
    print("== Required present handoff slots inside ProcMan-like CNode blocks ==")
    for slot, (meaning, target) in REQUIRED_PRESENT_PROC_SLOTS.items():
        slot_re = re.compile(rf"(?m)^\s*{re.escape(slot)}\s*:\s*([^\n]+)")
        m = slot_re.search(combined)
        ok = bool(m)
        if ok and target is not None:
            ok = target in m.group(1)
        target_note = f" -> {target}" if target else ""
        actual = f" [{m.group(1).strip()}]" if m else ""
        print(f"{'PASS' if ok else 'FAIL'} {slot}: {meaning}{target_note}{actual}")
        if not ok:
            failures += 1

    print()
    print("== Required empty handoff slots inside ProcMan-like CNode blocks ==")
    for slot, meaning in REQUIRED_EMPTY_PROC_SLOTS.items():
        slot_re = re.compile(rf"(?m)^\s*{re.escape(slot)}\s*:")
        ok = not bool(slot_re.search(combined))
        print(f"{'PASS' if ok else 'FAIL'} {slot}: {meaning}")
        if not ok:
            failures += 1

    print()
    print("== Conclusion ==")
    if failures:
        print("FAIL: full ProcMan TCB handoff is not present in the generated artifact.")
        print("Do not claim runtime TCB authority. Next step is capDL merge/injection.")
    else:
        print("PASS: all searched handoff slots appear inside ProcMan-like CNode blocks.")
        print("Still only syntactic capDL evidence, not runtime proof.")

    return 1 if failures else 0

if __name__ == "__main__":
    raise SystemExit(main())
