------------------------------- MODULE CodexFS_Final -------------------------------
EXTENDS Integers, FiniteSets, Sequences

CONSTANTS MaxOps, HashMax
ASSUME MaxOps > 0 /\ HashMax > 1

\* SMP gap note:
\* This model treats AppendBlock, TamperBlock, and CommitNext as serialized
\* atomic transitions over log and commitIndex. That matches the single-core
\* prototype discipline, but it does not model multicore dataport races.
\* SMP interleavings break the current assumptions if:
\* - two writers append to log concurrently without a single tail linearization;
\* - CommitNext reads a block while another core mutates its data/hash fields;
\* - commitIndex becomes visible before the corresponding log entry is visible;
\* - a verifier reads predecessor and current hashes from different snapshots.
\* A future SMP model needs memory ordering constraints around log append,
\* validation, and commitIndex publication: acquire/release queue operations,
\* CAS or a single-writer tail discipline, and a barrier before publishing a
\* newly committed index.

H(prev, data) == prev * HashMax + data + 1
Max(a,b) == IF a > b THEN a ELSE b

VARIABLES log, commitIndex, ops_left

Init ==
    /\ log = << <<0,0>> >>
    /\ commitIndex = 1
    /\ ops_left = MaxOps

AppendBlock(data) ==
    /\ ops_left > 0
    /\ data \in 0..HashMax-1
    /\ LET prev == log[Len(log)][2]
           nh   == H(prev, data)
       IN  /\ log' = Append(log, <<data, nh>>)
           /\ ops_left' = ops_left - 1
           /\ UNCHANGED commitIndex

TamperBlock(i, new_data) ==
    /\ ops_left > 0
    /\ i > commitIndex
    /\ i <= Len(log)
    /\ new_data \in 0..HashMax-1
    /\ LET old_hash == log[i][2]
       IN  /\ log' = [log EXCEPT ![i] = <<new_data, old_hash>>]
           /\ ops_left' = ops_left - 1
           /\ UNCHANGED commitIndex

Valid(i) ==
    i = 1 \/ log[i][2] = H(log[i-1][2], log[i][1])

CommitNext ==
    /\ commitIndex < Len(log)
    /\ Valid(commitIndex + 1)
    /\ commitIndex' = commitIndex + 1
    /\ UNCHANGED <<log, ops_left>>

Safety ==
    \A i \in 2..commitIndex : Valid(i)

Next ==
    \/ \E d \in 0..HashMax-1 : AppendBlock(d)
    \/ \E i \in 2..Len(log), d \in 0..HashMax-1 : TamperBlock(i, d)
    \/ CommitNext

Spec == Init /\ [][Next]_<<log, commitIndex, ops_left>>
THEOREM Spec => []Safety
=============================================================================
