# VERSE-OS

VERSE-OS is a seL4/CAmkES research operating-system prototype focused on capability-confined components, runtime recovery experiments, and bounded formal models.

This repository is not a production operating system and does not claim whole-system formal verification.

## Current Status

Implemented and observed:

- seL4/CAmkES unified prototype build path: `./build.sh verse_unified`
- CAmkES component graph for Sentinel, CortexMM, DharmaNet, CodexFS, Watchdog, ProcMan, TestWorker, and supporting clients
- Runtime cooperative recovery demo: Watchdog detects TestWorker heartbeat loss, ProcMan signals restart, TestWorker voluntarily reinitializes, Watchdog re-arms
- Bounded TLC recovery models with terminal escalation
- Runtime-faithful CodexFS bitwise-XOR checksum-chain model passing bounded TLC checks
- Guarded ProcMan TCB restart skeleton that compiles when `VERSE_TCB_ENFORCED` is force-enabled for probe builds

## What Is Proven or Checked

Evidence documents:

- `BUILD_STATUS.md`
- `RUNTIME_RECOVERY_EVIDENCE.md`
- `RECOVERY_TLA_FIXED_EVIDENCE.md`
- `CODEXFS_RUNTIME_XOR_EVIDENCE.md`
- `CODEXFS_MODEL_LINEAGE.md`
- `TCB_ENFORCED_COMPILE_PROBE.md`
- `VERSE_OS_TRUTH_TABLE.md`
- `VERSE_OS_VERIFICATION_REPORT.md`
- `CLAIM_AUDIT.md`

Current bounded model-checking highlights:

- Recovery cooperative model: TypeOK, deadlock freedom, and recovery-resolution checks pass under bounded TLC.
- Standalone Recovery_TCB model: TypeOK, deadlock freedom, recovery-resolution, and refinement-shape checks pass under bounded TLC.
- CodexFS runtime bitwise-XOR model: TypeOK, deadlock freedom, and GoodChain pass under bounded TLC.

## Important Boundaries

Not currently proven:

- Whole-system formal verification
- Native seL4 TCB restart at runtime
- Fresh process replacement at runtime
- Non-cooperative crash recovery
- Cryptographic CodexFS
- Persistent storage integrity
- Scheduler/MCS enforcement
- Production hardening

CodexFS v19.5 and v20 are preserved as stronger model-lineage candidates, but they are not current release proofs unless and until their TLC runs pass cleanly and are documented.
