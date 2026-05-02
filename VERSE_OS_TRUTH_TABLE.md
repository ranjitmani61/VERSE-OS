# VERSE_OS_TRUTH_TABLE

Date: 2026-05-02

No implementation code was patched for this truth-layer pass. Files added by this pass: `CLAIM_AUDIT.md`, `RECOVERY_TLA_STATUS.md`, `RUNTIME_RECOVERY_EVIDENCE.md`, `CODEXFS_STATUS.md`, `BUILD_STATUS.md`, and this file.

## 1. Executive truth verdict

The repo currently contains a buildable seL4/CAmkES prototype. The active build path is `./build.sh verse_unified`, which copies `src/apps/verse_unified` into the CAmkES Docker tree and builds successfully.

Runtime logs prove cooperative recovery for the TestWorker deadlock scenario: TestWorker starts, Watchdog detects heartbeat loss, ProcMan signals restart through a shared flag, TestWorker voluntarily reinitializes, Watchdog re-arms, and the worker enters a continuous second run.

The repo does not currently prove TCB restart, fresh process replacement, non-cooperative crash recovery, scheduler enforcement, cryptographic CodexFS, persistent CodexFS, or full-system formal verification. CodexFS v19.5 is broken under TLC. Recovery liveness is broken under TLC when explicitly checked.

