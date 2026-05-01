# VERSE OS Support Infrastructure Status

## Restored And Verified

- Threat model: `THREAT_MODEL.md`
- Formal report: `FORMAL_METHODS_REPORT.md`
- Recovery manifest: `RECOVERY_MANIFEST.md`
- Capability graph auditor: `tools/capability_audit.py`
- Chaos mutation harness: `tools/chaos_monkey.py`
- Sentinel/CortexMM/DharmaNet scoped TLA specs: `src/specs/`
- CodexFS TLA specs: root TLA files and `src/specs/`
- Recovery snapshot: `verse_os_recovery_snapshot_2026-05-01.tar.gz`

## Verified Commands

```bash
python3 tools/capability_audit.py
python3 tools/chaos_monkey.py
```

Both commands passed on 2026-05-01.

## Runtime Verification

The local `verse_unified/` tree was copied into the seL4/CAmkES Docker image, built with:

```bash
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified
ninja
./simulate
```

Observed runtime milestones:

- `BUILD_OK`
- `CORTEX: ok`
- `CLIENT: call`
- `S: FORWARD`
- `HELLO: ok`
- `WRITER: done`
- `READER: ok`
- `DHARMA: OK (53-56%)`
- `DHARMA: WARN (after sustained pressure)`
- `TestWorker: DEADLOCK SIMULATION`
- `WDOG: heartbeat lost`
- `ProcMan: restart attempt 1/3`
- `TestWorker: restart flag seen! Reinitialising...`
- `WDOG: heartbeat resumed`
- `TestWorker: second run complete`

The QEMU run was terminated by timeout after successful observation because the OS demo intentionally continues running.

## Latest Review Run

On 2026-05-01 the critic-style Docker command was rerun from `src/apps/verse_unified` after the Dharma hysteresis and persistent watchdog fixes.

Confirmed:

- Full CAmkES build completed with `BUILD OK`.
- Watchdog threshold is now 50 missed polls, reducing false-positive recovery under single-core QEMU scheduler jitter.
- TestWorker deadlock was detected once, ProcMan issued restart attempt `1/3`, and TestWorker resumed continuous heartbeat.
- Dharma no longer oscillates WARN/OK around a single threshold. It uses `WARN_ENTER=55`, `WARN_EXIT=45`, and a 3-epoch WARN dwell. In the observed run it stayed OK around 53-56%, then entered WARN only after sustained pressure.
- No ProcMan CRIT quarantine was observed in the successful review run.

Current repository note: `.git/` was present but empty in the recovered tree. It was reinitialized on 2026-05-02.

## 2026-05-02 Baseline Groundwork

- Added `src/specs/Recovery_Task.tla` as a cooperative recovery model. It requires the worker to voluntarily observe `restart_flag`; it does not claim forced TCB restart.
- Added `TCB-3: Cooperative restart bypass` to `THREAT_MODEL.md`.
- Added SMP assumption notes to `CodexFS_Final.tla` and `src/specs/Sentinel_Lattice.tla`.
- Ran the Ubuntu 24.04 Docker manifest path from `NATIVE_SEL4_TCB_SETUP.md`; `repo sync` completed, but no built-in CAmkES `seL4TCB` connector was present at the synced revisions.
