# TCB Enforced Build Flag Evidence

Date: 2026-05-02

## Verdict

`VERSE_TCB_ENFORCED` is now selectable through the normal build wrapper without force-editing ProcMan source.

Both builds completed:

- Default cooperative build: PASS
- `VERSE_TCB_ENFORCED=ON` compile path: PASS

## Commands

```bash
./build.sh verse_unified
./build.sh verse_unified -DVERSE_TCB_ENFORCED=ON
```

## Observed Result

Both logs ended with:

```text
BUILD_OK:verse_unified
```

Both logs also retained the known linker warning:

```text
kernel/kernel.elf has a LOAD segment with RWX permissions
```

## Claim Boundary

Allowed:

- The default build still compiles.
- The guarded TCB-enforced ProcMan branch compiles through a selectable CMake flag.
- The previous source-force probe is no longer required for compile validation.

Not allowed:

- Runtime native seL4 TCB restart is proven.
- ProcMan has valid runtime TCB, CNode, VSpace, IPC buffer, untyped, or fault endpoint caps.
- Fresh TestWorker TCB creation/resume succeeds at runtime.
- Non-cooperative worker recovery is proven.
