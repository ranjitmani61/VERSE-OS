# VERSE OS Verification Report

Date: 2026-05-02
Repository: `/home/king/verse_os`
Role: senior OS verification engineer / build and release auditor

No implementation files were patched during this pass. Temporary TLC config files were created under `/tmp` for diagnostics. The first failed parallel TLC attempt created `states/26-05-02-11-18-34/` in the repo.

## 1. Executive verdict

The current repository contains a buildable and bootable seL4/CAmkES prototype. The canonical wrapper `./build.sh verse_unified` builds the active app from `src/apps/verse_unified`, and a Docker/QEMU run reaches userspace, starts the VERSE components, exercises Sentinel, CortexMM, CodexFS writer/reader, DharmaNet, Watchdog, ProcMan, and TestWorker, and demonstrates a cooperative recovery loop after a simulated TestWorker deadlock.

The current repository does not prove the stronger claims present in some docs. There is no runtime-proven scheduler enforcement, no runtime-proven seL4 TCB restart, no forced non-cooperative recovery, no cryptographic CodexFS runtime implementation, and no full-system formal proof. CodexFS v19.5, the only top-level CodexFS spec with a matching top-level cfg, fails TLC. Recovery liveness is not proven; when explicitly checked, `CooperativeRecovery` fails.

Classification:

| Bucket | Finding |
|---|---|
| IMPLEMENTED | CAmkES component graph, in-memory demo components, LogRing, Sentinel forward path, CortexMM dataport write, CodexFS in-memory RPC demo, DharmaNet counter monitor, Watchdog heartbeat monitor, ProcMan cooperative restart flag, TestWorker simulated deadlock/reinit path. |
| MODEL-CHECKED | Sentinel safety passes with deadlock checking disabled; CortexMM safety passes but is structurally weak; DharmaNet budget flagging passes but is detection-only; CodexFS v12 passes only with deadlock disabled; Recovery TypeOK passes only because cfg disables deadlock. |
| RUNTIME-TESTED | Build, userspace boot, component startup, Sentinel forward, CodexFS write/read verify, DharmaNet OK/WARN logs, Watchdog detection, ProcMan action, TestWorker cooperative reinitialization, Watchdog re-arm. |
| PARTIAL / MOCK | CortexMM allocator, CodexFS storage/integrity, DharmaNet enforcement, ProcMan TCB restart path, Mnemosyne, capability audit/chaos harnesses. |
| BROKEN | CodexFS v19.5 TLC: deadlock with normal deadlock checking; temporal property violation with `-deadlock`. Recovery liveness fails when checked. Docs refer to missing `CodexFS.tla` and `CodexFS.cfg`. |
| FUTURE WORK | Native capDL/TCB handoff, fresh TCB construction, real scheduler contexts/MCS enforcement, persistent storage, cryptographic hashes/root of trust, SMP model, full recovery liveness model, doc correction. |

## 2. What works with proof

### Repository inventory

Canonical build source is `src/apps/$APP`, proven by:

Command:

```bash
sed -n '1,220p' build.sh
```

Observed output:

```text
APP="${1:-verse_unified}"
...
cp -a /host/src/apps/$APP /tmp/camkes/projects/camkes/apps/$APP
...
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=$APP
ninja
echo BUILD_OK:$APP
```

Active unified CAmkES assembly:

Command:

```bash
nl -ba src/apps/verse_unified/verse_unified.camkes
```

Observed output:

```text
17 assembly {
18     composition {
19         component LogRing logring;
20         component Sentinel sentinel;
21         component Hello hello;
22         component Client client;
23         component CortexMM cortexmm;
24         component MemClient memclient;
25         component WorkerA worker_a;
26         component WorkerB worker_b;
27         component DharmaNet dharmanet;
28         component CodexFS codexfs;
29         component WriteClient writeclient;
30         component ReadClient readclient;
31         component TestWorker testworker;
32         component Watchdog watchdog;
33         component ProcMan procman;
...
56         connection seL4SharedData hb(from testworker.heartbeat, to watchdog.heartbeat);
57         connection seL4SharedData kf(from watchdog.kill_flag, to procman.kill_flag);
58         connection seL4SharedData rf(from procman.restart_flag, to testworker.restart_flag);
59         connection seL4SharedData sev(from dharmanet.severity_buf, to procman.severity_buf);
```

Major components:

