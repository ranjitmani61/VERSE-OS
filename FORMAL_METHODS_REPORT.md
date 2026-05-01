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

## Proven Or Model-Checked Properties

- Sentinel: no forwarded message violates the configured lattice order.
- CortexMM: a component cannot legally access a page unless that page has been granted.
- DharmaNet: observed resource use never exceeds the modeled budget without entering a warning/critical state.
- CodexFS: committed prefix remains valid under the model's append/tamper/commit rules.

## Known Gaps

- The models are bounded TLC-style models unless explicitly lifted to TLAPS.
- The current specs do not form a single compositional system model.
- Watchdog restart semantics are not yet integrated into CodexFS liveness.
- Runtime cooperative restart is not the same as actual TCB suspension/recreation.
- SMP interleavings are not modeled for the shared dataports.

## Model/Runtime Semantic Gap

The current CodexFS specifications model storage enforcement as serialized kernel-side phases. This is intentional for the present x86/QEMU prototype: the relevant checks execute as atomic service actions from the perspective of the user components, so the model treats the log observation and commit frontier update as one indivisible transition.

The runtime recovery path is different. A worker can hang or fault asynchronously while other components continue to execute. Watchdog observes heartbeat loss through a dataport, ProcMan sets a restart flag, and TestWorker cooperatively reinitializes. That demonstrates closed-loop recovery behavior, but it is not the same mechanism as `seL4_TCB_Suspend`, CSpace revoke, VSpace teardown, and fresh TCB creation.

Therefore, the current formal claims should be read as scoped layer guarantees:

- Sentinel, CortexMM, DharmaNet, and CodexFS are model-checked as independent enforcement protocols.
- The running unified demo validates integration and failure observation/recovery signaling.
- A future Recovery TLA+ model must cover `RUNNING -> DEAD -> RESTARTING -> RUNNING` lifecycle semantics.
- A future TCB-capable runtime must replace the cooperative restart flag with enforced suspend/revoke/respawn before claiming real process resurrection.

This is an architectural boundary, not a contradiction: the model proves safety properties of serialized enforcement layers; the current runtime demonstrates cooperative recovery; the next implementation phase must close the gap with TCB authority and a formal recovery loop.

## Next Verification Work

1. Add a unified recovery model with Worker, Watchdog, ProcMan, and restart flag transitions.
2. Add CodexFS recovery epochs so liveness is stated across restarts, not a single execution.
3. Add a multicore memory model for LogRing, heartbeat, restart flag, and severity flag dataports.
4. Promote small invariants to TLAPS once the state machines stabilize.
