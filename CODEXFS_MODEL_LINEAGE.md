# CodexFS Model Lineage

Date: 2026-05-02

## Purpose

CodexFS has multiple TLA+ model generations. They must not be collapsed into one claim. Older models may contain important design ideas, while current release claims must be based only on models and runtime behavior that were actually checked.

## Current Lineage Status

| Model | Status | Meaning |
|---|---|---|
| v9 | ARCHIVAL / IMPORTANT | Historically valuable design step. Preserve for polish review. Do not use as current release proof without rerunning and documenting TLC output. |
| v12 | PARTIAL | Important large milestone. Prior evidence indicates it can pass with deadlock checking disabled, but deadlocks under normal checking. Not a clean proof. |
| v19.5 | STRONG CANDIDATE / CURRENTLY FAILING | Stronger canonical candidate, but current TLC runs show deadlock and temporal-property failure. Not verified. |
| v20 | DISCUSSED / NOT EXECUTED | Potential next canonical direction. Must be executed and checked during polish time before any claim. |
| CodexFS_Runtime_XOR | PASS / RUNTIME-FAITHFUL | Matches current runtime XOR checksum-chain shape and passes bounded TLC TypeOK, deadlock freedom, and GoodChain under small bounds. |

## Release Claim Rule

Allowed now:

- Current runtime CodexFS XOR checksum-chain semantics have bounded TLC evidence.
- Stronger CodexFS model generations exist and are preserved for continued work.

Not allowed now:

- CodexFS is cryptographic.
- CodexFS v19.5 is verified.
- CodexFS v20 is accepted.
- Full CodexFS storage integrity is proven.
- Production storage security is proven.

## Polish-Time Work

1. Re-run v9, v12, v19.5, and v20 with current TLC.
2. Store exact commands, TLC version, state counts, and failure traces.
3. Decide whether v20 supersedes v19.5.
4. Align the selected canonical model with runtime semantics or explicitly label it as future architecture.
5. Only update public claims after the above evidence exists.
