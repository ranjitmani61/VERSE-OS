# CodexFS Monotonic Recovery Set

Recovery date: 2026-05-01

This directory preserves a complete `CodexFS_Monotonic` numbered lineage from
`v1` through `v20`.

## Source status

Recovered original files already present in the workspace:

- `CodexFS_Monotonic_v12.tla`
- `CodexFS_Monotonic_v12.cfg`
- `CodexFS_Monotonic_v18.tla`
- `CodexFS_Monotonic_v19.tla`
- `CodexFS_Monotonic_v19_5.tla`
- `CodexFS_Monotonic_v19_5.cfg`
- `CodexFS_Final.tla`

Docker search result:

- The running containers contained the CAmkES `CodexFS` component source.
- The missing TLA versions were not present in Docker, `/home/king`, `/tmp`,
  the copied Docker recovery trees, or the refreshed recovery archive.

## Reconstructed files

The following files were reconstructed because their original bytes were not
available from Docker or local archives:

- `v1` through `v11`: rebuilt from the earliest surviving compact CodexFS
  safety model, `CodexFS_Final.tla`.
- `v13` through `v17`: rebuilt from surviving `v12` snapshot-locked validation
  semantics as the nearest predecessor family before `v18`.
- `v20`: rebuilt from surviving `v19.5` closure semantics as the final numbered
  closure file.

Each reconstructed `.tla` file has a header marking it as a recovered
reconstruction. The original anchor files were copied without semantic edits
except for placement in this recovery directory.

## Version map

- `v1`-`v11`: append-only commit safety baseline
- `v12`: snapshot-locked validation
- `v13`-`v17`: reconstructed snapshot-lock lineage
- `v18`: system anchors, recovery, active corruption detection
- `v19`: full continuous auditing, deterministic rollback, temporal liveness
- `v19_5`: closure specification
- `v20`: reconstructed closure-numbered successor from `v19_5`