## 2. Evidence ID table

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| BUILD-001 | PASS | `build.sh:7-17` | `cp -a /host/src/apps/$APP`; `-DCAMKES_APP=$APP`; `echo BUILD_OK:$APP` | Canonical build source is `src/apps/$APP`. | Keep release builds on canonical tree. |
| BUILD-002 | PASS | Command: `./build.sh verse_unified` | `[357/357] Generating images/capdl-loader-image-x86_64-pc99`; `BUILD_OK:verse_unified` | Unified app builds and image is generated inside Docker. | Save full build logs in release artifacts. |
| BUILD-003 | PARTIAL | Command: `./build.sh verse_unified` | `/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions` | Build is not warning-clean; hardened status is not proven. | Explain or fix RWX segment. |
| RUN-001 | PASS | `run_logs/verse_unified_demo_fixed_20260502_102117.log:455-467` | `Booting all finished, dropped to user space`; `CODEX: ok`; `WRITER: done`; `READER: ok` | Runtime smoke path works. | Keep as smoke evidence. |
| RUN-002 | PASS | `run_logs/verse_unified_demo_fixed_20260502_102117.log:469-479` | `DEADLOCK SIMULATION`; `heartbeat lost`; `restart attempt 1/3`; `Reinitialising`; `re-armed`; `second run complete` | Cooperative recovery works for this scenario. | Add repeated and non-cooperative failure tests. |
| RUN-003 | NOT PROVEN | Command: `rg -n "seL4_TCB|fresh TestWorker|TCB_Suspend|TCB_Resume|TCB restart|fresh.*TCB" run_logs/verse_unified_demo_fixed_20260502_102117.log` | No output. | No runtime evidence of TCB restart or fresh process replacement. | Native TCB recovery boot log required. |
| SRC-WDOG-001 | PASS | `src/apps/verse_unified/components/Watchdog/src/watchdog.c:19-30` | `setting kill flag`; `*kflag = 1`; `heartbeat resumed, re-armed and monitoring` | Source matches Watchdog runtime behavior. | Add tests for repeated faults. |
| SRC-PROCMAN-001 | PASS | `src/apps/verse_unified/components/ProcMan/src/procman.c:76-93` | `cooperative_restart`; `*rf = 1`; `restart flag acknowledged` | Default recovery is cooperative restart signaling. | Do not call this TCB restart. |
| SRC-PROCMAN-002 | NOT PROVEN | `src/apps/verse_unified/components/ProcMan/src/procman.c:96-132` | `#ifdef VERSE_TCB_ENFORCED`; `STUB`; `current Docker CAmkES build does not provide these caps` | TCB path is not runtime-proven. | Build native capDL path and boot it. |
| SRC-PROCMAN-003 | NOT PROVEN | Command: `rg -n "VERSE_TCB_ENFORCED|add_compile|target_compile|compile_definitions" src/apps/verse_unified/CMakeLists.txt src/apps/verse_unified/components/*/CMakeLists.txt` | No output. | Default build does not enable TCB path. | Add explicit native target if intended. |
| SRC-TWORKER-001 | PASS | `src/apps/verse_unified/components/TestWorker/src/testworker.c:11-17` | `while (*rf == 0)`; `restart flag seen! Reinitialising...` | Worker must voluntarily read restart flag. | Non-cooperative worker recovery remains unproven. |
| SRC-CODEX-001 | BROKEN | `src/apps/verse_unified/components/CodexFS/src/codexfs.c:5,14,15` | `static unsigned char cs`; `s^=d[i]`; `b->h=cs(...)` | Runtime CodexFS is not cryptographic. | Implement real crypto or downgrade claim. |
| SRC-CODEX-002 | NOT PROVEN | Source grep for crypto/CAS/persistence terms | No SHA/crypto/CAS/snapshot/persistence implementation found. | Runtime does not match v19.5 model. | Align runtime/model. |
| TLA-RECOVERY-001 | PASS | Recovery inventory command | `./src/specs/Recovery_Task.tla`; `./src/specs/Recovery_Task.cfg` | Only one recovery spec/cfg pair found. | Add or remove RecoveryLoop references. |
| TLA-RECOVERY-002 | PARTIAL | `src/specs/Recovery_Task.cfg:8-10` | `INVARIANT TypeOK`; `CONSTRAINT StateConstraint`; `CHECK_DEADLOCK FALSE` | Committed cfg hides deadlocks and checks no liveness. | Add separate explicit cfgs. |
| TLA-RECOVERY-003 | PASS | Default Recovery TLC command | `Model checking completed. No error`; `108 states generated, 73 distinct states found` | TypeOK passes under committed cfg only. | Do not claim recovery liveness. |
| TLA-RECOVERY-004 | BROKEN | Recovery deadlock-on TLC command | `Error: Deadlock reached`; final state `worker_state = "DEAD"`; `restart_count = 1` | Deadlock exists after restart budget is consumed. | Model terminal state or fix recovery actions. |
| TLA-RECOVERY-005 | FAIL | Recovery liveness TLC command | `Warning: Declaring state or action constraints during liveness checking is dangerous`; `Error: Temporal properties were violated`; `State 4: Stuttering` | CooperativeRecovery liveness is not proven. | Fix liveness model. |
| TLA-CODEX-001 | PASS | CodexFS inventory command | Top-level pair: `CodexFS_Monotonic_v19_5.tla`; `CodexFS_Monotonic_v19_5.cfg` | Canonical candidate identified. | Make docs match after passing. |
| TLA-CODEX-002 | PARTIAL | `CodexFS_Monotonic_v19_5.cfg:8-13` | `INVARIANTS TypeOK`; `PROPERTIES DetectionLiveness EventualLiveness` | Safety beyond TypeOK is not configured by name. | Add explicit safety invariants. |
| TLA-CODEX-003 | BROKEN | CodexFS deadlock-on TLC command | `Error: Deadlock reached`; `258 states generated, 192 distinct states found` | Canonical CodexFS fails with normal deadlock checking. | Fix deadlock or model finite halt. |
| TLA-CODEX-004 | FAIL | CodexFS `-deadlock` TLC command | `Error: Temporal properties were violated`; `State 6: Stuttering`; `3826 states generated, 2764 distinct states found` | Liveness fails even with deadlock checking disabled. | Repair temporal properties/fairness/bounds. |
| DOC-CLAIM-001 | PARTIAL | `real-architecture.md:3` | `formally verified, self-healing` | Overbroad release wording. | Scope to seL4 and cooperative recovery. |
| DOC-CLAIM-008 | BROKEN | `real-architecture.md:110`; `SRC-CODEX-001` | `Cryptographic Append-Only Integrity Store` | Not true for current runtime. | Remove or implement crypto. |
| DOC-CLAIM-034 | BROKEN | `architecture.md:2067` | `DharmaNet enforce hard budgets ... kernel's scheduling` | No scheduler enforcement implementation observed. | Implement MCS/scheduler enforcement and test. |
| GAP-001 | NOT PROVEN | RUN-003, SRC-PROCMAN-002, SRC-PROCMAN-003 | No TCB runtime logs and guarded stub source. | TCB restart not proven. | Native TCB acceptance test. |
| GAP-002 | NOT PROVEN | SRC-CODEX-001, SRC-CODEX-002 | XOR checksum only. | Cryptographic CodexFS not proven. | Real hash/root of trust. |
| GAP-003 | FAIL | TLA-RECOVERY-005 | Temporal violation. | Recovery liveness not proven. | Fix TLA model. |
| GAP-004 | BROKEN | TLA-CODEX-003, TLA-CODEX-004 | Deadlock and temporal violation. | CodexFS canonical model broken. | Fix v19.5. |
| GAP-005 | PARTIAL | BUILD-003 | RWX LOAD segment warning. | Hardened build not proven. | Explain/fix segment permissions. |

## 3. What is proven

| ID | Claim | Status |
|---|---|---|
| BUILD-002 | `./build.sh verse_unified` builds the unified app and generates the CAmkES image. | PASS |
| RUN-001 | The reviewed runtime log reaches seL4 userspace and executes smoke paths. | PASS |
| RUN-002 | Cooperative recovery after TestWorker deadlock is observed. | PASS |
| TLA-RECOVERY-003 | Recovery `TypeOK` passes under the committed cfg. | PASS, but deadlock disabled |

## 4. What is partial

| ID | Claim | Status |
|---|---|---|
| BUILD-003 | Build is successful but has RWX warning. | PARTIAL |
| SRC-PROCMAN-001 | ProcMan recovery works as cooperative flag signaling. | PARTIAL relative to self-healing/TCB claims |
| TLA-CODEX-002 | CodexFS cfg checks TypeOK plus temporal properties. | PARTIAL, not full safety |
| DOC-CLAIM-005 | "self-healing" wording. | PARTIAL only for cooperative TestWorker path |

