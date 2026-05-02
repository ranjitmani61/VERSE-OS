# TCB Recovery Critic Cleanup Audit

Date: 2026-05-02

## Current Valid Claim

VERSE OS demonstrates bounded runtime TCB respawn recovery: 3 watchdog-triggered recoveries with heartbeat proof, followed by quarantine after retry exhaustion.

## Cleared Critic Points

- Metadata is not zero in the enforced build. CMake defines `VERSE_WORKER_IPC_BUFFER_ADDR=0x53c000`, `VERSE_WORKER_ENTRY_IP=0x401116`, and `VERSE_WORKER_STACK_TOP=0x53a000`.
- `procman.c` fallback zero values are guarded by `#ifndef`; they are not used in the active enforced build.
- The enforced build now has a compile-time metadata guard.
- Runtime output proves nonzero metadata: `ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000`.
- Runtime output proves spare TCB rotation: `0x104`, `0x109`, `0x10a`.
- Runtime output proves recovery passes: `VERSE_RECOVERY_PASS_1`, `VERSE_RECOVERY_PASS_2`, `VERSE_RECOVERY_PASS_3`.
- Runtime retype one-shot failure was fixed by removing runtime `seL4_Untyped_Retype` from the recovery path and using a pre-created spare TCB pool.

## Still Open

- DHARMA return-to-OK.
- Old TCB cap revoke/delete proof.
- Fault endpoint behavior.
- Negative tests.
- Formal proof.
- RWX kernel LOAD segment warning.
- Clean shutdown/pass exit.
