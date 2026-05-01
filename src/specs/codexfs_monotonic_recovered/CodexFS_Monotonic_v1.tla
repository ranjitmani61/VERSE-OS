------------------------------- MODULE CodexFS_Monotonic_v1 -------------------------------
(* RECOVERED RECONSTRUCTION: original v1 was not present in Docker or local archives.
 * Rebuilt from the earliest surviving compact CodexFS safety model.
 * Lineage role: pre-v12 append-only commit safety baseline.
 *)
EXTENDS Integers, FiniteSets, Sequences

CONSTANTS MaxOps, HashMax
ASSUME MaxOps > 0 /\ HashMax > 1

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