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

## Proven Or Model-Checked Properties

- Sentinel: no forwarded message violates the configured lattice order.
- CortexMM: a component cannot legally access a page unless that page has been granted.
- DharmaNet: observed resource use never exceeds the modeled budget without entering a warning/critical state.
- CodexFS: committed prefix remains valid under the model's append/tamper/commit rules.

## Known Gaps

- The models are bounded TLC-style models unless explicitly lifted to TLAPS.
- The current specs do not form a single compositional system model.
- Watchdog restart semantics are not yet integrated into CodexFS liveness.
- SMP interleavings are not modeled for the shared dataports.

## In Progress: TCB Recovery Refinement

The TCB restart path has moved from documentation-only to implementation artifacts:

- `src/capdl/verse_tcb_handoff.cdl` drafts the ProcMan/TestWorker authority handoff: ProcMan gets a designated TestWorker TCB cap slot and a receive cap for the TestWorker fault endpoint.
- `CAPDL_INTEGRATION.md` describes how the overlay must be applied to the generated CAmkES capDL output.
- `src/apps/verse_unified/components/ProcMan/src/procman.c` now has a `VERSE_TCB_ENFORCED` path that calls `seL4_TCB_Suspend(worker_tcb)` when the native build supplies the cap.
- `src/specs/Recovery_TCB.tla` contains the standalone TCB recovery model with forced suspend, fault endpoint trigger, resource revoke, fresh TCB, and resume transitions.

This is not yet a completed enforced-respawn proof or runtime. The current repository has bounded TLC evidence for the standalone TCB model and a guarded C compile skeleton, but the real native build still must inject the caps, implement CSpace/VSpace teardown, configure the fresh TCB, and discharge any full refinement proof with TLAPS or a stronger model.

## Model/Runtime Semantic Gap

The current CodexFS specifications model storage enforcement as serialized kernel-side phases. This is intentional for the present x86/QEMU prototype: the relevant checks execute as atomic service actions from the perspective of the user components, so the model treats the log observation and commit frontier update as one indivisible transition.

The runtime recovery path is different. A worker can hang or fault asynchronously while other components continue to execute. Watchdog observes heartbeat loss through a dataport, ProcMan sets a restart flag, and TestWorker cooperatively reinitializes. That demonstrates closed-loop recovery behavior. The TCB-enforced path is now being implemented behind `VERSE_TCB_ENFORCED`, but the current default Docker build still uses cooperative restart.

Therefore, the current formal claims should be read as scoped layer guarantees:

- Sentinel, CortexMM, DharmaNet, and CodexFS are model-checked as independent enforcement protocols.
- The running unified demo validates integration and failure observation/recovery signaling.
- `Recovery_Task.tla` covers the cooperative `RUNNING -> DEAD -> RESTARTING -> RUNNING` lifecycle.
- `Recovery_TCB.tla` is a standalone bounded refinement-shape model for enforced suspend/revoke/fresh-TCB recovery.
- The runtime must still complete native capDL integration and fresh TCB construction before claiming real process resurrection.

This is an architectural boundary, not a contradiction: the model proves safety properties of serialized enforcement layers; the current runtime demonstrates cooperative recovery; the next implementation phase is closing the gap with TCB authority, capDL handoff, and a formal recovery refinement.

## Next Verification Work

1. Extend `Recovery_Task.tla` and `Recovery_TCB.tla` beyond tiny bounded TLC checks, or promote stable obligations to TLAPS.
2. Add CodexFS recovery epochs so liveness is stated across restarts, not a single execution.
3. Add a multicore memory model for LogRing, heartbeat, restart flag, and severity flag dataports.
4. Promote small invariants to TLAPS once the state machines stabilize.
