# VERSE OS Recovery Manifest

Recovered on: 2026-05-01

## Primary Prototype

The primary local prototype is `verse_unified/`.

Current CAmkES component instances:

1. `LogRing`
2. `Sentinel`
3. `Hello`
4. `Client`
5. `CortexMM`
6. `MemClient`
7. `WorkerA`
8. `WorkerB`
9. `DharmaNet`
10. `CodexFS`
11. `WriteClient`
12. `ReadClient`
13. `TestWorker`
14. `Watchdog`
15. `ProcMan`

The historical notes refer to a 14-component demo. The currently recovered tree has 15 component instances because the `Client`/`Hello` Sentinel path is present as explicit components.

## Preserved Behavior

- Sentinel forwards allowed `Client -> Sentinel -> Hello` IPC.
- CortexMM exposes a CAmkES dataport as the current x86/QEMU memory-capability demo.
- DharmaNet monitors WorkerA/WorkerB skew and emits severity.
- CodexFS writes and verifies an append-only RAM-backed chain.
- Watchdog detects heartbeat loss.
- ProcMan sends a cooperative restart signal.
- TestWorker simulates deadlock and resumes when restart is signaled.
- LogRing aggregates component log messages through shared dataports.

## Support Artifacts

- `THREAT_MODEL.md`
- `FORMAL_METHODS_REPORT.md`
- `tools/capability_audit.py`
- `tools/chaos_monkey.py`
- `MNEMOSYNE_RECONCILIATION.md`
- `SUPPORT_STATUS.md`
- Optional `verse_unified/components/Mnemosyne` scaffold, not wired into the verified assembly yet.
- `src/specs/Sentinel_Lattice.tla`
- `src/specs/CortexMM_Capability.tla`
- `src/specs/DharmaNet_Budget.tla`
- CodexFS TLA specs in the repository root and `src/specs/`

## Known Gaps

- No real `seL4_TCB` suspend/restart in the current CAmkES build.
- `Mnemosyne` exists only as an optional scaffold. Its behavior is still implemented by Watchdog/ProcMan/DharmaNet/LogRing in the verified assembly.
- No SMP runtime validation.
- No CHERI hardware enforcement in the QEMU/x86 prototype.
- No persistent CodexFS block device or TPM/ROM root hash.
- No TLAPS proofs yet.
