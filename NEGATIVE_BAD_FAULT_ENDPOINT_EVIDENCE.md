# Bad Fault Endpoint Negative Test Evidence

## Scope

This negative test exercises the non-MCS `seL4_TCB_Configure` fault endpoint argument by deliberately configuring the fresh TestWorker TCB with an invalid fault endpoint CPtr (`0x108`) and a nonzero invalid recovery entry IP (`0x1`).

The invalid entry IP is test-only and exists to force a worker fault so the bad fault endpoint path is exercised. Normal recovery still uses `VERSE_WORKER_CONFIGURE_FAULT_EP_CPTR=0x2` and `VERSE_WORKER_ENTRY_IP=0x401116`.

## Test Script

Script:

```sh
tools/negative_bad_fault_endpoint.sh
```

Build options used by the script:

```sh
-DVERSE_TCB_ENFORCED=ON
-DVERSE_NEGATIVE_BAD_FAULT_ENDPOINT=ON
```

Expected markers:

```text
fresh metadata RIP=0x1
Caught cap fault in send phase at address 0x108
```

## Evidence

Build log:

```text
out/negative_tests/bad_fault_endpoint/build.log
```

Build result:

```text
412:NEGATIVE_BAD_FAULT_ENDPOINT_BUILD_OK
```

The existing unresolved linker warning is still present and not hidden:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

Boot log:

```text
out/negative_tests/bad_fault_endpoint/boot.log
```

Relevant grep output:

```text
70:ProcMan: restart attempt 1/3
75:ProcMan: fresh metadata RIP=0x1 RSP=0x53a000 IPC=0x53c000
77:ProcMan: active worker TCB mCaught cap fault in send phase at address 0x108
79:vm fault on data at address 0x1 with status 0x4
180:SIMULATE_EXIT:124
```

Result log:

```text
PASS: bad fault endpoint boot produced expected fault marker
MARKER: Caught cap fault in send phase at address 0x108
METADATA: fresh metadata RIP=0x1
LOG: /home/king/verse_os/out/negative_tests/bad_fault_endpoint/boot.log
```

## Normal Regression Check

Default normal build/boot after adding the test-only option:

```text
out/negative_tests/bad_fault_endpoint/default_normal/build.log
out/negative_tests/bad_fault_endpoint/default_normal/boot.log
```

Pass markers:

```text
70:ProcMan: restart attempt 1/3
82:VERSE_RECOVERY_PASS_1
83:WDOG: heartbeat resumed, re-armed and monitoring
84:DHARMA: OK after recovery
150:SIMULATE_EXIT:124
```

Failure grep produced no lines for:

```text
Caught cap fault|vm fault|FAULT HANDLER|fault|Error|restart attempt 2/3|restart attempt 3/3|ProcMan: QUARANTINE
```

## Claim

Bad fault endpoint CPtr behavior is now covered by a deterministic negative boot test. Fault endpoint receive/decode handling remains not proven; this test only proves that a deliberately bad fault endpoint CPtr is observable as a kernel cap fault when the fresh TCB faults.
