# CLAIM_AUDIT

Date: 2026-05-02
Scope: maintained docs requested by the release verification task.

Maintained docs scanned:

- `VERSE_OS_VERIFICATION_REPORT.md`
- `real-architecture.md`
- `architecture.md`
- `SUPPORT_STATUS.md`
- `FORMAL_METHODS_REPORT.md`
- `THREAT_MODEL.md`
- `RECOVERY_MANIFEST.md`
- `NATIVE_SEL4_TCB_SETUP.md`
- `CAPDL_INTEGRATION.md`
- `MNEMOSYNE_RECONCILIATION.md`

Scan command:

```bash
rg -n -i "formally verified|proven|self-healing|secure|hardened|scheduler enforcement|TCB restart|cryptographic|impossible|guaranteed|production-ready|production ready" VERSE_OS_VERIFICATION_REPORT.md real-architecture.md architecture.md SUPPORT_STATUS.md FORMAL_METHODS_REPORT.md THREAT_MODEL.md RECOVERY_MANIFEST.md NATIVE_SEL4_TCB_SETUP.md CAPDL_INTEGRATION.md MNEMOSYNE_RECONCILIATION.md
```

Release rule: any strong claim not explicitly classified as supported below is frozen. Frozen means it must not be used as a release claim until linked to exact current source, build output, runtime log, or TLC output.

