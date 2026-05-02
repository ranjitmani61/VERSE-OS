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

## Resolved Generated Object Names

Observed in generated `verse_unified.cdl`:

- ProcMan CNode: `procman_cnode`
- TestWorker CNode: `testworker_cnode`
- TestWorker control TCB: `testworker_testworker_0_control_tcb`
- TestWorker fault-handler TCB: `testworker_testworker_0_fault_handler_tcb`
- TestWorker fault endpoint: `testworker_fault_ep`
- TestWorker VSpace/PML4: `testworker_group_bin_pd`
- TestWorker control IPC buffer frame: `testworker_frame__camkes_ipc_buffer_testworker_0_control`
- TestWorker fault-handler IPC buffer frame: `testworker_frame__camkes_ipc_buffer_testworker_0_fault_handler`

## Strict Audit Result

out/capdl_audit/verse_unified.cdl:

PASS ProcMan marker
PASS TestWorker marker
PASS TCB marker
PASS CNode marker
PASS Endpoint/fault marker
PASS found 1 ProcMan-like CNode block(s)

FAIL 0x100: TestWorker TCB cap for ProcMan suspend authority -> testworker_testworker_0_control_tcb
FAIL 0x101: ProcMan receive cap for TestWorker fault endpoint -> testworker_fault_ep
FAIL 0x102: ProcMan CNode destination root for Retype -> procman_cnode
FAIL 0x103: Untyped memory for fresh TCB
FAIL 0x105: TestWorker CSpace root -> testworker_cnode
FAIL 0x106: TestWorker VSpace root -> testworker_group_bin_pd
FAIL 0x107: TestWorker IPC buffer frame -> testworker_frame__camkes_ipc_buffer_testworker_0_control
FAIL 0x108: TestWorker fault endpoint cap for TCB_Configure -> testworker_fault_ep

PASS 0x104: Empty destination slot for fresh TCB created by seL4_Untyped_Retype

out/capdl_audit/capdl_spec.c also failed the strict ProcMan handoff audit.

## Correct Slot Contract

Required present in procman_cnode:

- 0x100: testworker_testworker_0_control_tcb
- 0x101: testworker_fault_ep
- 0x102: procman_cnode
- 0x103: untyped memory for fresh TCB
- 0x105: testworker_cnode
- 0x106: testworker_group_bin_pd
- 0x107: testworker_frame__camkes_ipc_buffer_testworker_0_control
- 0x108: testworker_fault_ep

Required absent/empty in procman_cnode:

- 0x104: reserved destination slot for runtime seL4_Untyped_Retype

## Claim Boundary

Allowed:

- The generated CAmkES capDL contains ProcMan/TestWorker/TCB/CNode/fault markers.
- The generated ProcMan CNode does not currently contain the required TCB handoff slots.
- Slot 0x104 is currently empty, as required for fresh TCB retype destination.
- Native TCB restart remains blocked on capDL merge/injection.

Not allowed:

- ProcMan has runtime TCB authority.
- The capDL handoff is integrated.
- Native seL4 TCB restart is runtime-proven.

## Next Engineering Step

Build a capDL merge/injection step that inserts the handoff contract into generated verse_unified.cdl, then regenerate capdl_spec.c from the merged capDL and rerun this audit.