| Component | Source paths | Status |
|---|---|---|
| Sentinel | `src/apps/verse_unified/components/Sentinel/src/sentinel.c`; `src/apps/verse_unified/components/Sentinel/Sentinel.camkes`; `src/apps/sentinel_negtest/` | PARTIAL / MOCK. Real CAmkES RPC interposer for the demo, but labels are compile-time constants `LC=0`, `LS=2`; unified runtime only observed forward path. |
| CortexMM | `src/apps/verse_unified/components/CortexMM/src/cortexmm.c`; `src/apps/cortexmm_demo/` | PARTIAL / MOCK. Writes `"CORTEX: ready"` to a dataport. No real allocator, untyped retype, or dynamic cap grant. |
| DharmaNet | `src/apps/verse_unified/components/DharmaNet/src/dharmanet.c`; `src/apps/dharmanet_severity/` | PARTIAL. Real counter monitor and severity flag, but no scheduler enforcement. |
| CodexFS | `src/apps/verse_unified/components/CodexFS/src/codexfs.c`; `src/apps/codexfs_demo/` | PARTIAL / MOCK. In-memory append/verify service with XOR checksum; not cryptographic, not persistent, no CAS/version snapshot pipeline from v19.5 model. |
| Watchdog | `src/apps/verse_unified/components/Watchdog/src/watchdog.c`; `src/apps/persistent_watchdog/`; `src/apps/watchdog_tcb/` | IMPLEMENTED for heartbeat polling and cooperative re-arm. No kernel fault endpoint proof. |
| ProcMan | `src/apps/verse_unified/components/ProcMan/src/procman.c`; `src/capdl/verse_tcb_handoff.cdl` | PARTIAL. Cooperative restart works. TCB enforced path is guarded by `#ifdef VERSE_TCB_ENFORCED` and not enabled by CMake. |
| TestWorker / CrashWorker | `src/apps/verse_unified/components/TestWorker/src/testworker.c`; no `CrashWorker` source found | TestWorker IMPLEMENTED as deadlock simulation plus cooperative reinit. CrashWorker MISSING. |
| LogRing | `src/apps/verse_unified/components/LogRing/src/logring.c` | IMPLEMENTED as simple shared ring printer. No synchronization proof. |
| Mnemosyne | `src/apps/verse_unified/components/Mnemosyne/src/mnemosyne.c` | PARTIAL / MOCK. Scaffold only; not instantiated in `src/apps/verse_unified/verse_unified.camkes`. |
| TLA+ specs | `src/specs/*.tla`; top-level `CodexFS_Monotonic_v19_5.tla`; recovered archive `src/specs/codexfs_monotonic_recovered/` | Mixed. Some small safety specs pass; CodexFS v19.5 and Recovery liveness fail. |
| CAmkES assemblies | `src/apps/verse_unified/verse_unified.camkes`, `src/apps/persistent_watchdog/persistent_watchdog.camkes`, `src/apps/watchdog_tcb/watchdog_tcb.camkes`, `src/apps/codexfs_demo/codexfs_demo.camkes`, `src/apps/cortexmm_demo/cortexmm_demo.camkes`, `src/apps/dharmanet_severity/dharmanet_severity.camkes`, `src/apps/sentinel_negtest/sentinel_negtest.camkes` | Real CAmkES app declarations. Only `verse_unified` was built and runtime-tested in this pass. |

Component source evidence:

Command:

```bash
nl -ba src/apps/verse_unified/components/TestWorker/src/testworker.c
```

Observed output:

```text
9     printf("TestWorker: started\n");
10    for (int i=1; i<=5; i++) { *hb = i; for (volatile int d=0; d<10000000; d++); }
11    printf("TestWorker: DEADLOCK SIMULATION\n");
12    while (*rf == 0) { for (volatile int d=0; d<1000000; d++); }
13    printf("TestWorker: restart flag seen! Reinitialising...\n");
...
17    printf("TestWorker: second run complete, entering continuous loop\n");
```

Command:

```bash
nl -ba src/apps/verse_unified/components/Watchdog/src/watchdog.c
```

Observed output:

```text
4  #define HEARTBEAT_MISS_LIMIT 50
...
20 printf("WDOG: heartbeat lost after %d polls, setting kill flag\n", fc);
21 *kflag = 1;
...
27 printf("WDOG: waiting for recovery heartbeat...\n");
28 while (*hb == last) { for (volatile int d=0; d<1000000; d++); }
29 *kflag = 0;
30 printf("WDOG: heartbeat resumed, re-armed and monitoring\n");
```

Command:

```bash
nl -ba src/apps/verse_unified/components/ProcMan/src/procman.c
```

Observed output:

```text
76  static int cooperative_restart(volatile int *rf, volatile int *kflag)
79      *rf = 1;
82              printf("ProcMan: restart flag acknowledged\n");
...
96  #ifdef VERSE_TCB_ENFORCED
97  static void fault_endpoint_handler_stub(void)
100     // STUB: requires native seL4 build environment with ProcMan receiving
...
109     int err = seL4_TCB_Suspend(worker_tcb);
...
130      * STUB: requires native seL4 build environment. The syscall sequence is
131      * real, but the current Docker CAmkES build does not provide these caps or
132      * the worker entry/stack addresses.
...
257 #ifdef VERSE_TCB_ENFORCED
```

Command:

```bash
rg -n "add_compile|target_compile|C_FLAGS|VERSE_TCB_ENFORCED" src/apps/verse_unified/CMakeLists.txt src/apps/verse_unified/components/*/CMakeLists.txt
```

Observed output: no matches. Therefore `VERSE_TCB_ENFORCED` is not enabled in the default app build.

### Capability graph audit

Command:

