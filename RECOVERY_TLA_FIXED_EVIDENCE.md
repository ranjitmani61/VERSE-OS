# Recovery TLA Fixed Evidence

Date: 2026-05-02

## Verdict

Bounded TLC recovery models now pass TypeOK, deadlock freedom, and recovery-resolution liveness with terminal escalation.

This is bounded model-checking evidence only. It is not an unconstrained mathematical proof, not a TLAPS proof, and not runtime evidence of native seL4 TCB restart.

## Cooperative Recovery_Task

Commands were run from `~/verse_os/src/specs`.

Results:

- TypeOK: PASS
- Deadlock: PASS
- CooperativeRecoveryResolution: PASS
- State space: 107 generated / 69 distinct
- Warning: liveness uses `StateConstraint`; TLC warns this is dangerous for liveness checking.

## Standalone Recovery_TCB

Commands were run from `~/verse_os/src/specs`.

Results:

- TCBTypeOK: PASS
- Deadlock: PASS
- TCBRecoveryResolution: PASS
- TaskSafetyUnderRefinement: PASS
- State space: 216 generated / 147 distinct
- Warning: liveness uses `TCBStateConstraint`; TLC warns this is dangerous for liveness checking.

## Release Claim Boundary

Allowed:

- Bounded TLC models for cooperative recovery and TCB recovery pass TypeOK, deadlock freedom, and recovery-resolution checks with terminal escalation.

Not allowed yet:

- Native seL4 TCB restart is runtime-proven.
- Recovery is formally proven without bounds.
- Full self-healing is proven.
- TLAPS refinement proof is complete.
