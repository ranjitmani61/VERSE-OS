# TCB Bounded Quarantine Lifecycle Evidence

Date: 2026-05-02

## Verdict

VERSE OS currently demonstrates bounded active-TCB quarantine, not capability
revoke/delete cleanup.

The recovery path suspends the old active worker TCB, moves the active worker
role to a pre-created spare TCB, and stops recovery after the bounded spare pool
is exhausted. It does not execute `seL4_CNode_Delete`,
`seL4_CNode_Revoke`, or an equivalent cap lifecycle operation.

A runtime trial that deleted old ProcMan TCB cap slots after handoff was not
safe enough to commit: repeat-deadlock mode still reached the three recovery
pass markers, but it also emitted a TestWorker fault-handler data fault during
the third recovery. The committed design therefore remains bounded quarantine
with no runtime reclamation.

## Implemented Lifecycle

The current `ProcMan` enforced recovery path does the following:

1. Suspends the current active worker TCB with `seL4_TCB_Suspend`.
2. Logs the suspended TCB as quarantined.
3. Selects a spare TCB for the current recovery attempt.
4. Configures the spare TCB with TestWorker CSpace, VSpace, IPC buffer, entry
   point, stack pointer, and priority.
5. Resumes the spare TCB.
6. Updates `active_worker_tcb` to the spare TCB.
7. Stops further restart attempts after the three-spare pool is exhausted and
   logs `ProcMan: QUARANTINE`.

The bounded spare TCB pool is:

```text
attempt 1 -> 0x104
attempt 2 -> 0x109
attempt 3 -> 0x10a
```

## Cap Lifecycle Status

No source path currently proves capability deletion, revocation, or object
reclamation for old worker TCBs.

Source audit command:

```sh
rg -n "seL4_CNode_Delete|seL4_CNode_Revoke|CNode_Delete|CNode_Revoke" src/apps/verse_unified tools -S
```

Observed result: no matches.

Therefore:

- Suspended old active TCBs remain represented by existing CSpace caps.
- `ProcMan: active worker TCB ... suspended and quarantined` means suspended and
  removed from the active-worker role.
- `ProcMan: active worker TCB ... suspended and quarantined` does not mean
  `seL4_CNode_Delete`.
- `ProcMan: active worker TCB ... suspended and quarantined` does not mean
  `seL4_CNode_Revoke`.
- Object destruction or cap reclamation is not proven.

## Generated CapDL Inspection

Generated capDL inspected:

```text
out/tcb_cap_lifecycle_normal/verse_unified.cdl
out/tcb_cap_lifecycle_normal/capdl_spec.c
```

`procman_cnode` contains the TCB handoff caps:

```text
0x100: testworker_testworker_0_control_tcb
0x104: verse_spare_worker_tcb_1
0x109: verse_spare_worker_tcb_2
0x10a: verse_spare_worker_tcb_3
```

The same `procman_cnode` also contains the worker runtime caps that must not be
deleted by TCB cleanup:

```text
0x105: testworker_cnode (guard: 0, guard_size: 61)
0x106: testworker_group_bin_pd
0x107: testworker_frame__camkes_ipc_buffer_testworker_0_control (RW)
```

`testworker_cnode` also has a cap to the original control TCB:

```text
0x1: testworker_testworker_0_control_tcb
```

The generated `capdl_spec.c` shows the spare TCB objects begin as empty TCBs
with no CSpace/VSpace/IPC buffer slots:

```text
name = "verse_spare_worker_tcb_1"
ipcbuffer_addr = 0x0
pc = 0x0
sp = 0x0
slots.num = 0
```

## Delete Trial

A local trial added `seL4_CNode_Delete(VERSE_PROCMAN_CNODE_CPTR, old_tcb,
seL4_WordBits)` after each successful handoff and logged delete success.
Normal mode passed, but repeat-deadlock mode produced a runtime fault.

Trial logs:

```text
out/tcb_cap_delete_normal/boot.log
out/tcb_cap_delete_repeat/boot.log
```

Normal trial marker:

```text
79:ProcMan: quarantined TCB cap 0x100 delete OK
83:VERSE_RECOVERY_PASS_1
84:WDOG: heartbeat resumed, re-armed and monitoring
```

Repeat trial failure marker:

```text
114:ProcMan: fresh TestWorker priority FAULT HANDLER: data fault from testworker.testworker_0_control (ID 0x1) on address 0, pc = 0, fsr = 0x4
```

Decision: runtime delete/revoke cleanup is not committed. Safe runtime cap
cleanup is not proven.

## Normal Runtime Evidence

Evidence log:

```text
out/tcb_cap_lifecycle_normal/boot.log
```

Observed grep:

```text
70:ProcMan: restart attempt 1/3
73:ProcMan: active worker TCB 0x100 suspended and quarantined
74:ProcMan: spare TCB slot for attempt 1 is 0x104
75:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
77:ProcMan: active worker TCB moved to spare 0x104
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
179:SIMULATE_EXIT:124
```

Negative grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/tcb_cap_lifecycle_normal/boot.log
```

Observed result: no matches.

## Repeat Runtime Evidence

Evidence log:

```text
out/tcb_cap_lifecycle_repeat/boot.log
```

Observed grep:

```text
70:ProcMan: restart attempt 1/3
73:ProcMan: active worker TCB 0x100 suspended and quarantined
74:ProcMan: spare TCB slot for attempt 1 is 0x104
75:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
77:ProcMan: active worker TCB moved to spare 0x104
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
88:ProcMan: restart attempt 2/3
91:ProcMan: active worker TCB 0x104 suspended and quarantined
92:ProcMan: spare TCB slot for attempt 2 is 0x109
93:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
95:ProcMan: active worker TCB moved to spare 0x109
100:VERSE_RECOVERY_PASS_2
101:WDOG: heartbeat resumed, re-armed and monitoring
106:ProcMan: restart attempt 3/3
109:ProcMan: active worker TCB 0x109 suspended and quarantined
110:ProcMan: spare TCB slot for attempt 3 is 0x10a
111:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
113:ProcMan: active worker TCB moved to spare 0x10a
118:VERSE_RECOVERY_PASS_3
119:WDOG: heartbeat resumed, re-armed and monitoring
124:ProcMan: QUARANTINE
217:SIMULATE_EXIT:124
```

Fault/error grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" out/tcb_cap_lifecycle_repeat/boot.log
```

Observed result: no matches.

Build log:

```text
out/tcb_cap_lifecycle_normal/build.log
out/tcb_cap_lifecycle_repeat/build.log
```

Observed build warning, not addressed by this document:

```text
/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

Both final QEMU runs exited by timeout with `SIMULATE_EXIT:124`; clean shutdown
is not proven.

## Not Proven

- Cap deletion is not proven.
- Cap revocation is not proven.
- TCB object destruction is not proven.
- Memory or kernel object reclamation is not proven.
- Fault endpoint handling is not proven by this document.
- Clean QEMU shutdown is not proven by this document.
- RWX kernel LOAD segment status is not proven by this document.
