# Chat Recovery Notes

Recovery date: 2026-05-01

The following recovered context files were scanned in the requested order:

1. `architecture.md` - 3,295 lines
2. `discussion.md` - 10,770 lines
3. `discussion1.md` - 5,904 lines
4. `chat0.md` - 4,306 lines
5. `chat.md` - 13,950 lines
6. `chat2.md` - 10,983 lines

Total scanned: 49,208 lines.

## Main architecture recovered

- VERSE OS is a capability-enforced seL4/CAmkES microkernel prototype.
- The implementation baseline is the 14/15-component `verse_unified` image:
  Sentinel, CortexMM, DharmaNet, CodexFS, Watchdog, ProcMan, LogRing, clients,
  workers, and recovery dataports.
- Formal models cover Sentinel lattice routing, CortexMM memory authority,
  DharmaNet budgets, and CodexFS monotonic integrity.
- Current self-healing is watchdog -> ProcMan -> cooperative restart flag.
- Real lifecycle recovery still requires TCB authority or a custom CAmkES/seL4
  environment that supports the needed connector/capability wiring.

## Recovered build tree

The missing persistent host build layout has been restored under `src/apps/`.

Recovered apps:

- `src/apps/verse_unified`
- `src/apps/persistent_watchdog`
- `src/apps/sentinel_negtest`
- `src/apps/codexfs_demo`
- `src/apps/cortexmm_demo`
- `src/apps/dharmanet_severity`
- `src/apps/watchdog_tcb`

Recovered tools:

- `src/tools/audit_caps.py` - generic CAmkES app inventory/audit tool
- `build.sh` - Docker-backed CAmkES build wrapper

## Build verification

The following Docker builds completed:

- `./build.sh verse_unified` -> `BUILD_OK:verse_unified`
- `./build.sh sentinel_negtest` -> `BUILD_OK:sentinel_negtest`
- `./build.sh codexfs_demo` -> `BUILD_OK:codexfs_demo`
- `./build.sh cortexmm_demo` -> `BUILD_OK:cortexmm_demo`
- `./build.sh persistent_watchdog` -> `BUILD_OK:persistent_watchdog`
- `./build.sh dharmanet_severity` -> `BUILD_OK:dharmanet_severity`
- `./build.sh watchdog_tcb` -> `BUILD_OK:watchdog_tcb`

## Important correction

`dharmanet_severity` was reconstructed as a standalone demo. The copied unified
DharmaNet component originally required `severity_buf` for ProcMan. The
standalone demo has no ProcMan, so that local demo component was restored to the
discussion's standalone severity-printing form.
