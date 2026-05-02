# TCB Handoff Injection Evidence

Date: 2026-05-02

## Verdict

Offline capDL injection now works on a copied generated CDL.

The original generated CAmkES capDL fails the strict ProcMan TCB handoff audit. The injected copy passes the strict audit.

This is syntactic capDL evidence only. It is not yet a booted image and not runtime TCB restart proof.

## Tools

- `tools/check_tcb_handoff.py`
- `tools/inject_tcb_handoff.py`

## Inputs

- Original generated capDL: `out/capdl_audit/verse_unified.cdl`
- Injected capDL copy: `out/capdl_merged/verse_unified_tcb_handoff.cdl`

## Result

Original generated CDL:

- ProcMan/TestWorker/TCB/CNode/fault markers present.
- ProcMan CNode missing required handoff slots.
- Slot `0x104` empty.

Injected CDL:

- `0x100`: `testworker_testworker_0_control_tcb`
- `0x101`: `testworker_fault_ep (R)`
- `0x102`: `procman_cnode (guard: 0, guard_size: 61)`
- `0x103`: `verse_procman_tcb_untyped`
- `0x104`: empty
- `0x105`: `testworker_cnode (guard: 0, guard_size: 61)`
- `0x106`: `testworker_group_bin_pd`
- `0x107`: `testworker_frame__camkes_ipc_buffer_testworker_0_control (RW)`
- `0x108`: `testworker_fault_ep (RWP)`

Strict audit result for injected CDL: PASS.

## Boundary

Not proven:

- Injected CDL parses through capDL tooling.
- `verse_procman_tcb_untyped` is a valid usable untyped object for runtime TCB creation.
- Regenerated `capdl_spec.c` builds.
- Booted image gives ProcMan valid runtime caps.
- `seL4_TCB_Suspend`, `seL4_Untyped_Retype`, `seL4_TCB_Configure`, or `seL4_TCB_Resume` succeed.

## Next Step

Run the injected CDL through the real capDL parser / C generator path and rebuild `capdl_spec.c` from it.