```bash
python3 tools/capability_audit.py src/apps/verse_unified/verse_unified.camkes
```

Observed output:

```text
audited src/apps/verse_unified/verse_unified.camkes: 26 connection declarations
...
rf: seL4SharedData procman.restart_flag -> testworker.restart_flag
sev: seL4SharedData dharmanet.severity_buf -> procman.severity_buf

CAPABILITY_AUDIT_OK
```

Command:

```bash
python3 src/tools/audit_caps.py src/apps/verse_unified
```

Observed output:

```text
APP verse_unified
ASSEMBLY src/apps/verse_unified/verse_unified.camkes
COMPONENTS 15
...
CONNECTIONS 26
...
AUDIT_OK
```

Limit: these are static parsers for declared CAmkES edges. They are not capDL proof, kernel authority proof, or runtime capability-use proof.

## 3. What is model-checked with proof

### Sentinel

Spec and cfg:

```text
src/specs/Sentinel_Lattice.tla
src/specs/Sentinel_Lattice.cfg
```

Cfg evidence:

```text
CONSTANTS MaxMsgs = 4
SPECIFICATION Spec
INVARIANT NoIllegalDelivery
```

Default deadlock checking fails:

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_sentinel_deadlock_on_escalated src/specs/Sentinel_Lattice.tla -config src/specs/Sentinel_Lattice.cfg
```

Observed output:

```text
Error: Deadlock reached.
...
38629 states generated, 21179 distinct states found, 1554 states left on queue.
The depth of the complete state graph search is 9.
```

With finite-model deadlock checking disabled, safety passes:

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_sentinel_deadlock_off_escalated src/specs/Sentinel_Lattice.tla -config src/specs/Sentinel_Lattice.cfg
```

Observed output:

```text
Model checking completed. No error has been found.
38629 states generated, 21179 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
```

Meaningfulness: useful scoped safety model. Weakness: runtime unified Sentinel has hard-coded labels and runtime only observed `S: FORWARD`; no unified-runtime `S: BLOCK` was observed in this pass.

### CortexMM

Spec and cfg:

```text
src/specs/CortexMM_Capability.tla
src/specs/CortexMM_Capability.cfg
```

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_cortex_escalated src/specs/CortexMM_Capability.tla -config src/specs/CortexMM_Capability.cfg
```

Observed output:

```text
Model checking completed. No error has been found.
541 states generated, 81 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
```

Meaningfulness: weak. The `Access(c,p)` action is enabled only when `p \in granted[c]`, so illegal access is not modeled as an adversary action that can be attempted and rejected. Runtime CortexMM is only a dataport string write, not a memory manager.

### DharmaNet

Spec and cfg:

```text
src/specs/DharmaNet_Budget.tla
src/specs/DharmaNet_Budget.cfg
```

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_dharma_escalated src/specs/DharmaNet_Budget.tla -config src/specs/DharmaNet_Budget.cfg
```

Observed output:

```text
Model checking completed. No error has been found.
28562 states generated, 169 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 2.
```

Meaningfulness: weak detection property. The model sets `severity = CRIT` in the same `Observe` action when over budget; it does not model scheduler enforcement or resource throttling.

### CodexFS

Current runnable top-level pair found:

```text
CodexFS_Monotonic_v19_5.tla
CodexFS_Monotonic_v19_5.cfg
```

Cfg evidence:

```text
CONSTANTS
    MaxUserOps = 3
    MaxSysOps  = 16
    HashMax    = 2

SPECIFICATION Spec

INVARIANTS
    TypeOK

PROPERTIES
    DetectionLiveness
    EventualLiveness
```

Repo doc command is stale:

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_doc_missing CodexFS.tla -config CodexFS.cfg
```

Observed output:

```text
TLC encountered the following error when trying to read the configuration file CodexFS.cfg:
File not found.
```

v19.5 with normal deadlock checking:

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_codex_v19_5_deadlock_on_escalated CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
```

Observed output:

```text
Error: Deadlock reached.
...
258 states generated, 192 distinct states found, 85 states left on queue.
The depth of the complete state graph search is 6.
```

v19.5 with deadlock checking disabled:

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_codex_v19_5_deadlock_off_escalated CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
```

Observed output:

```text
Progress(20) at 2026-05-02 11:19:14: 3,826 states generated, 2,764 distinct states found, 0 states left on queue.
Checking 2 branches of temporal properties for the complete state space with 5528 total distinct states
Error: Temporal properties were violated.
...
3826 states generated, 2764 distinct states found, 0 states left on queue.
```

Result: BROKEN. v19.5 is not model-checked successfully.

Older v12:

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_codex_v12_escalated src/specs/CodexFS_Monotonic_v12.tla -config src/specs/CodexFS_Monotonic_v12.cfg
```

Observed output:

```text
Error: Deadlock reached.
...
778 states generated, 487 distinct states found, 143 states left on queue.
The depth of the complete state graph search is 8.
```

With `-deadlock`:

```text
Model checking completed. No error has been found.
1600 states generated, 991 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 11.
```

