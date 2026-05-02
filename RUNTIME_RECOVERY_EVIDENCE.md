# RUNTIME_RECOVERY_EVIDENCE

Date: 2026-05-02
Latest reviewed runtime log: `run_logs/verse_unified_demo_fixed_20260502_102117.log`

## Runtime Log Excerpts

Command:

```bash
nl -ba run_logs/verse_unified_demo_fixed_20260502_102117.log | sed -n '452,482p'
```

Output excerpt:

```text
455 Booting all finished, dropped to user space
456 TestWorker: started
457 ProcMan: waiting
458 WDOG: active monitoring
459 DHARMA: strict hysteresis + escalation
460 CORTEX: ok
461 CLIENT: call
462 CODEX: ok
463 S: FORWARD
464 HELLO: ok
465 CLIENT: done
466 WRITER: done
467 READER: ok
468 DHARMA: WARN (57%)
469 TestWorker: DEADLOCK SIMULATION
470 DHARMA: WARN (56%)
471 WDOG: heartbeat lost after 50 polls, setting kill flag
472 WDOG: waiting for recovery heartbeat...
473 ProcMan: restart attempt 1/3
474 TestWorker: restart flag seen! Reinitialising...
475 ProcMan: restart flag acknowledged
476 WDOG: heartbeat resumed, re-armed and monitoring
477 ProcMan: restart done
478 DHARMA: WARN (54%)
479 TestWorker: second run complete, entering continuous loop
```

## Findings

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| RUN-001 | PASS | `run_logs/verse_unified_demo_fixed_20260502_102117.log:455-467` | `Booting all finished, dropped to user space`; `TestWorker: started`; `WDOG: active monitoring`; `CODEX: ok`; `WRITER: done`; `READER: ok` | seL4/CAmkES image reached userspace and demo components started/executed. | Keep log as smoke-test evidence. |
| RUN-002 | PASS | `run_logs/verse_unified_demo_fixed_20260502_102117.log:469-479` | `TestWorker: DEADLOCK SIMULATION`; `WDOG: heartbeat lost after 50 polls, setting kill flag`; `ProcMan: restart attempt 1/3`; `TestWorker: restart flag seen! Reinitialising...`; `WDOG: heartbeat resumed, re-armed and monitoring`; `second run complete, entering continuous loop` | Cooperative recovery path is runtime-observed. | Keep claim scoped to cooperative recovery. |
| RUN-003 | NOT PROVEN | Command: `rg -n "seL4_TCB|fresh TestWorker|TCB_Suspend|TCB_Resume|TCB restart|fresh.*TCB" run_logs/verse_unified_demo_fixed_20260502_102117.log` | No output, exit code 1. | Runtime log contains no TCB suspend/resume or fresh TCB evidence. | Native TCB runtime test must log `seL4_TCB_Suspend(worker_tcb) OK`, resource rebuild, and fresh TCB resume. |
| SRC-WDOG-001 | PASS | `src/apps/verse_unified/components/Watchdog/src/watchdog.c:19-30` | `setting kill flag`; `*kflag = 1`; `heartbeat resumed, re-armed and monitoring` | Source matches runtime watchdog detection and re-arm behavior. | Add tests for repeated faults and non-cooperative worker behavior. |
| SRC-PROCMAN-001 | PASS | `src/apps/verse_unified/components/ProcMan/src/procman.c:76-93` | `static int cooperative_restart`; `*rf = 1`; `ProcMan: restart flag acknowledged` | ProcMan default path is cooperative restart flag signaling. | Do not call this TCB restart. |
| SRC-PROCMAN-002 | NOT PROVEN | `src/apps/verse_unified/components/ProcMan/src/procman.c:96-132` | `#ifdef VERSE_TCB_ENFORCED`; `STUB: requires native seL4 build environment`; `current Docker CAmkES build does not provide these caps` | TCB path is guarded and stubbed for current default runtime. | Enable and boot native capDL build with real caps before claiming. |
| SRC-PROCMAN-003 | NOT PROVEN | Command: `rg -n "VERSE_TCB_ENFORCED|add_compile|target_compile|compile_definitions" src/apps/verse_unified/CMakeLists.txt src/apps/verse_unified/components/*/CMakeLists.txt` | No output, exit code 1. | Default CMake does not enable `VERSE_TCB_ENFORCED`. | Add an explicit native build target if TCB path is intended. |
| SRC-TWORKER-001 | PASS | `src/apps/verse_unified/components/TestWorker/src/testworker.c:11-17` | `DEADLOCK SIMULATION`; `while (*rf == 0)`; `restart flag seen! Reinitialising...`; `second run complete` | Worker voluntarily observes restart flag. This is cooperative recovery. | Add non-cooperative crash/fault tests separately. |

## Classification

| Property | Verdict | Evidence ID |
|---|---|---|
| Cooperative recovery | PASS | RUN-002, SRC-PROCMAN-001, SRC-TWORKER-001 |
| TCB restart | NOT PROVEN | RUN-003, SRC-PROCMAN-002, SRC-PROCMAN-003 |
| Fresh process replacement | NOT PROVEN | RUN-003 |
| Non-cooperative crash recovery | NOT PROVEN | No null-deref/fault/fresh-process runtime log reviewed |
| Watchdog re-arm | PASS | RUN-002, SRC-WDOG-001 |

