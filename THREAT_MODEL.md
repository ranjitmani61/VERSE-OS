# VERSE OS Unified Threat Model

Status: recovered baseline for the current `verse_unified` prototype.

## System Model

The current prototype is a seL4/CAmkES user-space system with these component roles:

- `Sentinel`: IPC information-flow gate for `Client -> Hello`.
- `CortexMM`: capability-style memory provider using a statically wired dataport.
- `DharmaNet`: resource budget monitor using WorkerA/WorkerB counters and severity output.
- `CodexFS`: RAM-backed append-only hash chain store.
- `Watchdog`: heartbeat monitor.
- `ProcMan`: cooperative restart/quarantine controller.
- `LogRing`: shared log sink.
- Clients/workers: `Client`, `Hello`, `MemClient`, `WorkerA`, `WorkerB`, `WriteClient`, `ReadClient`, `TestWorker`.

The current CAmkES assembly is static. Capabilities are distributed by CAmkES at build/boot time. Dynamic capability minting, TCB suspension, persistent storage, SMP, CHERI hardware tags, and TLAPS proofs are out of scope for this prototype.

## Adversary Classes

1. Malicious user component
   - Can execute arbitrary code inside its assigned component.
   - Can send allowed IPC over capabilities it possesses.
   - Cannot forge new seL4 capabilities.

2. Faulty service component
   - Can crash, stall, corrupt its own state, or stop updating shared dataports.
   - Cannot directly corrupt another protection domain except through explicitly shared dataports.

3. Misconfigured build graph
   - Can accidentally wire an illegal IPC or dataport edge in `.camkes`.
   - Mitigated by the capability graph audit tool.

4. Storage tamper adversary
   - Can mutate RAM-backed CodexFS blocks after write in the model.
   - Runtime prototype detects only the simplified checksum/hash-chain invariant.
   - Real persistent tamper resistance requires block storage plus TPM/ROM root hash.

5. Physical/platform adversary
   - Includes cache timing, DMA, power, thermal, bus probing, and microarchitectural leakage.
   - Out of scope for the QEMU/x86 CAmkES prototype.
   - Future work: CHERI hardware, IOMMU/device isolation, SMP model, and side-channel budgets.

## Enforced Invariants

- Sentinel lattice: data may flow only from lower/equal label to higher/equal label in the configured lattice.
- CortexMM prototype: memory sharing is limited to statically granted CAmkES dataports; unconnected memory has no generated accessor/capability path.
- DharmaNet prototype: budget skew is detected and severity is raised with hysteresis, avoiding repeated 50 percent flip-flop.
- CodexFS prototype: committed blocks form a locally verifiable append-only hash chain.
- Watchdog/ProcMan prototype: heartbeat loss is detected and converted into a cooperative restart signal.

## TCB-3: Cooperative Restart Bypass

The current recovery path is cooperative. Watchdog detects heartbeat loss, ProcMan publishes a restart signal through the shared `restart_flag`, and the worker reinitializes only when its own code voluntarily checks that flag.

Threat: a compromised, wedged, or adversarial worker can stop reading `restart_flag`. In that case Watchdog can continue detecting heartbeat loss and ProcMan can continue signaling, but the system cannot force the old worker thread to stop, discard its CSpace/VSpace state, or launch a clean replacement TCB.

Impact: the current prototype demonstrates a recovery protocol and persistent monitoring loop, not enforceable kernel-level restart. A non-cooperative worker can defeat recovery after detection.

Mitigation path: give ProcMan narrowly scoped authority over the managed worker TCB. On timeout or fault, ProcMan should call `seL4_TCB_Suspend(worker_tcb)`, revoke or tear down the worker CSpace/VSpace, rebuild the worker address space from a known-good template, set registers, IPC buffer, scheduling context, and entry point, then resume a fresh worker TCB.

Residual risk: until the CAmkES/capDL build hands ProcMan the required worker TCB and resource capabilities, VERSE OS must describe this path as cooperative restart signaling rather than forced respawn.

## Non-Goals

- No claim of whole-system compositional liveness.
- No claim of complete side-channel elimination.
- No claim of dynamic `seL4_TCB` restart in the current build.
- No claim of CHERI pointer-forgery resistance on x86/QEMU.
- No claim of persistent tamper evidence without a block device and immutable root hash.
- No claim that bounded TLC model checking is equivalent to unbounded TLAPS proof.