Meaningfulness: v12 safety checks are scoped and bounded, and pass only when deadlock is ignored. They do not rescue the current top-level v19.5 failure.

### Recovery

Found recovery specs:

```text
src/specs/Recovery_Task.tla
src/specs/Recovery_Task.cfg
```

No `RecoveryLoop.tla` was found.

Committed cfg:

```text
SPECIFICATION Spec
CONSTANTS
    MaxMisses = 2
    MaxRestarts = 1
    TCBMaxMisses = 2
    TCBMaxRestarts = 1

INVARIANT TypeOK
CONSTRAINT StateConstraint
CHECK_DEADLOCK FALSE
```

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_cfg_escalated src/specs/Recovery_Task.tla -config src/specs/Recovery_Task.cfg
```

Observed output:

```text
Model checking completed. No error has been found.
108 states generated, 73 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 16.
```

This only proves the configured `TypeOK` invariant under a state constraint and with deadlock checking disabled.

Deadlock restored using temporary `/tmp/Recovery_Task_deadlock_on.cfg`:

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_deadlock_on_escalated src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_deadlock_on.cfg
```

Observed output:

```text
Error: Deadlock reached.
...
State 13: <WatchdogDetect line 95, col 5 to line 100, col 84 of module Recovery_Task>
/\ restart_count = 1
/\ watchdog_state = "DETECTED"
/\ missed_polls = 2
/\ worker_state = "DEAD"
...
105 states generated, 70 distinct states found, 2 states left on queue.
The depth of the complete state graph search is 14.
```

Liveness enabled using temporary `/tmp/Recovery_Task_liveness.cfg`:

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_liveness_escalated src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_liveness.cfg
```

Observed output:

```text
Warning: Declaring state or action constraints during liveness checking is dangerous
...
Error: Temporal properties were violated.
...
State 8: Stuttering
...
108 states generated, 73 distinct states found, 0 states left on queue.
```

Result: recovery liveness is NOT PROVEN. It fails when checked. The current cfg does not check `CooperativeRecovery`.

TCB refinement model status:

`src/specs/Recovery_Task.tla` contains a nested `Recovery_TCB` module, but no runnable `Recovery_TCB.tla` file or cfg was found. Direct TLC attempts failed:

```text
Cannot find source file for module Recovery_TCB.
Cannot find source file for module Recovery_Task!Recovery_TCB.
```

Therefore TCB recovery is NOT PROVEN.

## 4. What is runtime-tested with proof

### Build verification

Canonical build command:

```bash
./build.sh verse_unified
```

Observed result:

```text
[357/357] Generating images/capdl-loader-image-x86_64-pc99
BUILD_OK:verse_unified
```

Generated image path observed inside the Docker container:

```text
/tmp/camkes/build_verse_unified/images/capdl-loader-image-x86_64-pc99
```

Relevant warning:

```text
/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
```

The container uses `--rm`, so the image path is not persisted on the host after command exit.

### Runtime verification

Runtime command:

```bash
timeout 180s docker run --rm -v /home/king/verse_os:/host user_img-king bash -lc '
set -e
rm -rf /tmp/camkes/projects/camkes/apps/verse_unified
rm -rf /tmp/camkes/build_verse_unified_runtime
cp -a /host/src/apps/verse_unified /tmp/camkes/projects/camkes/apps/verse_unified
cd /tmp/camkes
mkdir build_verse_unified_runtime
cd build_verse_unified_runtime
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified
ninja
echo BUILD_OK_RUNTIME:verse_unified
echo IMAGE_PATH:/tmp/camkes/build_verse_unified_runtime/images/capdl-loader-image-x86_64-pc99
timeout 70s ./simulate
'
```

Observed build/runtime output:

```text
BUILD_OK_RUNTIME:verse_unified
IMAGE_PATH:/tmp/camkes/build_verse_unified_runtime/images/capdl-loader-image-x86_64-pc99
./simulate: QEMU command: qemu-system-x86_64 ... -kernel images/kernel-x86_64-pc99 -initrd images/capdl-loader-image-x86_64-pc99
...
Booting all finished, dropped to user space
TestWorker: started
ProcMan: waiting
WDOG: active monitoring
DHARMA: strict hysteresis + escalation
CORTEX: ok
CLIENT: call
CODEX: ok
S: FORWARD
HELLO: ok
CLIENT: done
WRITER: done
READER: ok
TestWorker: DEADLOCK SIMULATION
DHARMA: OK (52%)
DHARMA: WARN (58%)
WDOG: heartbeat lost after 50 polls, setting kill flag
WDOG: waiting for recovery heartbeat...
ProcMan: restart attempt 1/3
TestWorker: restart flag seen! Reinitialising...
ProcMan: restart flag acknowledged
WDOG: heartbeat resumed, re-armed and monitoring
ProcMan: restart done
TestWorker: second run complete, entering continuous loop
...
qemu-system-x86_64: terminating on signal 15 from pid 1 (timeout)
```

Exit status: 124 from the configured timeout. This is expected for the demo loop and is not evidence of kernel crash.

Runtime event checklist:

| Event | Status | Evidence |
|---|---|---|
| seL4 boots to userspace | PASS | `Booting all finished, dropped to user space` |
| CORTEX starts | PASS | `CORTEX: ok` |
| CODEX starts | PASS | `CODEX: ok` |
| Sentinel path executes | PASS | `CLIENT: call`, `S: FORWARD`, `HELLO: ok`, `CLIENT: done` |
| Writer/Reader path executes | PASS | `WRITER: done`, `READER: ok` |
| DharmaNet logs status | PASS for status logging; NOT PROVEN for enforcement | `DHARMA: OK`, `DHARMA: WARN`; no scheduler actuation observed |
| Watchdog starts | PASS | `WDOG: active monitoring` |
| TestWorker failure occurs | PASS | `TestWorker: DEADLOCK SIMULATION` |
| CrashWorker failure occurs | NOT OBSERVED | No CrashWorker source found |
| Watchdog detects heartbeat loss | PASS | `WDOG: heartbeat lost after 50 polls` |
| ProcMan acts | PASS | `ProcMan: restart attempt 1/3`, `ProcMan: restart flag acknowledged`, `ProcMan: restart done` |
| Worker reinitializes/restarts | PASS for cooperative same-worker reinit | `TestWorker: restart flag seen! Reinitialising...`, `second run complete` |
| Watchdog re-arms | PASS | `WDOG: heartbeat resumed, re-armed and monitoring` |
| seL4 TCB restart | FAIL / NOT OBSERVED | No `seL4_TCB_Suspend(worker_tcb) OK`, no fresh TCB logs |

## 5. What is partial/mock

| Area | Evidence | Why partial/mock |
|---|---|---|
| Sentinel | `src/apps/verse_unified/components/Sentinel/src/sentinel.c`: `#define LC 0`, `#define LS 2`; runtime only `S: FORWARD` | Hard-coded labels, no dynamic policy, no unified-runtime block observed. |
| CortexMM | `src/apps/verse_unified/components/CortexMM/src/cortexmm.c`: `strcpy((char*)page_allocatable,"CORTEX: ready")` | No allocator, no seL4 untyped/cap mint path. |
| DharmaNet | `src/apps/verse_unified/components/DharmaNet/src/dharmanet.c`: reads counters and writes `severity_buf` | Detection only. No `seL4_SchedControl_*` or runtime throttling. |
| CodexFS | `src/apps/verse_unified/components/CodexFS/src/codexfs.c`: `static unsigned char cs(...)` XOR checksum | Not cryptographic, no persistent backing store, no TPM/ROM root, no v19.5 snapshot/CAS pipeline. |
| ProcMan TCB path | `#ifdef VERSE_TCB_ENFORCED`; comments say STUB and missing caps | Default CMake does not enable it; no runtime TCB capability evidence. |
| Mnemosyne | `src/apps/verse_unified/components/Mnemosyne/src/mnemosyne.c`: `MNEMOSYNE: scaffold ready`; not in assembly | Scaffold only, not built into unified app. |
| Chaos Monkey | `tools/chaos_monkey.py` uses `ROOT / "verse_unified" / "verse_unified.camkes"` | It tests the root duplicate tree, not the canonical `src/apps/verse_unified`, unless changed. It is a static mutation harness, not runtime chaos. |

