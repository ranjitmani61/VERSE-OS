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
