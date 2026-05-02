# CodexFS Runtime XOR Evidence

Date: 2026-05-02

## Verdict

The runtime-faithful CodexFS XOR checksum-chain model passes bounded TLC checks.

This model matches the current runtime implementation shape:

- bounded in-memory block array;
- one-byte previous-hash field;
- one-byte bitwise XOR checksum;
- append-only `fs_write` style behavior;
- `fs_verify` style predecessor/checksum validation;
- explicit terminal states for full/corrupt conditions.

This is bounded model-checking evidence only. It is not a cryptographic proof, not persistence evidence, not a proof of `CodexFS_Monotonic_v19_5`, and not a production-storage claim.

## Files

- `src/specs/CodexFS_Runtime_XOR.tla`
- `src/specs/CodexFS_Runtime_XOR_type.cfg`
- `src/specs/CodexFS_Runtime_XOR_deadlock.cfg`
- `src/specs/CodexFS_Runtime_XOR_goodchain.cfg`

## TLC Results

Commands were run from `~/verse_os`.

Results:

- TypeOK: PASS
- Deadlock freedom: PASS
- GoodChain invariant: PASS
- State space for each run: 746 generated / 271 distinct
- TLC version: 2.19 of 08 August 2024

## Claim Boundary

Allowed:

- Runtime CodexFS bitwise-XOR checksum-chain semantics have a bounded TLC model passing TypeOK, deadlock freedom, and GoodChain under `MaxBlocks = 3`, `DataVals = {0, 1, 2}`.

Not allowed:

- CodexFS is cryptographic.
- CodexFS is persistent.
- CodexFS v19.5 is fixed.
- Full CodexFS is formally verified.
- Production storage integrity is proven.