## 6. What is broken

1. CodexFS current top-level v19.5 is broken under TLC.
   - Deadlock enabled: `Error: Deadlock reached`, 258 generated / 192 distinct states.
   - Deadlock disabled: `Error: Temporal properties were violated`, 3826 generated / 2764 distinct states.

2. The documented CodexFS command is stale.
   - `real-architecture.md` lines 253-257 refer to `CodexFS.tla -config CodexFS.cfg`.
   - Command output: `File not found` for `CodexFS.cfg`.

3. Recovery liveness is broken / not proven.
   - Committed `Recovery_Task.cfg` checks only `TypeOK`.
   - When `PROPERTY CooperativeRecovery` is added in a temporary cfg, TLC reports temporal violation and stuttering.

4. Recovery cfg hides deadlock.
   - `src/specs/Recovery_Task.cfg` contains `CHECK_DEADLOCK FALSE`.
   - When deadlock checking is restored, TLC reaches a deadlock after the restart limit is consumed.

5. TCB restart is not built or runtime-proven.
   - Default ProcMan CMake has only `DeclareCAmkESComponent(ProcMan SOURCES src/procman.c)`.
   - No compile definition enables `VERSE_TCB_ENFORCED`.
   - Runtime logs show cooperative restart only.

6. Scheduler enforcement is not implemented.
   - Active runtime code has no scheduler-control syscall path.
   - DharmaNet logs severity; ProcMan can quarantine on CRIT, but no budget enforcement was observed.

7. CrashWorker is missing.
   - Search found TestWorker files only. No `CrashWorker` source or assembly exists.

## 7. What is overclaimed

Maintained docs with strong claims were searched using:

