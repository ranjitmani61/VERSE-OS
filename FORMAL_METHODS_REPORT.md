# VERSE OS Formal Methods Report

Status: recovered baseline for the current prototype and available specs.

## Scope

The formal work is a collection of scoped safety models, not a single proof of the whole OS. The runtime system includes asynchronous faults, watchdog recovery, shared dataports, and cooperative restart behavior that are not all represented in one unified TLA+ model.

## Current Proof Artifacts

- `CodexFS_Final.tla`: compact CodexFS append/tamper/commit safety model.
- `CodexFS_Monotonic_v18.tla`, `CodexFS_Monotonic_v19.tla`, `CodexFS_Monotonic_v19_5.tla`: later CodexFS monotonicity iterations.
- `src/specs/CodexFS_Monotonic_v12.tla`: earlier CodexFS model.
- `src/specs/Sentinel_Lattice.tla`: recovered scoped Sentinel lattice safety model.
- `src/specs/CortexMM_Capability.tla`: recovered scoped memory grant/access model.
- `src/specs/DharmaNet_Budget.tla`: recovered scoped budget monitor model.
- `src/specs/Recovery_Task.tla`: cooperative recovery model with bounded TypeOK, deadlock, and recovery-resolution checks.
- `src/specs/Recovery_TCB.tla`: standalone bounded TCB recovery/refinement-shape model for the guarded native restart path.
- `src/specs/Bounded_Active_TCB_Failover.tla`: bounded active-TCB slot failover model for `0x100 -> 0x104 -> 0x109 -> 0x10a -> Quarantined`.

## Proven Or Model-Checked Properties

- Sentinel: no forwarded message violates the configured lattice order.
- CortexMM: a component cannot legally access a page unless that page has been granted.
- DharmaNet: observed resource use never exceeds the modeled budget without entering a warning/critical state.
- CodexFS: committed prefix remains valid under the model's append/tamper/commit rules.
- Bounded active-TCB failover: TLC checks that the active TCB is never quarantined, each recovery uses a fresh unused spare, retry count stays `<= 3`, normal recovery reaches `StableRecovered`, and exhausted spare pool reaches `Quarantined`.

## Known Gaps

- The models are bounded TLC-style models unless explicitly lifted to TLAPS.
- The current specs do not form a single compositional system model.
- `Bounded_Active_TCB_Failover.tla` is a bounded abstract failover model, not a C refinement proof, TLAPS proof, capDL proof, or seL4 kernel proof.
- Watchdog restart semantics are not yet integrated into CodexFS liveness.
- SMP interleavings are not modeled for the shared dataports.

## TCB Recovery Refinement Status

The TCB restart path has moved beyond documentation-only artifacts. Current
runtime evidence separately demonstrates bounded active-TCB failover with
watchdog-confirmed worker recovery. The formal artifacts remain scoped models,
not full implementation refinement proofs.

- `tools/inject_tcb_handoff.py` injects the ProcMan/TestWorker authority handoff into generated capDL.
- `src/apps/verse_unified/components/ProcMan/src/procman.c` has a `VERSE_TCB_ENFORCED` path that suspends the active worker TCB, configures a spare TCB, and resumes it.
- `src/specs/Recovery_TCB.tla` contains the standalone TCB recovery model with forced suspend, fault endpoint trigger, resource revoke, fresh TCB, and resume transitions.
- `src/specs/Bounded_Active_TCB_Failover.tla` models the bounded concrete active-TCB sequence and spare-pool exhaustion.

The remaining formal gap is a real refinement proof from C/capDL execution to
the TLA+ model. TCB cap delete/revoke cleanup and real fault endpoint
receive/decode handling are also not proven.

## Model/Runtime Semantic Gap

The current CodexFS specifications model storage enforcement as serialized kernel-side phases. This is intentional for the present x86/QEMU prototype: the relevant checks execute as atomic service actions from the perspective of the user components, so the model treats the log observation and commit frontier update as one indivisible transition.

The runtime recovery path is different. A worker can hang or fault asynchronously while other components continue to execute. Watchdog observes heartbeat loss through a dataport, ProcMan sets a restart flag, and TestWorker cooperatively reinitializes. That demonstrates closed-loop recovery behavior. The TCB-enforced path is now being implemented behind `VERSE_TCB_ENFORCED`, but the current default Docker build still uses cooperative restart.

Therefore, the current formal claims should be read as scoped layer guarantees:

- Sentinel, CortexMM, DharmaNet, and CodexFS are model-checked as independent enforcement protocols.
- The running unified evidence validates bounded active-TCB failover with watchdog-confirmed recovery.
- `Recovery_Task.tla` covers the older cooperative `RUNNING -> DEAD -> RESTARTING -> RUNNING` lifecycle.
- `Recovery_TCB.tla` is a standalone bounded refinement-shape model for enforced suspend/revoke/fresh-TCB recovery.
- `Bounded_Active_TCB_Failover.tla` covers the concrete bounded active-TCB sequence and quarantine behavior.

This is an architectural boundary, not a contradiction: the model proves safety
properties of serialized enforcement layers; the runtime evidence proves the
bounded active-TCB failover path; the remaining formal work is refinement, not a
full OS proof.

## Next Verification Work

1. Extend `Recovery_Task.tla` and `Recovery_TCB.tla` beyond tiny bounded TLC checks, or promote stable obligations to TLAPS.
2. Add CodexFS recovery epochs so liveness is stated across restarts, not a single execution.
3. Add a multicore memory model for LogRing, heartbeat, restart flag, and severity flag dataports.
4. Promote small invariants to TLAPS once the state machines stabilize.