## Claim Findings

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| DOC-CLAIM-001 | PARTIAL | `real-architecture.md:3` | `A capability-enforced, formally verified, self-healing microkernel operating system` | Overstates the current repo. seL4 is the formally verified kernel dependency; VERSE user components are not formally verified as a whole. Runtime recovery is cooperative. | Replace with scoped wording: buildable seL4/CAmkES prototype with bounded TLC models and cooperative recovery evidence. |
| DOC-CLAIM-002 | PARTIAL | `real-architecture.md:9` | `running on the formally verified seL4 kernel` | Supported only as a claim about seL4, not about all VERSE code. | Cite seL4 version/proof scope or phrase as assumption/dependency. |
| DOC-CLAIM-003 | BROKEN | `real-architecture.md:9`; `TLA-CODEX-003`; `TLA-CODEX-004` | `Each safety layer has been formally specified in TLA+ and model-checked with TLC under bounded parameters.` | Current canonical CodexFS v19.5 fails TLC; Recovery liveness fails when explicitly checked. | Fix CodexFS v19.5 and Recovery liveness, or downgrade the claim to named passing scoped specs only. |
| DOC-CLAIM-004 | NOT PROVEN | `real-architecture.md:9` | `survives combined memory corruption, RPC floods, and CPU exhaustion attacks` | No current canonical runtime log in this pass proves the combined adversarial scenario. Static chaos harness is not runtime chaos. | Add a reproducible runtime chaos test script and log against `src/apps/verse_unified`. |
| DOC-CLAIM-005 | PARTIAL | `real-architecture.md:9`; `RUN-002` | `performs a closed-loop self-healing cycle from fault detection through worker restart` | Runtime evidence proves cooperative same-worker reinitialization after simulated deadlock, not TCB restart or fresh process replacement. | Say "cooperative recovery loop"; reserve "self-healing" for a defined acceptance test. |
| DOC-CLAIM-006 | SUPPORTED | `real-architecture.md:33` | `Formally verified functional correctness (machine-checked proof from abstract specification to C implementation).` | Acceptable only as a seL4 kernel dependency statement. | Keep scoped to seL4; do not imply VERSE components are verified. |
| DOC-CLAIM-007 | NOT PROVEN | `real-architecture.md:86` | `Access to unwired dataport (secret_page) is compile-time impossible.` | No negative build test was run in this pass. Static CAmkES wiring supports least-authority shape but does not prove this exact claim. | Add a negative app build that attempts to access `secret_page` and fails at CAmkES/C compile time. |
| DOC-CLAIM-008 | BROKEN | `real-architecture.md:110`; `SRC-CODEX-001` | `Cryptographic Append-Only Integrity Store` | Runtime CodexFS uses an 8-bit XOR checksum (`cs`), not a cryptographic hash. | Remove "cryptographic" until runtime uses a real cryptographic hash or a verified crypto abstraction. |
| DOC-CLAIM-009 | BROKEN | `real-architecture.md:112`; `SRC-CODEX-001` | `cryptographically linked to its predecessor` | Runtime stores one-byte `ph` and one-byte XOR `h`; no cryptographic link exists. | Implement real hash chaining or downgrade to "toy checksum-linked in-memory demo." |
| DOC-CLAIM-010 | STALE/BROKEN | `real-architecture.md:119-126`; `TLA-CODEX-003`; `TLA-CODEX-004` | `CodexFS.tla, canonical version`; `Verified by TLC: 624 distinct states, zero violations.` | Documented canonical file names do not match current top-level cfg pair; current v19.5 fails. | Update canonical spec path and state counts after a passing run. |
| DOC-CLAIM-011 | PARTIAL | `real-architecture.md:137-146`; `RUN-002`; `SRC-PROCMAN-001` | `Self-Healing Subsystem`; `Worker reinitialises on restart-flag` | Supported only for cooperative restart flag path. | Mark as cooperative recovery; do not imply enforced restart. |
| DOC-CLAIM-012 | NOT PROVEN | `real-architecture.md:188` | `Null dereference ... seL4 traps fault; watchdog detects; ProcMan restarts` | No current null-dereference runtime log was reviewed. | Add null-dereference test log with fault, watchdog detection, ProcMan action, and recovery. |
| DOC-CLAIM-013 | NOT PROVEN | `real-architecture.md:190-191` | `Chaos Monkey (combined) ... All 14 components survive`; `Stack overflow ...` | No current runtime chaos/stack-overflow log was reviewed. | Add current runtime logs and exact commands. |
| DOC-CLAIM-014 | BROKEN | `real-architecture.md:253-257` | `CodexFS.tla -config CodexFS.cfg` | Command is stale; current run reports missing `CodexFS.cfg`. | Replace with current canonical command after CodexFS passes. |
| DOC-CLAIM-015 | NOT PROVEN | `real-architecture.md:269` | `most formally specified, adversarially tested, capability-confined microkernel architecture in the open literature` | Comparative literature claim not proven by repo evidence. | Remove from release docs or support with external survey and current passing artifacts. |
| DOC-CLAIM-016 | PARTIAL | `SUPPORT_STATUS.md:3` | `Restored And Verified` | "Verified" is too broad. Some artifacts build/run; some TLC checks fail. | Split into restored, build-tested, runtime-observed, model-checked, broken. |
| DOC-CLAIM-017 | PARTIAL | `SUPPORT_STATUS.md:14` | `Verified Commands` | Passing commands can be called observed passing, not broad verification. | Rename to "Observed passing commands" with date and output. |
| DOC-CLAIM-018 | SUPPORTED | `SUPPORT_STATUS.md:69`; `SRC-PROCMAN-001` | `cooperative recovery model. It requires the worker to voluntarily observe restart_flag; it does not claim forced TCB restart.` | This is accurate and should be preserved. | Keep. |
| DOC-CLAIM-019 | PARTIAL | `FORMAL_METHODS_REPORT.md:19` | `Proven Or Model-Checked Properties` | Some small scoped specs pass; CodexFS v19.5 and Recovery liveness do not. | Rename to "Scoped model-checking results" and list current pass/fail results. |
| DOC-CLAIM-020 | PARTIAL | `FORMAL_METHODS_REPORT.md:35` | `The TCB restart path has moved from documentation-only to implementation artifacts` | Source has guarded stubs and capDL draft, but no runtime TCB restart. | Keep only with explicit "not runtime-proven" caveat. |
| DOC-CLAIM-021 | SUPPORTED | `NATIVE_SEL4_TCB_SETUP.md:187`; `RUN-003` | `cooperative self-healing, not real TCB-based respawn` | Accurate boundary: runtime log lacks TCB restart strings. | Prefer "cooperative recovery" over "self-healing" for release language. |
| DOC-CLAIM-022 | PARTIAL | `CAPDL_INTEGRATION.md:66` | `once the slot contract is proven` | Future condition, not current proof. | Keep as future work; do not imply current proof. |
| DOC-CLAIM-023 | PARTIAL | `MNEMOSYNE_RECONCILIATION.md:18` | `verified verse_unified.camkes wiring` | Static audit/build support wiring, but no formal capDL proof. | Change to "audited/build-tested wiring" if docs are later edited. |
| DOC-CLAIM-024 | PARTIAL | `RECOVERY_MANIFEST.md:48` | `verified assembly` | Same issue: build/runtime-tested assembly, not formal verification. | Change to "current build-tested assembly." |
| DOC-CLAIM-025 | NOT PROVEN | `architecture.md:26` | `secure, reliable, single-fire messages that are guaranteed to be delivered exactly once` | Speculative architecture claim; no current implementation evidence. | Remove from release claims or provide a model/runtime test. |
| DOC-CLAIM-026 | NOT PROVEN | `architecture.md:35` | `A small, formally verified microkernel ...` | Acceptable only as seL4-like design text; not evidence of VERSE implementation beyond seL4 dependency. | Scope to seL4 dependency if retained. |
| DOC-CLAIM-027 | NOT PROVEN | `architecture.md:56` | `physically guaranteeing no stale pointers can ever leak` | No current source/build/runtime proof. | Remove from release claims. |
| DOC-CLAIM-028 | NOT PROVEN | `architecture.md:59` | `cryptographically unique`; `impossible, physically denied event` | No current implementation evidence. | Remove or mark speculative. |
| DOC-CLAIM-029 | NOT PROVEN | `architecture.md:69` | `statistically proven and formally verified` | No current implementation evidence. | Remove or mark speculative future concept. |
| DOC-CLAIM-030 | NOT PROVEN | `architecture.md:124` | `making DMA attacks and post-exploitation persistence electrically impossible` | No current implementation evidence. | Remove from release claims. |
| DOC-CLAIM-031 | NOT PROVEN | `architecture.md:154` | `single, formally verified grounding plane`; `cryptographic checks`; `impossible` | No current implementation evidence. | Remove from release claims. |
| DOC-CLAIM-032 | NOT PROVEN | `architecture.md:1638-1647` | `verified static dataflow graph`; `liveness is formally proven`; `verified dynamic update protocol` | No current TLC/runtime evidence for this system. | Remove or mark future research. |
| DOC-CLAIM-033 | NOT PROVEN | `architecture.md:1894-1896` | `cryptographic guarantees`; `cryptographic integrity`; `Self-healing ... Intact` | Not supported by current runtime/source; CodexFS is XOR checksum, recovery is cooperative. | Remove from release claims. |
| DOC-CLAIM-034 | BROKEN | `architecture.md:2067` | `CortexMM and DharmaNet enforce hard budgets ... enforced by the kernel's scheduling` | Current code has no scheduler enforcement path; DharmaNet logs severity only. | Implement MCS/scheduler enforcement and runtime tests before claiming. |
| DOC-CLAIM-035 | BROKEN | `architecture.md:2070` | `data integrity is cryptographically verifiable` | Runtime CodexFS is not cryptographic. | Implement real crypto or downgrade. |
| DOC-CLAIM-036 | NOT PROVEN | `architecture.md:2124-2128` | `kernel-enforced`; `cryptographic integrity`; `guaranteed non-starvation` | Current evidence does not prove storage crypto or non-starvation. | Remove from release claims or produce proofs/tests. |
| DOC-CLAIM-037 | NOT PROVEN | `architecture.md:2252-2256` | `Cryptographic storage integrity ... Present`; `Self-healing autonomic reflexes ... Present` | Current repo only supports cooperative recovery and non-crypto CodexFS demo. | Replace with current status. |
| DOC-CLAIM-038 | NOT PROVEN | `architecture.md:2430-2582` | `Cryptographic Storage Integrity`; `cryptographically tamper-evident` | Roadmap text can stay as future, but not current release evidence. | Label explicitly as future phase. |

## Release Claim Freeze

The following phrases are frozen for release use until fixed or proven:

- "VERSE OS is formally verified" beyond the seL4 dependency.
- "formally proven" for VERSE user-space components.
- "self-healing" without the word "cooperative" and the exact TestWorker acceptance test.
- "scheduler enforcement" for DharmaNet.
- "TCB restart", "kernel restart", or "fresh process replacement".
- "cryptographic CodexFS" or "cryptographic storage integrity".
- "production-ready", "hardened", "impossible", or "guaranteed" for current implementation behavior.