```bash
rg -n -i "verified|self-healing|formally proven|production|secure|kernel restart|scheduler enforcement|impossible|guaranteed" SUPPORT_STATUS.md FORMAL_METHODS_REPORT.md THREAT_MODEL.md NATIVE_SEL4_TCB_SETUP.md CAPDL_INTEGRATION.md RECOVERY_MANIFEST.md DOCKER_RECOVERY_MANIFEST.md MNEMOSYNE_RECONCILIATION.md real-architecture.md architecture.md
```

The chat transcripts (`chat*.md`, `discussion*.md`, `verseos.txt`) contain many additional strong phrases, but they are treated as conversation/archive text rather than current maintained claims. They should not be used as release claims.

| File:line | Quote | Classification | Required evidence to make true |
|---|---|---|---|
| `real-architecture.md:3` | `A capability-enforced, formally verified, self-healing microkernel operating system` | OVERCLAIM | Replace with scoped wording: seL4 kernel is formally verified; VERSE components are bounded model-checked or runtime-tested; recovery is cooperative. |
| `real-architecture.md:9` | `Each safety layer has been formally specified in TLA+ and model-checked with TLC under bounded parameters.` | OVERCLAIM | CodexFS v19.5 must pass TLC; Recovery liveness must pass if recovery is counted as a safety layer. |
| `real-architecture.md:9` | `survives combined memory corruption, RPC floods, and CPU exhaustion attacks` | UNKNOWN / NOT PROVEN THIS PASS | Runtime logs for those exact combined attacks against canonical `src/apps/verse_unified`, with commands and outputs. |
| `real-architecture.md:22` | `Self-healing: The system detects faults, signals for recovery, and reinitialises failed components without operator intervention.` | SUPPORTED only for cooperative TestWorker deadlock path | Keep "cooperative"; do not imply non-cooperative or TCB restart. |
| `real-architecture.md:62` | `Verified by TLC: 2 distinct states, zero violations.` | OVERCLAIM / STALE | Current Sentinel run: 21179 distinct states with `-deadlock`; default deadlocks. Update state counts. |
| `real-architecture.md:82` | `Verified by TLC: 18 distinct states, zero violations.` | OVERCLAIM / STALE | Current CortexMM run: 81 distinct states. Also flag weak model. |
| `real-architecture.md:86` | `Access to unwired dataport ... is compile-time impossible.` | PARTIAL SUPPORT | Build/capability audit evidence for current assembly plus negative build test showing unwired access fails. |
| `real-architecture.md:103` | `Verified by TLC: 4 distinct states, zero violations.` | OVERCLAIM / STALE | Current DharmaNet run: 169 distinct states. Also detection-only. |
| `real-architecture.md:106` | `DharmaNet reports OK/WARN/CRIT based on actual CPU counters.` | PARTIAL / OVERCLAIM | This run observed OK/WARN only, no CRIT. |
| `real-architecture.md:126` | `Verified by TLC: 624 distinct states, zero violations.` | OVERCLAIM | Current v19.5 fails; v12 only passes with deadlock disabled and has 991 distinct states. |
| `real-architecture.md:133-135` | `Manual byte corruption ... detected`; `Chaos Monkey ... CodexFS integrity unchanged` | UNKNOWN / NOT PROVEN THIS PASS | Runtime corruption command/log against canonical build. Static chaos monkey is not this evidence. |
| `real-architecture.md:146` | `All three components built and tested in the unified demo.` | SUPPORTED for Watchdog/ProcMan/TestWorker build and cooperative runtime | Add exact current build/runtime command output. |
| `real-architecture.md:154-159` | Formal summary table with `CodexFS.tla` and state counts | OVERCLAIM / STALE | Replace with current TLC outputs from this report. |
| `real-architecture.md:178` | `Runtime proves: ... the system returns to a productive state.` | OVERCLAIM wording | Runtime observes a cooperative recovery path. It does not prove all realistic fault injection. |
| `real-architecture.md:188` | `Null dereference ... seL4 traps fault; watchdog detects; ProcMan restarts` | NOT PROVEN THIS PASS | Runtime log of null dereference fault path and recovery. |
| `real-architecture.md:190-191` | `Chaos Monkey ... All 14 components survive`; `Stack overflow ...` | NOT PROVEN THIS PASS | Runtime chaos/stack-overflow commands and logs. |
| `real-architecture.md:212` | `CodexFS.tla ... canonical` | BROKEN / STALE | File not found under documented name. |
| `real-architecture.md:253-257` | TLC command for `CodexFS.tla -config CodexFS.cfg` | BROKEN | Add real canonical spec/cfg or update docs. |
| `real-architecture.md:269` | `most formally specified, adversarially tested... in the open literature` | OVERCLAIM | External literature comparison, complete passing model-check suite, reproducible adversarial logs. |
| `MNEMOSYNE_RECONCILIATION.md:18` | `verified verse_unified.camkes wiring` | PARTIAL SUPPORT | Static audit and build support wiring consistency; "verified" should be "audited/build-tested" unless formal capDL proof exists. |
| `RECOVERY_MANIFEST.md:48` | `verified assembly` | PARTIAL SUPPORT | Same: build/runtime-tested assembly, not formal verification. |
| `NATIVE_SEL4_TCB_SETUP.md:187` | `cooperative self-healing, not real TCB-based respawn` | SUPPORTED | Runtime logs prove cooperative recovery and absence of TCB logs. |
| `SUPPORT_STATUS.md:3` | `Restored And Verified` | OVERCLAIM | Split into restored, built, runtime-observed, model-checked. |
| `SUPPORT_STATUS.md:14` | `Verified Commands` | PARTIAL SUPPORT | Commands may pass, but "verified" should state "observed passing on date". |
| `architecture.md` broad speculative claims | Many lines claim production, formally verified, impossible, guaranteed, secure hardware behavior | OVERCLAIM / ARCHIVAL | This file is speculative design text, not evidence for the current repo. Treat all implementation-sounding claims as NOT PROVEN unless tied to current source, build, TLC, or runtime logs. |

