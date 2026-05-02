# Normal Recovery No-Second-Restart Test Evidence

## Scope

This test covers the normal recovered-worker path. The expected behavior is one watchdog-triggered TCB recovery, recovery heartbeat detection, watchdog re-arm, and no second or third ProcMan restart attempt in the test window.

## Test Script

Script:

```sh
tools/negative_normal_recovery_no_second_restart.sh
```

Build options used by the script:

```sh
-DVERSE_TCB_ENFORCED=ON
```

Expected markers:

```text
VERSE_RECOVERY_PASS_1
WDOG: heartbeat resumed, re-armed and monitoring
```

Rejected markers:

```text
Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE
```

## Evidence

Build log:

```text
out/negative_tests/normal_recovery_no_second_restart/build.log
```

Build result:

```text
412:NEGATIVE_NORMAL_RECOVERY_NO_SECOND_RESTART_BUILD_OK
```

The existing unresolved linker warning is still present and not hidden:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

Boot log:

```text
out/negative_tests/normal_recovery_no_second_restart/boot.log
```

Relevant grep output:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
84:DHARMA: OK after recovery
151:SIMULATE_EXIT:124
```

Result log:

```text
PASS: normal recovery re-armed watchdog without second restart
MARKER: VERSE_RECOVERY_PASS_1
MARKER: WDOG: heartbeat resumed, re-armed and monitoring
ABSENT: ProcMan: restart attempt 2/3
ABSENT: ProcMan: restart attempt 3/3
ABSENT: ProcMan: QUARANTINE
LOG: /home/king/verse_os/out/negative_tests/normal_recovery_no_second_restart/boot.log
```

## Claim

Normal recovered-worker mode is covered by a deterministic boot test that rejects repeat recovery and quarantine markers in the captured test window.
