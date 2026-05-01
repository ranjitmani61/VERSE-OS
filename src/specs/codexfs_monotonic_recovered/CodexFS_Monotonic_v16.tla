------------------------------- MODULE CodexFS_Monotonic_v16 -------------------------------
(* RECOVERED RECONSTRUCTION: original v16 was not present in Docker or local archives.
 * Rebuilt from surviving v12 snapshot-lock semantics as the nearest predecessor to v18.
 * 
 * CodexFS_Monotonic v16 — Recovered snapshot-locked validation lineage
 *
 * Engineering goal:
 * - User mutations remain interleaved with kernel work.
 * - The kernel validates a frozen snapshot, not the live log entry.
 * - lock_index prevents TOCTOU on the block currently under inspection.
 * - commit advances only after successful validation.
 *
 * This is the first version that cleanly separates:
 *   1) live mutable log
 *   2) locked kernel snapshot
 *   3) committed prefix
 *)
EXTENDS Integers, FiniteSets, Sequences

CONSTANTS MaxUserOps, MaxSysOps, HashMax
ASSUME MaxUserOps > 0 /\ MaxSysOps > 0 /\ HashMax > 1

H(prev, data) == prev * HashMax + data + 1

VARIABLES
    log,
    commit_index,
    validated_index,
    lock_index,
    kernel_buffer,
    user_ops,
    sys_ops

vars ==
    <<log, commit_index, validated_index, lock_index, kernel_buffer, user_ops, sys_ops>>

ValidPrefix(i) ==
    i = 1 \/ log[i][2] = H(log[i-1][2], log[i][1])

Init ==
    /\ log             = << <<0, H(0, 0)>> >>
    /\ commit_index    = 1
    /\ validated_index = 1
    /\ lock_index      = 0
    /\ kernel_buffer   = << >>
    /\ user_ops        = MaxUserOps
    /\ sys_ops         = MaxSysOps

(* ─────────────────────────── USER / ADVERSARY ─────────────────────────── *)

UserAppend(data) ==
    /\ user_ops > 0
    /\ data \in 0..HashMax-1
    /\ LET prev_hash == log[Len(log)][2]
           new_hash  == H(prev_hash, data)
       IN  /\ log' = Append(log, <<data, new_hash>>)
           /\ user_ops' = user_ops - 1
           /\ UNCHANGED <<commit_index, validated_index, lock_index, kernel_buffer, sys_ops>>

UserTamper(i, new_data) ==
    /\ user_ops > 0
    /\ i > validated_index
    /\ i /= lock_index
    /\ i <= Len(log)
    /\ new_data \in 0..HashMax-1
    /\ new_data # log[i][1]
    /\ log' = [log EXCEPT ![i] = <<new_data, log[i][2]>>]
    /\ user_ops' = user_ops - 1
    /\ UNCHANGED <<commit_index, validated_index, lock_index, kernel_buffer, sys_ops>>

(* ─────────────────────────── KERNEL SNAPSHOT PIPELINE ─────────────────────────── *)

KernelLoad ==
    /\ lock_index = 0
    /\ sys_ops > 0
    /\ validated_index < Len(log)
    /\ LET idx == validated_index + 1
       IN  /\ lock_index' = idx
           /\ kernel_buffer' = << idx, log[idx - 1][2], log[idx][1], log[idx][2] >>
           /\ UNCHANGED <<log, commit_index, validated_index, user_ops, sys_ops>>

KernelValidate_Success ==
    /\ lock_index > 0
    /\ sys_ops > 0
    /\ Len(kernel_buffer) = 4
    /\ kernel_buffer[1] = lock_index
    /\ kernel_buffer[4] = H(kernel_buffer[2], kernel_buffer[3])
    /\ validated_index' = lock_index
    /\ lock_index' = 0
    /\ kernel_buffer' = << >>
    /\ sys_ops' = sys_ops - 1
    /\ UNCHANGED <<log, commit_index, user_ops>>

KernelValidate_Fail ==
    /\ lock_index > 0
    /\ sys_ops > 0
    /\ Len(kernel_buffer) = 4
    /\ kernel_buffer[1] = lock_index
    /\ kernel_buffer[4] # H(kernel_buffer[2], kernel_buffer[3])
    /\ lock_index' = 0
    /\ kernel_buffer' = << >>
    /\ sys_ops' = sys_ops - 1
    /\ UNCHANGED <<log, commit_index, validated_index, user_ops>>

KernelCommit ==
    /\ lock_index = 0
    /\ validated_index > commit_index
    /\ commit_index' = validated_index
    /\ UNCHANGED <<log, validated_index, lock_index, kernel_buffer, user_ops, sys_ops>>

Halt ==
    /\ user_ops = 0
    /\ sys_ops = 0
    /\ lock_index = 0
    /\ commit_index = validated_index
    /\ validated_index = Len(log)
    /\ UNCHANGED vars

(* ─────────────────────────── INVARIANTS ─────────────────────────── *)

TypeOK ==
    /\ commit_index    \in 1..Len(log)
    /\ validated_index \in 1..Len(log)
    /\ lock_index      \in 0..Len(log)
    /\ validated_index >= commit_index
    /\ user_ops \in 0..MaxUserOps
    /\ sys_ops  \in 0..MaxSysOps
    /\ (lock_index = 0 => kernel_buffer = << >>)
    /\ (lock_index > 0 =>
          /\ Len(kernel_buffer) = 4
          /\ kernel_buffer[1] = lock_index
          /\ kernel_buffer[2] = log[lock_index - 1][2]
          /\ kernel_buffer[3] = log[lock_index][1]
          /\ kernel_buffer[4] = log[lock_index][2])

Safety ==
    \A i \in 2..commit_index : ValidPrefix(i)

ValidationSafety ==
    \A i \in 2..validated_index : ValidPrefix(i)

TamperContainment ==
    \A i \in 2..Len(log) :
        ~ValidPrefix(i) => validated_index < i /\ commit_index < i

Monotonicity ==
    /\ [][commit_index'    >= commit_index]_vars
    /\ [][validated_index' >= validated_index]_vars

(* ─────────────────────────── SPEC ─────────────────────────── *)

KernelStep ==
    \/ KernelCommit
    \/ KernelValidate_Success
    \/ KernelValidate_Fail
    \/ KernelLoad

Next ==
    \/ \E d \in 0..HashMax-1 : UserAppend(d)
    \/ \E i \in 1..Len(log) : \E d \in 0..HashMax-1 : UserTamper(i, d)
    \/ KernelStep
    \/ Halt

Spec ==
    Init /\ [][Next]_vars /\ WF_vars(KernelStep)

THEOREM Spec => []Safety
THEOREM Spec => []ValidationSafety
THEOREM Spec => []TamperContainment
=============================================================================