# TCB Bounded Quarantine Lifecycle Evidence

Date: 2026-05-02

## Verdict

VERSE OS currently demonstrates bounded active-TCB quarantine, not capability
revoke/delete cleanup.

The recovery path suspends the old active worker TCB, moves the active worker
role to a pre-created spare TCB, and stops recovery after the bounded spare pool
is exhausted. It does not execute `seL4_CNode_Delete`,
`seL4_CNode_Revoke`, or an equivalent cap lifecycle operation.

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

## Runtime Evidence

Evidence log:

```text
out/tcb_bounded_quarantine_lifecycle/boot.log
```

Observed grep:

```text
72:ProcMan: suspending active worker TCB 0x100
73:ProcMan: active worker TCB 0x100 suspended and quarantined
74:ProcMan: spare TCB slot for attempt 1 is 0x104
77:ProcMan: active worker TCB moved to spare 0x104
82:VERSE_RECOVERY_PASS_1
90:ProcMan: suspending active worker TCB 0x104
91:ProcMan: active worker TCB 0x104 suspended and quarantined
92:ProcMan: spare TCB slot for attempt 2 is 0x109
95:ProcMan: active worker TCB moved to spare 0x109
100:VERSE_RECOVERY_PASS_2
108:ProcMan: suspending active worker TCB 0x109
109:ProcMan: active worker TCB 0x109 suspended and quarantined
110:ProcMan: spare TCB slot for attempt 3 is 0x10a
113:ProcMan: active worker TCB moved to spare 0x10a
118:VERSE_RECOVERY_PASS_3
124:ProcMan: QUARANTINE
216:SIMULATE_EXIT:124
```

Fault/error grep:

```sh
grep -nE "Caught cap fault|vm fault|fault|Error" out/tcb_bounded_quarantine_lifecycle/boot.log
```

Observed result: no matches.

Build log:

```text
out/tcb_bounded_quarantine_lifecycle/build.log
```

Observed build warning, not addressed by this document:

```text
/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

## Not Proven

- Cap deletion is not proven.
- Cap revocation is not proven.
- TCB object destruction is not proven.
- Memory or kernel object reclamation is not proven.
- Fault endpoint handling is not proven by this document.
- Clean QEMU shutdown is not proven by this document.
- RWX kernel LOAD segment status is not proven by this document.
