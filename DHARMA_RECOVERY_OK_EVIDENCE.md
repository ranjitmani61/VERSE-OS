# DHARMA Recovery OK Evidence

Date: 2026-05-02

## Verdict

DHARMA now has an explicit recovery signal from Watchdog and emits
`DHARMA: OK after recovery` after watchdog-confirmed recovered worker
heartbeats.

This does not prove that DHARMA remains permanently OK. The existing worker
balance inputs can later drive DHARMA back to `WARN`.

## Implementation

The previous dirty experiment tried to infer recovery from `workerA_buf` and
`workerB_buf`. That was not a real recovery signal.

The committed path adds:

- `watchdog.recovery_signal`
- `dharmanet.recovery_signal`
- `seL4SharedData rs(from watchdog.recovery_signal, to dharmanet.recovery_signal)`

Watchdog writes the recovery pass count when it observes a recovered heartbeat
`>= 1000000`. DharmaNet observes new pass counts, clears its local warning and
critical state, sets severity to 0, and logs:

```text
DHARMA: OK after recovery
```

## Normal Runtime Evidence

Build log:

```text
out/dharma_recovery_ok_normal/build.log
```

Boot log:

```text
out/dharma_recovery_ok_normal/boot.log
```

Observed grep:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
84:DHARMA: OK after recovery
179:SIMULATE_EXIT:124
```

Negative grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/dharma_recovery_ok_normal/boot.log
```

Observed result: no matches.

## Repeat Runtime Evidence

Build log:

```text
out/dharma_recovery_ok_repeat/build.log
```

Boot log:

```text
out/dharma_recovery_ok_repeat/boot.log
```

Observed grep:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
84:DHARMA: OK after recovery
89:ProcMan: restart attempt 2/3
101:VERSE_RECOVERY_PASS_2
102:WDOG: heartbeat resumed, re-armed and monitoring
103:DHARMA: OK after recovery
108:ProcMan: restart attempt 3/3
120:VERSE_RECOVERY_PASS_3
121:WDOG: heartbeat resumed, re-armed and monitoring
122:DHARMA: OK after recovery
127:ProcMan: QUARANTINE
218:SIMULATE_EXIT:124
```

Fault/error grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" out/dharma_recovery_ok_repeat/boot.log
```

Observed result: no matches.

## Not Proven

- Permanent DHARMA OK state is not proven.
- Clean QEMU shutdown is not proven.
- RWX kernel LOAD segment status is not proven by this document.

## Issue 3 Reverification Run

Date: 2026-05-02

Decision after source inspection: no revert is needed and no new code change is
needed for Issue 3. There is no tracked dirty diff in the DharmaNet, Watchdog,
or assembly files. The current committed design already uses an explicit
`recovery_signal` dataport from Watchdog to DharmaNet.

Inspected source:

```text
src/apps/verse_unified/components/DharmaNet/src/dharmanet.c
src/apps/verse_unified/components/DharmaNet/DharmaNet.camkes
src/apps/verse_unified/components/Watchdog/src/watchdog.c
src/apps/verse_unified/components/Watchdog/Watchdog.camkes
src/apps/verse_unified/verse_unified.camkes
```

Relevant source state:

```text
src/apps/verse_unified/verse_unified.camkes:58:        connection seL4SharedData rs(from watchdog.recovery_signal, to dharmanet.recovery_signal);
src/apps/verse_unified/components/Watchdog/src/watchdog.c:35:        if (recovered >= 1000000) {
src/apps/verse_unified/components/Watchdog/src/watchdog.c:36:            recovery_passes++;
src/apps/verse_unified/components/Watchdog/src/watchdog.c:37:            *rsig = recovery_passes;
src/apps/verse_unified/components/DharmaNet/src/dharmanet.c:26:        int recovery_pass = *recovery;
src/apps/verse_unified/components/DharmaNet/src/dharmanet.c:27:        if(recovery_pass!=0 && recovery_pass!=seen_recovery){
src/apps/verse_unified/components/DharmaNet/src/dharmanet.c:30:            lw("DHARMA: OK after recovery\n");
```

Fresh normal-mode build and boot evidence:

```text
out/dharma_issue3_20260502_normal/build.log
out/dharma_issue3_20260502_normal/boot.log
```

Build marker:

```text
412:DHARMA_ISSUE3_NORMAL_BUILD_OK
```

Runtime markers:

```text
69:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
84:DHARMA: OK after recovery
149:SIMULATE_EXIT:124
```

Rejected-marker grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/dharma_issue3_20260502_normal/boot.log
```

Observed result: no matches.

The same boot later emitted `DHARMA: WARN (...)` again because the existing
WorkerA/WorkerB ratio monitor continues running after the recovery marker. That
does not invalidate the required Issue 3 marker, but permanent DHARMA OK remains
not proven.

Issue 3 status: `DHARMA: OK after recovery` is reproven through the explicit
Watchdog-to-DharmaNet dataport path.
