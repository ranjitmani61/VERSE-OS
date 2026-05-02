# TCB Repeated Recovery Spare Pool Evidence

Date: 2026-05-02

## Verdict

VERSE OS demonstrates bounded runtime TCB respawn recovery: 3 watchdog-triggered recoveries with heartbeat proof, followed by quarantine after retry exhaustion.

## Proven

- Deadlock detected on each cycle.
- Active worker TCB suspended and quarantined.
- Spare TCB slots rotate: 0x104, 0x109, 0x10a.
- Fresh metadata applied: RIP=0x401116 RSP=0x53a000 IPC=0x53c000.
- Priority restored.
- Spare TCB configured/resumed.
- Watchdog receives recovered heartbeat.
- Recovered worker entry heartbeat proof emitted.
- Watchdog re-arms after each recovery.
- ProcMan enters quarantine after 3 attempts.

## Key Runtime Markers

```text
ProcMan: spare TCB slot for attempt 1 is 0x104
ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
VERSE_RECOVERY_PASS_1
ProcMan: spare TCB slot for attempt 2 is 0x109
ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
VERSE_RECOVERY_PASS_2
ProcMan: spare TCB slot for attempt 3 is 0x10a
ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
VERSE_RECOVERY_PASS_3
ProcMan: QUARANTINE
