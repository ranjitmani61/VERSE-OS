# TCB Enforced Compile Probe

Date: 2026-05-02

## Verdict

The guarded `VERSE_TCB_ENFORCED` ProcMan branch compiles when the macro is force-defined in source for a probe build.

This is compile evidence only. It is not runtime evidence of native seL4 TCB restart.

## Evidence

Forced probe build exported ProcMan artifacts into `out/verse_unified`.

Observed strings in `procman.c.obj`, `procman_group_bin`, `procman.instance.bin`, and `procman.instance-copy.bin`:

- `ProcMan: seL4_TCB_Suspend(worker_tcb) OK`
- `ProcMan: TCB rebuild metadata missing; configure IPC addr, entry IP, and stack top`
- `ProcMan: enforced TCB restart attempt %d/%d`
- `ProcMan: enforced rebuild failed after suspend; quarantine required`
- `ProcMan: enforced path unavailable, falling back to cooperative restart`

## Boundary

Not proven:

- ProcMan receives valid worker TCB cap.
- ProcMan receives valid untyped, CNode, VSpace, IPC buffer, fault endpoint caps.
- Worker entry IP, stack top, and IPC buffer address are configured.
- `seL4_TCB_Suspend`, `seL4_Untyped_Retype`, `seL4_TCB_Configure`, `seL4_TCB_WriteRegisters`, or `seL4_TCB_Resume` succeed at runtime.
- Fresh TestWorker TCB is created or resumed at runtime.

Current expected runtime behavior with fake/default metadata is failure or fallback/quarantine, not successful native TCB restart.
