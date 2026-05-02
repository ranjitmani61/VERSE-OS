# Negative Tests Issue 4 Reverification Evidence

Date: 2026-05-02

## Verdict

All five required Issue 4 negative tests passed when run one at a time against
the current tree. No test script changes were needed.

The logs are under:

```text
out/negative_tests/
```

Clean QEMU shutdown is still not proven for booting tests; successful boot-based
negative tests still end with `SIMULATE_EXIT:124`.

## 1. Missing Metadata

Script:

```text
tools/negative_missing_metadata.sh
```

Expected: build fails due to the compile-time metadata guard.

Actual result:

```text
PASS: missing metadata build failed on expected compile-time guard
MARKER: VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top
LOG: /home/king/verse_os/out/negative_tests/missing_metadata/build.log
```

Build log marker:

```text
338:/tmp/camkes/projects/camkes/apps/verse_unified/components/ProcMan/src/procman.c:90:2: error: #error "VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top"
339:   90 | #error "VERSE_TCB_ENFORCED requires nonzero worker IPC buffer, entry IP, and stack top"
```

## 2. Bad Fault Endpoint CPtr

Script:

```text
tools/negative_bad_fault_endpoint.sh
```

Expected: build succeeds, boot fails safely through the expected old invalid
fault endpoint CPtr path.

Actual result:

```text
PASS: bad fault endpoint boot produced expected fault marker
MARKER: Caught cap fault in send phase at address 0x108
METADATA: fresh metadata RIP=0x1
LOG: /home/king/verse_os/out/negative_tests/bad_fault_endpoint/boot.log
```

Build and boot markers:

```text
out/negative_tests/bad_fault_endpoint/build.log:412:NEGATIVE_BAD_FAULT_ENDPOINT_BUILD_OK
out/negative_tests/bad_fault_endpoint/boot.log:74:ProcMan: fresh metadata RIP=0x1 RSP=0x53a000 IPC=0x53c000
out/negative_tests/bad_fault_endpoint/boot.log:80:Caught cap fault in send phase at address 0x108
out/negative_tests/bad_fault_endpoint/boot.log:190:SIMULATE_EXIT:124
```

## 3. Exhausted Spare Pool

Script:

```text
tools/negative_exhausted_spare_pool.sh
```

Expected: repeat-deadlock mode consumes the bounded spare pool, reaches three
recovery pass markers, then quarantines.

Actual result:

```text
PASS: exhausted spare pool hit three recovery passes and quarantine
MARKER: VERSE_RECOVERY_PASS_1
MARKER: VERSE_RECOVERY_PASS_2
MARKER: VERSE_RECOVERY_PASS_3
MARKER: ProcMan: QUARANTINE
LOG: /home/king/verse_os/out/negative_tests/exhausted_spare_pool/boot.log
```

Build and boot markers:

```text
out/negative_tests/exhausted_spare_pool/build.log:412:NEGATIVE_EXHAUSTED_SPARE_POOL_BUILD_OK
out/negative_tests/exhausted_spare_pool/boot.log:81:VERSE_RECOVERY_PASS_1
out/negative_tests/exhausted_spare_pool/boot.log:100:VERSE_RECOVERY_PASS_2
out/negative_tests/exhausted_spare_pool/boot.log:119:VERSE_RECOVERY_PASS_3
out/negative_tests/exhausted_spare_pool/boot.log:125:ProcMan: QUARANTINE
out/negative_tests/exhausted_spare_pool/boot.log:213:SIMULATE_EXIT:124
```

Fault/error grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error" out/negative_tests/exhausted_spare_pool/boot.log
```

Observed result: no matches.

## 4. Normal Recovery No Second Restart

Script:

```text
tools/negative_normal_recovery_no_second_restart.sh
```

Expected: normal recovery reaches one pass and watchdog re-arm, without restart
attempt 2/3 or quarantine.

Actual result:

```text
PASS: normal recovery re-armed watchdog without second restart
MARKER: VERSE_RECOVERY_PASS_1
MARKER: WDOG: heartbeat resumed, re-armed and monitoring
ABSENT: ProcMan: restart attempt 2/3
ABSENT: ProcMan: restart attempt 3/3
ABSENT: ProcMan: QUARANTINE
LOG: /home/king/verse_os/out/negative_tests/normal_recovery_no_second_restart/boot.log
```

Build and boot markers:

```text
out/negative_tests/normal_recovery_no_second_restart/build.log:412:NEGATIVE_NORMAL_RECOVERY_NO_SECOND_RESTART_BUILD_OK
out/negative_tests/normal_recovery_no_second_restart/boot.log:82:VERSE_RECOVERY_PASS_1
out/negative_tests/normal_recovery_no_second_restart/boot.log:83:WDOG: heartbeat resumed, re-armed and monitoring
out/negative_tests/normal_recovery_no_second_restart/boot.log:144:SIMULATE_EXIT:124
```

Rejected-marker grep:

```sh
grep -nE "Caught cap fault|vm fault|FAULT HANDLER|fault|Error|ProcMan: restart attempt 2/3|ProcMan: restart attempt 3/3|ProcMan: QUARANTINE" out/negative_tests/normal_recovery_no_second_restart/boot.log
```

Observed result: no matches.

## 5. Occupied Spare Slot

Script:

```text
tools/negative_occupied_spare_slot.sh
```

Expected: injector rejects an already occupied spare slot before boot.

Actual result:

```text
PASS: injector rejected occupied spare slot before boot
MARKER: FAIL: procman_cnode already has slot 0x104:
LOG: /home/king/verse_os/out/negative_tests/occupied_spare_slot/injector.log
```

Build and injector markers:

```text
out/negative_tests/occupied_spare_slot/build.log:405:NEGATIVE_OCCUPIED_SPARE_SLOT_BUILD_OK
out/negative_tests/occupied_spare_slot/injector.log:1:FAIL: procman_cnode already has slot 0x104:
```

## Not Proven

- Clean QEMU shutdown is not proven.
- RWX kernel LOAD segment warning is not resolved by these tests.
- These tests do not prove TCB cap reclamation.
