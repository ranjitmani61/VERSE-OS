# TCB Suspend Runtime Evidence

Date: 2026-05-02

## Verdict

ProcMan successfully exercised runtime seL4 TCB suspend authority over TestWorker.

This is runtime evidence that the injected ProcMan -> TestWorker TCB handoff works far enough for seL4_TCB_Suspend(worker_tcb) to succeed.

## Passing Runtime Marker

ProcMan: enforced TCB restart attempt 1/3
ProcMan: seL4_TCB_Suspend(worker_tcb) OK

## Relevant Runtime Trace

TestWorker: DEADLOCK SIMULATION
WDOG: heartbeat lost after 50 polls, setting kill flag
WDOG: waiting for recovery heartbeat...
ProcMan: restart attempt 1/3
ProcMan: enforced TCB restart attempt 1/3
ProcMan: seL4_TCB_Suspend(worker_tcb) OK
ProcMan: TCB rebuild metadata missing; configure IPC addr, entry IP, and stack top
ProcMan: enforced rebuild failed after suspend; quarantine required
ProcMan: enforced path failed after taking TCB authority - quarantining

## Claim Boundary

Allowed:

- ProcMan has runtime TCB authority over TestWorker in the injected capDL image.
- seL4_TCB_Suspend(worker_tcb) succeeds at runtime.
- The enforced path can take TCB authority and quarantine after rebuild metadata is missing.

Not allowed:

- Fresh TestWorker respawn is implemented.
- seL4_Untyped_Retype, seL4_TCB_Configure, seL4_TCB_WriteRegisters, or seL4_TCB_Resume succeeded.
- Non-cooperative recovery is complete.
- Full self-healing is proven.

## Remaining Engineering Work

To complete enforced respawn, ProcMan still needs correct rebuild metadata:

- fresh TCB destination slot;
- worker CSpace root;
- worker VSpace root;
- worker IPC buffer virtual address;
- worker entry instruction pointer;
- worker stack pointer;
- fault endpoint;
- scheduler parameters where required.
