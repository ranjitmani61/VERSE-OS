# TCB Handoff Generated capDL Audit

Date: 2026-05-02

## Verdict

Generated CAmkES capDL does not currently contain the ProcMan -> TestWorker TCB handoff contract.

This confirms the current blocker is capability injection/merge, not ProcMan C compile support.

## Inputs

- Overlay contract: `src/capdl/verse_tcb_handoff.cdl`
- Generated capDL: `out/capdl_audit/verse_unified.cdl`
- Generated C capDL loader source: `out/capdl_audit/capdl_spec.c`
- Audit tool: `tools/check_tcb_handoff.py`

## Strict Audit Result

`out/capdl_audit/verse_unified.cdl`:

```text
PASS ProcMan marker
PASS TestWorker marker
PASS TCB marker
PASS CNode marker
PASS Endpoint/fault marker
PASS found 1 ProcMan-like CNode block(s)
FAIL 0x100: TestWorker TCB cap for ProcMan suspend authority
FAIL 0x101: ProcMan receive cap for TestWorker fault endpoint
FAIL 0x102: ProcMan CNode destination root for Retype
FAIL 0x103: Untyped memory for fresh TCB
FAIL 0x104: Empty destination slot for fresh TCB
FAIL 0x105: TestWorker CSpace root
FAIL 0x106: TestWorker VSpace root
FAIL 0x107: TestWorker IPC buffer frame
FAIL 0x108: TestWorker fault endpoint cap for TCB_Configure
```

`out/capdl_audit/capdl_spec.c` also failed the strict ProcMan handoff slot audit.

## Claim Boundary

Allowed:

- The generated CAmkES capDL contains ProcMan/TestWorker/TCB/CNode/fault markers.
- The generated ProcMan CNode does not currently contain slots `0x100..0x108` for the TCB handoff.
- Native TCB restart remains blocked on capDL merge/injection.

Not allowed:

- ProcMan has runtime TCB authority.
- The capDL handoff is integrated.
- Native seL4 TCB restart is runtime-proven.

## Next Engineering Step

Build a capDL merge/injection step that inserts the handoff contract into the generated `verse_unified.cdl`, then regenerate `capdl_spec.c` from the merged capDL and rerun this audit.
