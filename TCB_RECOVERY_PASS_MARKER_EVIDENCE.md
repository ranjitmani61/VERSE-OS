# TCB Recovery PASS Marker Evidence

Date: 2026-05-02

## Verdict

Runtime TCB respawn now restores watchdog-observed heartbeat and emits an explicit PASS marker.

## Proven Markers

```text
52:TestWorker: started
53:ProcMan: waiting
54:WDOG: active monitoring
65:TestWorker: DEADLOCK SIMULATION
66:WDOG: heartbeat lost after 50 polls, setting kill flag
67:WDOG: waiting for recovery heartbeat...
68:ProcMan: restart attempt 1/3
69:ProcMan: enforced TCB restart attempt 1/3
70:ProcMan: seL4_TCB_Suspend(worker_tcb) OK
71:ProcMan: old worker TCB suspended and quarantined
72:ProcMan: fresh metadata RIP=0x401116 RSP=0x53a000 IPC=0x53c000
73:ProcMan: fresh TestWorker priority set to 254
74:ProcMan: fresh TestWorker TCB configured and resWDOG: recovery heartbeat received (1000001)
75:WDOG: recovered worker entry heartbeat proof
76:VERSE_RECOVERY_PASS
77:WDOG: heartbeat resumed, re-armed and monitoring
79:ProcMan: restart done
```

## Honest Scope

Proven: one runtime TCB respawn recovery reaches recovered worker heartbeat execution and watchdog re-arm.

Not yet proven: repeated restart cycles, old TCB deletion/revocation, resource leak freedom, negative safety paths, DHARMA return-to-OK, clean QEMU shutdown.
