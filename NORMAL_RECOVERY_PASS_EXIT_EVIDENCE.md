# Normal Recovery Pass Exit Evidence

Date: 2026-05-02

## Verdict

Issue 6 is fixed for the required PASS marker, not for clean QEMU shutdown.

Normal recovery now emits:

```text
VERSE_NORMAL_RECOVERY_PASS
```

The marker is printed by `Watchdog` after:

1. `VERSE_RECOVERY_PASS_1`
2. `WDOG: heartbeat resumed, re-armed and monitoring`
3. a normal-mode monitoring window of `HEARTBEAT_MISS_LIMIT * 2` watchdog polls
   without heartbeat loss

QEMU still exits by wrapper timeout. Clean ACPI shutdown or another controlled
machine exit is not proven.

## Code Change

Changed file:

```text
src/apps/verse_unified/components/Watchdog/src/watchdog.c
```

The change adds a normal-mode-only monitoring window:

```c
#ifndef VERSE_TESTWORKER_REPEAT_DEADLOCK
#define NORMAL_PASS_MONITOR_POLLS (HEARTBEAT_MISS_LIMIT * 2)
...
#endif
```

The pass marker is compiled out of repeat-deadlock mode using
`VERSE_TESTWORKER_REPEAT_DEADLOCK`, so exhausted-spare-pool evidence does not
receive a false normal-pass marker.

## Normal Build Evidence

Evidence directory:

```text
out/pass_exit_issue6_20260502_final_normal/
```

Build log:

```text
out/pass_exit_issue6_20260502_final_normal/build.log
```

Observed markers:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
412:PASS_EXIT_ISSUE6_FINAL_NORMAL_BUILD_OK
```

The RWX warning is documented separately in
`RWX_KERNEL_LOAD_SEGMENT_EVIDENCE.md`; it is not fixed by Issue 6.

## Normal Boot Evidence

Boot log:

```text
out/pass_exit_issue6_20260502_final_normal/boot.log
```

Observed runtime markers:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
86:VERSE_NORMAL_RECOVERY_PASS
163:SIMULATE_EXIT:124
```

Rejected-marker grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/pass_exit_issue6_20260502_final_normal/boot.log
```

Observed result: no matches.

Normal recovery therefore no longer depends only on QEMU timeout for a success
signal: the boot log contains an explicit final PASS marker. Clean shutdown is
still not proven.

## Repeat-Deadlock Regression Evidence

Because `Watchdog` was changed, repeat-deadlock mode was rebuilt and booted.

Final repeat evidence directory:

```text
out/pass_exit_issue6_20260502_final_repeat/
```

Build log:

```text
out/pass_exit_issue6_20260502_final_repeat/build.log
```

Observed markers:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
412:PASS_EXIT_ISSUE6_FINAL_REPEAT_BUILD_OK
```

Boot log:

```text
out/pass_exit_issue6_20260502_final_repeat/boot.log
```

Observed runtime markers:

```text
82:VERSE_RECOVERY_PASS_1
100:VERSE_RECOVERY_PASS_2
119:VERSE_RECOVERY_PASS_3
126:ProcMan: QUARANTINE
208:SIMULATE_EXIT:124
```

Fault/error grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" out/pass_exit_issue6_20260502_final_repeat/boot.log
```

Observed result: no matches.

`VERSE_NORMAL_RECOVERY_PASS` is not present in the final repeat-deadlock boot
log.

## Rejected Intermediate Evidence

An earlier Issue 6 repeat run emitted a TestWorker fault-handler data fault:

```text
out/pass_exit_issue6_20260502_repeat/boot.log
```

Observed rejected marker:

```text
112:ProcMan: fFAULT HANDLER: data fault from testworker.testworker_0_control (ID 0x1) on address 0, pc = 0, fsr = 0x4
```

That intermediate patch state was not accepted. The final code tightens the
repeat-mode compile guard and the final repeat run above has no fault/error
matches.

## Not Proven

- Clean ACPI shutdown is not proven.
- Controlled QEMU halt/exit is not implemented.
- QEMU still exits by timeout in the evidence runs: `SIMULATE_EXIT:124`.
- Kernel W^X is not proven.
