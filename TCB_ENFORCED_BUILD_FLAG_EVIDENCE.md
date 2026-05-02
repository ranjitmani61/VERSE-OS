# TCB Enforced Build Flag Evidence

Date: 2026-05-02

## Verdict

`VERSE_TCB_ENFORCED` is now selectable through the normal build wrapper without force-editing ProcMan source.

Both builds completed:

- Default cooperative build: PASS
- `VERSE_TCB_ENFORCED=ON` compile/link path: PASS
- Enforced ProcMan strings were observed in exported binaries from the flag-enabled build.

## Commands

```bash
./build.sh verse_unified
./build.sh verse_unified -DVERSE_TCB_ENFORCED=ON
```

One container-session export build was also run with:

```bash
../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=verse_unified -DVERSE_TCB_ENFORCED=ON
ninja
```

## Observed Result

The flag-enabled build ended with:

```text
BUILD_OK_AND_EXPORTED:verse_unified
```

Known linker warning remained:

```text
kernel/kernel.elf has a LOAD segment with RWX permissions
```

Exported ProcMan artifacts contained these strings:

```text
ProcMan: seL4_TCB_Suspend failed (%d)
ProcMan: seL4_TCB_Suspend(worker_tcb) OK
ProcMan: TCB rebuild metadata missing; configure IPC addr, entry IP, and stack top
ProcMan: enforced TCB restart attempt %d/%d
ProcMan: enforced rebuild failed after suspend; quarantine required
ProcMan: enforced path unavailable, falling back to cooperative restart
seL4_TCB_Suspend
```

## Claim Boundary

Allowed:

- The default build still compiles.
- The guarded TCB-enforced ProcMan branch compiles and links through a selectable CMake flag.
- The flag-enabled ProcMan binary contains the enforced-path strings and `seL4_TCB_Suspend` symbol/string evidence.
- The previous source-force probe is no longer required for compile validation.

Not allowed:

- Runtime native seL4 TCB restart is proven.
- ProcMan has valid runtime TCB, CNode, VSpace, IPC buffer, untyped, or fault endpoint caps.
- Fresh TestWorker TCB creation/resume succeeds at runtime.
- Non-cooperative worker recovery is proven.