## 8. What must be fixed next

1. Fix docs first. Replace "verified", "formally proven", "scheduler enforcement", "TCB restart", and broad "self-healing" claims with scoped terms backed by this report.
2. Decide the canonical CodexFS spec. Either repair v19.5 until TLC passes with meaningful properties, or demote it and explicitly document v12 as an older bounded safety model.
3. Make CodexFS runtime match the model or make the model match the runtime. Current runtime XOR/in-memory implementation does not match "cryptographic append-only Merkle-DAG with CAS snapshot validation".
4. Repair `Recovery_Task.tla`: add meaningful liveness, fair detection progression, bounded but non-misleading counters, and no hidden deadlocks.
5. Move `Recovery_TCB` into a runnable top-level spec/cfg or document it as unmodel-checked draft.
6. Implement or remove `VERSE_TCB_ENFORCED` claims. Completion requires runtime logs for `seL4_TCB_Suspend`, resource teardown/rebuild, fresh TCB register setup, and worker resume.
7. Implement real scheduler enforcement before claiming DharmaNet enforcement. Detection logs are not enforcement.
8. Add canonical runtime test scripts that save full build and simulation logs under `run_logs/`.
9. Make `tools/chaos_monkey.py` target `src/apps/verse_unified` or clearly label it as testing the root duplicate tree.

## 9. Milestone checklist with acceptance tests

| Milestone | Acceptance test |
|---|---|
| M0: Build reproducibility | `./build.sh verse_unified` exits 0 and emits `BUILD_OK:verse_unified`; report all warnings including RWX segment warning. |
| M1: Runtime smoke | QEMU log includes userspace boot, CORTEX, CODEX, Sentinel forward, writer/reader, DharmaNet status, Watchdog start. |
| M2: Cooperative recovery | Runtime log includes TestWorker deadlock, Watchdog heartbeat loss, ProcMan restart attempt, TestWorker reinit, Watchdog re-arm, continuous second run. |
| M3: Sentinel negative path | Canonical runtime log includes both allowed and blocked IPC paths, not just `S: FORWARD`. |
| M4: CodexFS model | Canonical CodexFS spec/cfg exists under documented names and passes TLC without hiding meaningful deadlocks. State counts recorded. |
| M5: CodexFS runtime integrity | Runtime corruption test mutates stored data and `fs_verify` fails; no "cryptographic" claim until cryptographic hash/root exists. |
| M6: Recovery model | `Recovery_Task` checks TypeOK, deadlock freedom, and recovery liveness under small meaningful bounds. No liveness warning caused by unsafe state constraints. |
| M7: TCB restart | Native boot log shows `seL4_TCB_Suspend(worker_tcb) OK`, resource revoke/rebuild, fresh TCB configured/resumed, TestWorker starts as a fresh instance. |
| M8: Scheduler enforcement | Runtime uses MCS scheduling-context or equivalent enforcement syscalls and demonstrates throttling/quota, not just WARN/CRIT logs. |
| M9: Release claim gate | A doc lint script rejects unsupported strong words unless linked to exact command output and source path. |

## 10. Commands run and raw outputs

This section records the decisive raw outputs. Exploratory `rg`, `find`, `nl`, and `sed` commands were also run to locate files and line references.

### Build

Command:

```bash
./build.sh verse_unified
```

Raw output excerpt:

```text
-- Build files have been written to: /tmp/camkes/build_verse_unified
...
[355/357] Linking C executable kernel/kernel.elf
/usr/bin/ld: warning: kernel/kernel.elf has a LOAD segment with RWX permissions
[356/357] objcopy kernel into bootable elf
[357/357] Generating images/capdl-loader-image-x86_64-pc99
BUILD_OK:verse_unified
```

### Runtime

Command:

```bash
timeout 180s docker run --rm -v /home/king/verse_os:/host user_img-king bash -lc '... build src/apps/verse_unified ... timeout 70s ./simulate'
```

Raw output excerpt:

```text
BUILD_OK_RUNTIME:verse_unified
IMAGE_PATH:/tmp/camkes/build_verse_unified_runtime/images/capdl-loader-image-x86_64-pc99
...
Booting all finished, dropped to user space
TestWorker: started
ProcMan: waiting
WDOG: active monitoring
DHARMA: strict hysteresis + escalation
CORTEX: ok
CLIENT: call
CODEX: ok
S: FORWARD
HELLO: ok
CLIENT: done
WRITER: done
READER: ok
TestWorker: DEADLOCK SIMULATION
DHARMA: OK (52%)
DHARMA: WARN (58%)
WDOG: heartbeat lost after 50 polls, setting kill flag
WDOG: waiting for recovery heartbeat...
ProcMan: restart attempt 1/3
TestWorker: restart flag seen! Reinitialising...
ProcMan: restart flag acknowledged
WDOG: heartbeat resumed, re-armed and monitoring
ProcMan: restart done
TestWorker: second run complete, entering continuous loop
...
qemu-system-x86_64: terminating on signal 15 from pid 1 (timeout)
```

### TLC tooling caveat

Initial parallel TLC attempt:

```text
java.rmi.server.ExportException: Listen failed on port: 0
java.net.SocketException: Operation not permitted
```

Rerun was performed with escalation and `-workers 1`. Parallel commands also collided on the default timestamped `states/` directory:

```text
This directory should be /home/king/verse_os/states/26-05-02-11-18-34, but that directory already exists.
```

### CodexFS stale docs command

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_doc_missing CodexFS.tla -config CodexFS.cfg
```

Raw output:

```text
TLC encountered the following error when trying to read the configuration file CodexFS.cfg:
File not found.
```

### CodexFS v19.5

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_codex_v19_5_deadlock_on_escalated CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
```

Raw output:

```text
Error: Deadlock reached.
258 states generated, 192 distinct states found, 85 states left on queue.
The depth of the complete state graph search is 6.
```

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_codex_v19_5_deadlock_off_escalated CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg
```

Raw output:

```text
Checking 2 branches of temporal properties for the complete state space with 5528 total distinct states
Error: Temporal properties were violated.
State 21: Stuttering
3826 states generated, 2764 distinct states found, 0 states left on queue.
```

### CodexFS v12

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_codex_v12_escalated src/specs/CodexFS_Monotonic_v12.tla -config src/specs/CodexFS_Monotonic_v12.cfg
```

Raw output:

```text
Error: Deadlock reached.
778 states generated, 487 distinct states found, 143 states left on queue.
The depth of the complete state graph search is 8.
```

Command:

```bash
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_tlc_codex_v12_deadlock_off_escalated src/specs/CodexFS_Monotonic_v12.tla -config src/specs/CodexFS_Monotonic_v12.cfg
```

Raw output:

```text
Model checking completed. No error has been found.
1600 states generated, 991 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 11.
```

### Recovery

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_cfg_escalated src/specs/Recovery_Task.tla -config src/specs/Recovery_Task.cfg
```

Raw output:

```text
Model checking completed. No error has been found.
108 states generated, 73 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 16.
```

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_deadlock_on_escalated src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_deadlock_on.cfg
```

Raw output:

```text
Error: Deadlock reached.
State 13: <WatchdogDetect line 95, col 5 to line 100, col 84 of module Recovery_Task>
/\ restart_count = 1
/\ watchdog_state = "DETECTED"
/\ missed_polls = 2
/\ worker_state = "DEAD"
105 states generated, 70 distinct states found, 2 states left on queue.
The depth of the complete state graph search is 14.
```

Command:

```bash
java -XX:+UseParallelGC -Xmx2g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_tlc_recovery_task_liveness_escalated src/specs/Recovery_Task.tla -config /tmp/Recovery_Task_liveness.cfg
```

Raw output:

```text
Warning: Declaring state or action constraints during liveness checking is dangerous
Error: Temporal properties were violated.
State 8: Stuttering
108 states generated, 73 distinct states found, 0 states left on queue.
```

### Sentinel, CortexMM, DharmaNet

Sentinel with `-deadlock`:

```text
Model checking completed. No error has been found.
38629 states generated, 21179 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
```

CortexMM:

```text
Model checking completed. No error has been found.
541 states generated, 81 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 9.
```

DharmaNet:

```text
Model checking completed. No error has been found.
28562 states generated, 169 distinct states found, 0 states left on queue.
The depth of the complete state graph search is 2.
```

### Static audit and chaos harness

Command:

```bash
python3 tools/capability_audit.py src/apps/verse_unified/verse_unified.camkes
```

Raw output:

```text
audited src/apps/verse_unified/verse_unified.camkes: 26 connection declarations
...
CAPABILITY_AUDIT_OK
```

Command:

```bash
python3 tools/chaos_monkey.py
```

Raw output:

```text
bypass_sentinel: caught
drop_restart: caught
swap_codex_reader: caught
CHAOS_MONKEY_OK
```

Limit: `tools/chaos_monkey.py` targets `/home/king/verse_os/verse_unified/verse_unified.camkes`, not the canonical `src/apps/verse_unified` tree used by `build.sh`.
