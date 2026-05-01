# Docker Recovery Manifest

Recovery date: 2026-05-01

Recovered from running Docker containers based on `user_img-king`.

## Containers copied

- `8a11c759c7e5` -> `docker_recovered/8a11c759c7e5/`
- `4aa108f66513` -> `docker_recovered/4aa108f66513/`
- `044ce8e5bbc9` -> `docker_recovered/044ce8e5bbc9/`
- `2cd00f07fb13` -> `docker_recovered/2cd00f07fb13/`

Each container contributed:

- `/tmp/camkes/projects/camkes/apps/verse_unified`
- `/home/king`

## Recovered source tree

The only VERSE OS CAmkES app found under `/tmp/camkes/projects/camkes/apps` was:

- `verse_unified`

No separate `persistent_watchdog`, `codex`, `sentinel`, `dharma`, or `cortex` app directories were present outside `verse_unified`.

The recovered `verse_unified` tree contains the 15-component CAmkES prototype:

- `Client`
- `CodexFS`
- `CortexMM`
- `DharmaNet`
- `Hello`
- `LogRing`
- `MemClient`
- `ProcMan`
- `ReadClient`
- `Sentinel`
- `TestWorker`
- `Watchdog`
- `WorkerA`
- `WorkerB`
- `WriteClient`

## Differences between recovered containers

The recovered trees are identical except for timing-loop variants in:

- `components/WorkerA/src/workera.c`
- `components/WorkerB/src/workerb.c`

Observed variants:

- `8a11c759c7e5`: `WorkerA` tight increment loop, `WorkerB` slowed increment loop.
- `4aa108f66513`: `WorkerA` slowed increment loop, `WorkerB` same as `8a11c759c7e5`.
- `044ce8e5bbc9`: `WorkerA` slowed increment loop, `WorkerB` formatting-only variant of slowed loop.
- `2cd00f07fb13`: `WorkerA` same as `8a11c759c7e5`, `WorkerB` tight increment loop.

## Relationship to current workspace

The current workspace `verse_unified` matches `docker_recovered/8a11c759c7e5/verse_unified` for all recovered Docker files.

The only additional local directory under `verse_unified/components` is:

- `Mnemosyne`

That `Mnemosyne` directory is a local optional scaffold and was not present in the recovered Docker CAmkES app.
