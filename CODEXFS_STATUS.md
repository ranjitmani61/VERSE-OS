# CODEXFS_STATUS

Date: 2026-05-02

## Inventory

Command:

```bash
find . -path './.git' -prune -o \( -iname '*CodexFS*.tla' -o -iname '*CodexFS*.cfg' \) -print | sort
```

Output excerpt:

```text
./CodexFS_Final.tla
./CodexFS_Monotonic_v18.tla
./CodexFS_Monotonic_v19.tla
./CodexFS_Monotonic_v19_5.cfg
./CodexFS_Monotonic_v19_5.tla
./src/specs/CodexFS_Monotonic_v10.cfg
./src/specs/CodexFS_Monotonic_v10.tla
./src/specs/CodexFS_Monotonic_v11.cfg
./src/specs/CodexFS_Monotonic_v11.tla
./src/specs/CodexFS_Monotonic_v12.cfg
./src/specs/CodexFS_Monotonic_v12.tla
...
./src/specs/codexfs_monotonic_recovered/CodexFS_Monotonic_v20.tla
```

The current canonical candidate is `CodexFS_Monotonic_v19_5.tla` with `CodexFS_Monotonic_v19_5.cfg`, because it is the top-level latest-numbered spec with a matching top-level cfg.

## Canonical cfg

Evidence:

```text
CodexFS_Monotonic_v19_5.cfg:
1 CONSTANTS
2     MaxUserOps = 3
3     MaxSysOps  = 16
4     HashMax    = 2
6 SPECIFICATION Spec
8 INVARIANTS
9     TypeOK
11 PROPERTIES
12     DetectionLiveness
13     EventualLiveness
```

## TLC results

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| TLA-CODEX-001 | PASS | Inventory command above | Top-level matching pair: `./CodexFS_Monotonic_v19_5.tla`; `./CodexFS_Monotonic_v19_5.cfg` | Canonical candidate identified. | Update docs to this path only after it passes. |
| TLA-CODEX-002 | PARTIAL | `CodexFS_Monotonic_v19_5.cfg` | `INVARIANTS TypeOK`; `PROPERTIES DetectionLiveness EventualLiveness` | Cfg checks TypeOK plus two temporal properties. It does not name a storage safety invariant beyond TypeOK. | Add explicit safety/anchor invariants if intended. |
| TLA-CODEX-003 | BROKEN | Command: `java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_truth_codex_v19_5_deadlock_on CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg` | `Error: Deadlock reached.`; `258 states generated, 192 distinct states found`; `depth ... 6` | With normal deadlock checking, canonical candidate fails before completing. | Fix model deadlock or explicitly model finite termination. |
| TLA-CODEX-004 | FAIL | Command: `java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -deadlock -workers 1 -metadir /tmp/verse_truth_codex_v19_5_deadlock_off CodexFS_Monotonic_v19_5.tla -config CodexFS_Monotonic_v19_5.cfg` | `Checking 2 branches of temporal properties`; `Error: Temporal properties were violated.`; `State 6: Stuttering`; `3826 states generated, 2764 distinct states found` | Disabling deadlock does not make v19.5 pass; temporal properties fail. | Repair liveness/fairness/bounds before claiming model-checked CodexFS. |

## Property status

| Property | Verdict | Evidence |
|---|---|---|
| TypeOK | NOT A PASSING RUN | No TypeOK violation was reported, but both canonical TLC runs failed for deadlock or temporal violation. |
| Safety | NOT PROVEN | Canonical cfg does not list a named CodexFS safety invariant beyond `TypeOK`. |
| Liveness | FAIL | TLA-CODEX-004 temporal property violation. |
| Deadlock freedom | BROKEN | TLA-CODEX-003 deadlock reached. |
| Deadlock-hidden success | FAIL | Even with `-deadlock`, temporal properties fail. |

## Runtime source comparison

| ID | Verdict | Evidence source | Exact quote or output excerpt | Implication | Required fix or next test |
|---|---|---|---|---|---|
| SRC-CODEX-001 | BROKEN for cryptographic claim | `src/apps/verse_unified/components/CodexFS/src/codexfs.c:5,14,15` | `static unsigned char cs(...)`; `s^=d[i]`; `b->h=cs(...)`; `fs_verify...cs(...)` | Runtime integrity check is an 8-bit XOR checksum, not cryptographic. | Do not call runtime CodexFS cryptographic. |
| SRC-CODEX-002 | NOT PROVEN | Command: `rg -n "SHA|sha|crypto|hash|cs\(|checksum|CAS|snapshot|ver|persistent|TPM|ROM" src/apps/verse_unified/components/CodexFS/src/codexfs.c src/apps/verse_unified/components/ReadClient/src/readclient.c src/apps/verse_unified/components/WriteClient/src/writeclient.c` | Only `cs(...)`, `fs_write`, and `fs_verify` matches were found; no SHA/crypto/CAS/snapshot/persistence matches. | Runtime does not implement the v19.5 snapshot/CAS model or persistent cryptographic storage. | Align model and runtime or explicitly label runtime as toy in-memory checksum demo. |
| SRC-CODEX-003 | PASS for demo only | `run_logs/verse_unified_demo_fixed_20260502_102117.log:462,466,467` | `CODEX: ok`; `WRITER: done`; `READER: ok` | Runtime demo writes three records and reader verifies current checksum chain. | Add mutation/corruption runtime test if claiming tamper detection. |

## Status summary

- Canonical current spec: `CodexFS_Monotonic_v19_5.tla` with `CodexFS_Monotonic_v19_5.cfg`.
- Canonical spec result: BROKEN.
- Runtime CodexFS: in-memory checksum demo.
- Cryptographic claim: BROKEN for current runtime.
- Persistence claim: NOT PROVEN.
- Snapshot/CAS claim: NOT IMPLEMENTED in current runtime source.

