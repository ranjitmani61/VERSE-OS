# Fault Endpoint Limitation Evidence

Date: 2026-05-02

## Verdict

The fresh TestWorker TCB fault endpoint path is configured cleanly for the
current recovery proof, but ProcMan fault receive/decode handling is not proven.

`ProcMan` still has `fault_endpoint_handler_stub()`. It does not call
`seL4_Recv`, `seL4_NBRecv`, or decode a fault message.

## Source Inspection

Current source search:

```sh
rg -n "seL4_Recv|seL4_NBRecv|seL4_Poll|fault_endpoint_handler_stub" src/apps/verse_unified tools -S
```

Observed state:

```text
src/apps/verse_unified/components/ProcMan/src/procman.c:119:static void fault_endpoint_handler_stub(void)
src/apps/verse_unified/components/ProcMan/src/procman.c:123:    // TestWorker's fault endpoint cap. The real handler must seL4_Recv on
src/apps/verse_unified/components/ProcMan/src/procman.c:261:    fault_endpoint_handler_stub();
```

The `seL4_Recv` match is a comment inside the stub, not an executed call. No
ProcMan source path receives or decodes a TestWorker fault message.

## Generated CapDL Inspection

Generated capDL inspected:

```text
out/tcb_cap_lifecycle_normal/verse_unified.cdl
out/tcb_cap_lifecycle_normal/capdl_spec.c
```

ProcMan has caps to the TestWorker fault endpoint:

```text
0x101: testworker_fault_ep (R)
0x108: testworker_fault_ep (RWP)
```

TestWorker also has caps to the same endpoint:

```text
0x2: testworker_fault_ep (RWP, badge: 1)
0x4: testworker_fault_ep (RWP)
```

The generated TestWorker control TCB uses fault endpoint CPtr `0x2`:

```text
testworker_testworker_0_control_tcb = tcb (... fault_ep: 0x00000002)
```

The generated `capdl_spec.c` also shows:

```text
.fault_ep = 2
```

The recovered fresh TCB is configured with `VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR`
set to `0x2`, which is valid in TestWorker's configured CSpace. This is the
fixed path that removed the earlier `Caught cap fault in send phase at address
0x108` failure.

## Handler Decision

Replacing the current stub with a blocking `seL4_Recv` in ProcMan's watchdog
restart path is not safe for the current design:

- The normal proven recovery path is heartbeat-loss driven, not fault-message
  driven.
- In normal recovery, no TestWorker fault message is expected.
- A blocking receive in `enforced_restart_worker()` would block ProcMan before
  it suspends/rebuilds the worker.
- The same endpoint is also wired to the generated TestWorker fault handler
  thread, so ProcMan is not proven to be the sole receiver.

Real fault-triggered recovery needs a separate design step: explicit endpoint
ownership or a nonblocking/asynchronous ProcMan receiver, plus a deliberate
fault injection test proving ProcMan receives and decodes the fault.

## Runtime Evidence

Normal recovery log:

```text
out/tcb_cap_lifecycle_normal/boot.log
```

Observed markers:

```text
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
```

Normal negative grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/tcb_cap_lifecycle_normal/boot.log
```

Observed result: no matches.

Repeat-deadlock log:

```text
out/tcb_cap_lifecycle_repeat/boot.log
```

Observed markers:

```text
82:VERSE_RECOVERY_PASS_1
100:VERSE_RECOVERY_PASS_2
118:VERSE_RECOVERY_PASS_3
124:ProcMan: QUARANTINE
```

Repeat negative grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" out/tcb_cap_lifecycle_repeat/boot.log
```

Observed result: no matches.

## Not Proven

- `ProcMan: fault endpoint receive OK` is not proven.
- `ProcMan: decoded worker fault` is not proven.
- Fault-triggered recovery is not proven.
- Real fault endpoint handling is not implemented.
- Clean QEMU shutdown is not proven.
- RWX kernel LOAD segment status is not proven by this document.
