# TCB Normal Recovery No-Fault Evidence

Date: 2026-05-02

## Verdict

Normal recovered TestWorker mode now completes one enforced TCB recovery without the previous runtime fault delivery failure.

## Root Cause Fixed

- Non-MCS `seL4_TCB_Configure` takes `fault_ep` as a CPtr in the configured thread's CSpace.
- ProcMan was passing `0x108`, which is a ProcMan CSpace endpoint cap, not a valid TestWorker CSpace fault endpoint CPtr.
- TestWorker's generated CSpace has `testworker_fault_ep` at CPtr `0x2`.
- ProcMan was also configuring the fresh TCB with CSpace guard size `52`, while generated `testworker_cnode` uses guard size `61`.

## Runtime Evidence

Boot log:

`out/testworker_normal_recovery_no_fault/boot.log`

Required grep:

```text
69:ProcMan: restart attempt 1/3
73:ProcMan: spare TCB slot for attempt 1 is 0x104
74:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
81:VERSE_RECOVERY_PASS_1
82:WDOG: heartbeat resumed, re-armed and monitoring
```

Negative grep results:

```text
grep -nE "Caught cap fault|vm fault|fault|Error" out/testworker_normal_recovery_no_fault/boot.log
# no output

grep -nE "ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/testworker_normal_recovery_no_fault/boot.log
# no output
```

## Boundary

- Fault endpoint message handling by ProcMan remains not proven.
- Cap delete/revoke cleanup remains not proven.
- QEMU still exits by timeout: `SIMULATE_EXIT:124`.
- Build still emits: `kernel.elf has a LOAD segment with RWX permissions`.
