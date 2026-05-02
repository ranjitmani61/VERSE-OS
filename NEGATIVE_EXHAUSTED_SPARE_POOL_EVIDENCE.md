# Exhausted Spare Pool Negative Test Evidence

## Scope

This negative test builds TestWorker with repeat-deadlock fault injection enabled. The expected behavior is bounded recovery through the three configured spare TCB slots followed by ProcMan quarantine after retry exhaustion.

This test does not claim cap reclamation. The cap lifecycle remains bounded quarantine with no runtime delete/revoke proven.

## Test Script

Script:

```sh
tools/negative_exhausted_spare_pool.sh
```

Build options used by the script:

```sh
-DVERSE_TCB_ENFORCED=ON
-DVERSE_TESTWORKER_REPEAT_DEADLOCK=ON
```

Expected markers:

```text
VERSE_RECOVERY_PASS_1
VERSE_RECOVERY_PASS_2
VERSE_RECOVERY_PASS_3
ProcMan: QUARANTINE
```

Unexpected markers rejected by the script:

```text
Caught cap fault|vm fault|FAULT HANDLER|fault|Error
```

## Evidence

Build log:

```text
out/negative_tests/exhausted_spare_pool/build.log
```

Build result:

```text
412:NEGATIVE_EXHAUSTED_SPARE_POOL_BUILD_OK
```

The existing unresolved linker warning is still present and not hidden:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

Boot log:

```text
out/negative_tests/exhausted_spare_pool/boot.log
```

Relevant grep output:

```text
70:ProcMan: restart attempt 1/3
74:ProcMan: spare TCB slot for attempt 1 is 0x104
82:VERSE_RECOVERY_PASS_1
89:ProcMan: restart attempt 2/3
93:ProcMan: spare TCB slot for attempt 2 is 0x109
101:VERSE_RECOVERY_PASS_2
107:ProcMan: restart attempt 3/3
111:ProcMan: spare TCB slot for attempt 3 is 0x10a
119:VERSE_RECOVERY_PASS_3
125:WDOG: waiting for recovery heartbeat.ProcMan: QUARANTINE
205:SIMULATE_EXIT:124
```

Result log:

```text
PASS: exhausted spare pool hit three recovery passes and quarantine
MARKER: VERSE_RECOVERY_PASS_1
MARKER: VERSE_RECOVERY_PASS_2
MARKER: VERSE_RECOVERY_PASS_3
MARKER: ProcMan: QUARANTINE
LOG: /home/king/verse_os/out/negative_tests/exhausted_spare_pool/boot.log
```

## Claim

Exhausted spare pool behavior is covered by a deterministic negative boot test. The bounded pool still uses spare TCB slots `0x104`, `0x109`, and `0x10a`, then ProcMan enters quarantine.
