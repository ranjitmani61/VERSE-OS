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

## Issue 2 Reverification Run

Date: 2026-05-02

Decision after re-inspection: do not implement a ProcMan fault receive/decode
handler in the current control thread. The fault endpoint path is configured
cleanly, but ProcMan is not proven to be a safe or deterministic receiver for
TestWorker faults.

Source audit for executed receive/decode calls:

```sh
rg -n "seL4_Recv\(|seL4_NBRecv\(|seL4_Poll\(|seL4_GetMR\(|seL4_MessageInfo" src/apps/verse_unified/components/ProcMan/src/procman.c src/apps/verse_unified/components/TestWorker/src/testworker.c
```

Observed result: no matches.

Current ProcMan fault-endpoint source state:

```text
src/apps/verse_unified/components/ProcMan/src/procman.c:10:#ifndef VERSE_WORKER_FAULT_EP_CPTR
src/apps/verse_unified/components/ProcMan/src/procman.c:11:#define VERSE_WORKER_FAULT_EP_CPTR ((seL4_CPtr)0x101)
src/apps/verse_unified/components/ProcMan/src/procman.c:119:static void fault_endpoint_handler_stub(void)
src/apps/verse_unified/components/ProcMan/src/procman.c:121:    (void)VERSE_WORKER_FAULT_EP_CPTR;
src/apps/verse_unified/components/ProcMan/src/procman.c:261:    fault_endpoint_handler_stub();
```

Fresh generated capDL inspected:

```text
out/fault_endpoint_issue2_20260502_normal/verse_unified.cdl
out/fault_endpoint_issue2_20260502_normal/capdl_spec.c
```

ProcMan has TestWorker fault endpoint caps:

```text
5279:    0x100: testworker_testworker_0_control_tcb
5280:    0x101: testworker_fault_ep (R)
5286:    0x108: testworker_fault_ep (RWP)
```

The TestWorker control TCB is configured to deliver faults via CPtr `0x2` in
TestWorker's own CSpace:

```text
4960:testworker_testworker_0_control_tcb = tcb (... fault_ep: 0x00000002)
```

The same generated CSpace also contains a generated TestWorker fault-handler TCB
and an unbadged cap to the same endpoint:

```text
10240:testworker_cnode {
10241:0x1: testworker_testworker_0_control_tcb
10242:0x2: testworker_fault_ep (RWP, badge: 1)
10243:0x3: testworker_testworker_0_fault_handler_tcb
10244:0x4: testworker_fault_ep (RWP)
```

The generated `capdl_spec.c` confirms that the fault-handler TCB is live and
shares the TestWorker CSpace:

```text
.name = "testworker_testworker_0_fault_handler_tcb"
.ipcbuffer_addr = 0x545000
.priority = 255
.pc = 0x406221
.sp = 0x543000
.init = (const seL4_Word[]){3}
.fault_ep = 0
```

Handler decision:

- A blocking `seL4_Recv` in `enforced_restart_worker()` would block the current
  watchdog-driven recovery path before suspend/rebuild when no fault message is
  pending.
- A nonblocking receive in the same path would not prove fault-triggered
  recovery; it would only opportunistically sample the endpoint after watchdog
  detection.
- A separate ProcMan receiver on the same endpoint would race the generated
  TestWorker fault-handler TCB because ProcMan is not the sole receiver.
- A real implementation needs explicit endpoint ownership or a dedicated
  noncompeting ProcMan receiver design, then a deliberate fault test proving
  receive, decode, and recovery.

Fresh normal-mode build and boot evidence:

```text
out/fault_endpoint_issue2_20260502_normal/build.log
out/fault_endpoint_issue2_20260502_normal/boot.log
```

Build marker:

```text
412:FAULT_ENDPOINT_ISSUE2_NORMAL_BUILD_OK
```

Runtime markers:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
152:SIMULATE_EXIT:124
```

Rejected-marker grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/fault_endpoint_issue2_20260502_normal/boot.log
```

Observed result: no matches.

Real-handler marker grep:

```sh
grep -nE "ProcMan: fault endpoint receive OK|ProcMan: decoded worker fault|ProcMan: fault-triggered recovery started" out/fault_endpoint_issue2_20260502_normal/boot.log
```

Observed result: no matches.

Issue 2 status:

- Fault endpoint path configured cleanly: proven for the current recovery path.
- ProcMan fault receive/decode handling: not proven.
- Fault-triggered recovery: not proven.