## 5. What is broken

| ID | Claim | Status |
|---|---|---|
| TLA-CODEX-003 | CodexFS v19.5 deadlock freedom. | BROKEN |
| TLA-CODEX-004 | CodexFS v19.5 liveness with deadlock disabled. | FAIL |
| TLA-RECOVERY-004 | Recovery deadlock behavior. | BROKEN |
| TLA-RECOVERY-005 | Cooperative recovery liveness. | FAIL |
| DOC-CLAIM-008 | Cryptographic CodexFS runtime claim. | BROKEN |
| DOC-CLAIM-034 | Scheduler enforcement claim. | BROKEN |

## 6. What is not proven

| ID | Claim | Status |
|---|---|---|
| RUN-003 | TCB restart. | NOT PROVEN |
| RUN-003 | Fresh process replacement. | NOT PROVEN |
| SRC-TWORKER-001 | Non-cooperative worker recovery. | NOT PROVEN |
| SRC-CODEX-002 | Persistence, SHA/crypto, snapshot/CAS runtime behavior. | NOT PROVEN |
| DOC-CLAIM-004 | Combined runtime adversarial survival. | NOT PROVEN |
| DOC-CLAIM-012 | Null dereference recovery. | NOT PROVEN |

## 7. Exact next fixes in priority order

| ID | Priority | Fix |
|---|---|---|
| FIX-001 | P0 | Freeze or edit docs to remove overbroad verified/proven/self-healing/secure/scheduler/cryptographic/guaranteed claims. Use `CLAIM_AUDIT.md` as the gate. |
| FIX-002 | P1 | Repair `src/specs/Recovery_Task.tla` so TypeOK, deadlock behavior, and `CooperativeRecovery` liveness are checked in separate meaningful cfgs. |
| FIX-003 | P2 | Repair `CodexFS_Monotonic_v19_5.tla` or designate another canonical spec only after a passing TLC run. |
| FIX-004 | P3 | Align runtime CodexFS source with the model or downgrade runtime docs to in-memory XOR checksum demo. |
| FIX-005 | P4 | Add native TCB restart acceptance test only after capDL handoff and ProcMan TCB caps are actually booted. |
| FIX-006 | P5 | Investigate `/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions` before any hardened-build claim. |

## 8. Commands to reproduce every result

Build:

```bash
./build.sh verse_unified
```

Runtime log review:

```bash
nl -ba run_logs/verse_unified_demo_fixed_20260502_102117.log | sed -n '452,482p'
rg -n "seL4_TCB|fresh TestWorker|TCB_Suspend|TCB_Resume|TCB restart|fresh.*TCB" run_logs/verse_unified_demo_fixed_20260502_102117.log
```

Recovery inventory and TLC:

```bash
find . -path './.git' -prune -o \( -iname '*Recovery*.tla' -o -iname '*Recovery*.cfg' -o -iname '*RecoveryLoop*.tla' -o -iname '*RecoveryLoop*.cfg' \) -print
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_truth_recovery_default src/specs/Recovery_Task.tla -config src/specs/Recovery_Task.cfg
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_truth_recovery_deadlock_on src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_deadlock_on_truth.cfg
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_truth_recovery_liveness src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_liveness_truth.cfg
```

CodexFS inventory and TLC:

```bash
find . -path './.git' -prune -o \( -iname '*CodexFS*.tla' -o -iname '*CodexFS*.cfg' \) -print | sort
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_truth_codex_v19_5_deadlock_on CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_truth_codex_v19_5_deadlock_off CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
```

Source checks:

```bash
nl -ba src/apps/verse_unified/components/CodexFS/src/codexfs.c
rg -n "SHA|sha|crypto|hash|cs\(|checksum|CAS|snapshot|ver|persistent|TPM|ROM" src/apps/verse_unified/components/CodexFS/src/codexfs.c src/apps/verse_unified/components/ReadClient/src/readclient.c src/apps/verse_unified/components/WriteClient/src/writeclient.c
nl -ba src/apps/verse_unified/components/ProcMan/src/procman.c | sed -n '1,285p'
rg -n "VERSE_TCB_ENFORCED|add_compile|target_compile|compile_definitions" src/apps/verse_unified/CMakeLists.txt src/apps/verse_unified/components/*/CMakeLists.txt
```

Claim scan:

```bash
rg -n -i "formally verified|proven|self-healing|secure|hardened|scheduler enforcement|TCB restart|cryptographic|impossible|guaranteed|production-ready|production ready" VERSE_OS_VERIFICATION_REPORT.md real-architecture.md architecture.md SUPPORT_STATUS.md FORMAL_METHODS_REPORT.md THREAT_MODEL.md RECOVERY_MANIFEST.md NATIVE_SEL4_TCB_SETUP.md CAPDL_INTEGRATION.md MNEMOSYNE_RECONCILIATION.md
```

## 9. No marketing language

Release wording must stay limited to the evidence above. Terms frozen until supported by current evidence: formally verified, formally proven, self-healing without cooperative qualifier, secure, hardened, scheduler enforcement, TCB restart, cryptographic CodexFS, impossible, guaranteed, production-ready.
