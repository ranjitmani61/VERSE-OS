# Occupied Spare Slot Negative Test Evidence

## Scope

This negative test proves the capDL injector rejects an occupied ProcMan handoff/spare slot before boot. The test generates normal capDL, inserts a synthetic `procman_cnode` entry at `0x104`, then runs `tools/inject_tcb_handoff.py`.

No boot image is produced for this test after the occupied slot is detected.

## Test Script

Script:

```sh
tools/negative_occupied_spare_slot.sh
```

Build options used by the script:

```sh
-DVERSE_TCB_ENFORCED=ON
```

Expected injector marker:

```text
FAIL: procman_cnode already has slot 0x104:
```

## Evidence

Build log:

```text
out/negative_tests/occupied_spare_slot/build.log
```

Build result:

```text
405:NEGATIVE_OCCUPIED_SPARE_SLOT_BUILD_OK
```

The existing unresolved linker warning is still present and not hidden:

```text
402:/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

Injected occupied slot:

```text
5269:    0x104: testworker_fault_ep (R)
```

Injector log:

```text
out/negative_tests/occupied_spare_slot/injector.log
```

Injector result:

```text
FAIL: procman_cnode already has slot 0x104:
```

Result log:

```text
PASS: injector rejected occupied spare slot before boot
MARKER: FAIL: procman_cnode already has slot 0x104:
LOG: /home/king/verse_os/out/negative_tests/occupied_spare_slot/injector.log
```

Output capDL check:

```text
SHOULD_NOT_BE_WRITTEN_ABSENT
```

## Claim

Occupied spare slot handling is covered by a deterministic pre-boot injector test. The injector refuses to write a handoff capDL when ProcMan slot `0x104` is already occupied.
