# Bounded Active-TCB Failover TLA Evidence

Date: 2026-05-02

## Verdict

Issue 7 is complete as bounded TLC model checking.

The new model checks bounded active-TCB failover over the concrete TCB labels:

```text
original active TCB: 0x100
spare pool:          0x104, 0x109, 0x10a
```

This is not a full OS proof, not a seL4 kernel proof, not a C refinement proof,
and not a TLAPS proof.

Allowed claim:

```text
Bounded active-TCB failover was model-checked with TLC for the normal recovery
and exhausted-spare-pool paths.
```

## Model Files

```text
src/specs/Bounded_Active_TCB_Failover.tla
src/specs/Bounded_Active_TCB_Failover_normal.cfg
src/specs/Bounded_Active_TCB_Failover_exhausted.cfg
```

TLC logs:

```text
out/formal_issue7_20260502/tlc_normal.log
out/formal_issue7_20260502/tlc_exhausted.log
```

## Modeled State

The model includes these system states:

```text
Running
Deadlocked
Suspended
Recovered
StableRecovered
Exhausted
Quarantined
```

The model includes:

- `active_tcb`
- `suspended_tcb`
- `quarantined`
- `used_spares`
- `retry_count`
- `fault_events`
- watchdog detection transitions
- ProcMan recovery transitions
- spare pool exhaustion and quarantine

## Checked Invariants

Both TLC configs check:

```text
TypeOK
ActiveNotQuarantined
FreshUnusedSpareInvariant
RetryCountBound
```

The relevant invariant meanings are:

- `active_tcb` is never a quarantined TCB.
- Each recovery uses the next fresh unused spare from `0x104`, `0x109`,
  `0x10a`.
- `retry_count <= 3`.
- Used spare order matches the runtime pool order.

## Checked Liveness Properties

Normal recovery config:

```text
NormalRecoveryReachesStable
```

Exhausted-spare-pool config:

```text
ThreeFailedCyclesQuarantine
ExhaustionQuarantines
```

These properties cover:

- normal recovery reaches `StableRecovered`
- after all three spare recovery attempts are consumed, the model reaches
  `Quarantined`
- `Exhausted` leads to `Quarantined`

## TLC Normal Recovery Run

Command:

```sh
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_issue7_normal src/specs/Bounded_Active_TCB_Failover.tla -config src/specs/Bounded_Active_TCB_Failover_normal.cfg
```

Saved log:

```text
out/formal_issue7_20260502/tlc_normal.log
```

Observed result:

```text
16:Model checking completed. No error has been found.
20:6 states generated, 5 distinct states found, 0 states left on queue.
21:The depth of the complete state graph search is 5.
```

## TLC Exhausted-Spare-Pool Run

Command:

```sh
java -XX:+UseParallelGC -Xmx4g -cp tools/tla/tla2tools.jar tlc2.TLC -workers 1 -metadir /tmp/verse_issue7_exhausted src/specs/Bounded_Active_TCB_Failover.tla -config src/specs/Bounded_Active_TCB_Failover_exhausted.cfg
```

Saved log:

```text
out/formal_issue7_20260502/tlc_exhausted.log
```

Observed result:

```text
16:Model checking completed. No error has been found.
20:14 states generated, 13 distinct states found, 0 states left on queue.
21:The depth of the complete state graph search is 13.
```

## Scope Boundary

This model abstracts over:

- real seL4 kernel behavior
- generated CAmkES glue code
- capDL object layout details
- CSpace/VSpace mutation details
- TCB cap delete/revoke cleanup
- fault endpoint receive/decode handling
- instruction-level scheduling and timing

The model matches the bounded runtime failover shape only:

```text
0x100 -> 0x104 -> 0x109 -> 0x10a -> Quarantined
```

## Not Proven

- Full OS correctness is not proven.
- seL4 correctness is not proven by this project model.
- C implementation refinement to TLA+ is not proven.
- TLAPS proof is not provided.
- Cap deletion/revocation is not proven.
- Fault endpoint receive/decode recovery is not proven.
