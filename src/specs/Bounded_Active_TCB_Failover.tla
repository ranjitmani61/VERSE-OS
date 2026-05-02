----------------------- MODULE Bounded_Active_TCB_Failover -----------------------
EXTENDS Naturals, Sequences

CONSTANT FaultBudget
ASSUME FaultBudget > 0

NoTCB == "NONE"
OriginalTCB == "0x100"
SparePool == <<"0x104", "0x109", "0x10a">>
MaxRetries == Len(SparePool)
SpareSet == {SparePool[i] : i \in 1..Len(SparePool)}
TCBSet == SpareSet \cup {OriginalTCB}

States == {
    "Running",
    "Deadlocked",
    "Suspended",
    "Recovered",
    "StableRecovered",
    "Exhausted",
    "Quarantined"
}

VARIABLES
    state,
    active_tcb,
    suspended_tcb,
    quarantined,
    used_spares,
    retry_count,
    fault_events

Vars == << state, active_tcb, suspended_tcb, quarantined, used_spares,
          retry_count, fault_events >>

UsedSpareSet == {used_spares[i] : i \in 1..Len(used_spares)}

NoDuplicateSeq(seq) ==
    \A i, j \in 1..Len(seq) : i # j => seq[i] # seq[j]

Init ==
    /\ state = "Running"
    /\ active_tcb = OriginalTCB
    /\ suspended_tcb = NoTCB
    /\ quarantined = {}
    /\ used_spares = <<>>
    /\ retry_count = 0
    /\ fault_events = 0

TypeOK ==
    /\ state \in States
    /\ active_tcb \in TCBSet \cup {NoTCB}
    /\ suspended_tcb \in TCBSet \cup {NoTCB}
    /\ quarantined \subseteq TCBSet
    /\ Len(used_spares) \in 0..MaxRetries
    /\ \A i \in 1..Len(used_spares) : used_spares[i] \in SpareSet
    /\ retry_count \in 0..MaxRetries
    /\ fault_events \in 0..FaultBudget
    /\ state = "Quarantined" => active_tcb = NoTCB
    /\ state # "Quarantined" => active_tcb \in TCBSet
    /\ state = "Suspended" => suspended_tcb \in TCBSet
    /\ state # "Suspended" => suspended_tcb = NoTCB

ActiveNotQuarantined ==
    active_tcb = NoTCB \/ active_tcb \notin quarantined

FreshUnusedSpareInvariant ==
    /\ Len(used_spares) = retry_count
    /\ UsedSpareSet \subseteq SpareSet
    /\ NoDuplicateSeq(used_spares)
    /\ \A i \in 1..Len(used_spares) : used_spares[i] = SparePool[i]

RetryCountBound ==
    retry_count <= MaxRetries

WorkerDeadlock ==
    /\ state \in {"Running", "Recovered"}
    /\ fault_events < FaultBudget
    /\ state' = "Deadlocked"
    /\ fault_events' = fault_events + 1
    /\ UNCHANGED << active_tcb, suspended_tcb, quarantined, used_spares,
                    retry_count >>

WatchdogDetectRecoverable ==
    /\ state = "Deadlocked"
    /\ retry_count < MaxRetries
    /\ active_tcb # NoTCB
    /\ state' = "Suspended"
    /\ suspended_tcb' = active_tcb
    /\ UNCHANGED << active_tcb, quarantined, used_spares, retry_count,
                    fault_events >>

ProcManRecover ==
    /\ state = "Suspended"
    /\ retry_count < MaxRetries
    /\ LET fresh == SparePool[retry_count + 1] IN
        /\ fresh \notin UsedSpareSet
        /\ state' = "Recovered"
        /\ active_tcb' = fresh
        /\ suspended_tcb' = NoTCB
        /\ quarantined' = quarantined \cup {suspended_tcb}
        /\ used_spares' = Append(used_spares, fresh)
        /\ retry_count' = retry_count + 1
        /\ UNCHANGED fault_events

MarkStableRecovered ==
    /\ state = "Recovered"
    /\ fault_events >= FaultBudget
    /\ state' = "StableRecovered"
    /\ UNCHANGED << active_tcb, suspended_tcb, quarantined, used_spares,
                    retry_count, fault_events >>

WatchdogDetectExhausted ==
    /\ state = "Deadlocked"
    /\ retry_count = MaxRetries
    /\ state' = "Exhausted"
    /\ UNCHANGED << active_tcb, suspended_tcb, quarantined, used_spares,
                    retry_count, fault_events >>

ProcManQuarantine ==
    /\ state = "Exhausted"
    /\ state' = "Quarantined"
    /\ active_tcb' = NoTCB
    /\ suspended_tcb' = NoTCB
    /\ quarantined' =
        IF active_tcb = NoTCB THEN quarantined ELSE quarantined \cup {active_tcb}
    /\ UNCHANGED << used_spares, retry_count, fault_events >>

StableTerminal ==
    /\ state = "StableRecovered"
    /\ UNCHANGED Vars

QuarantineTerminal ==
    /\ state = "Quarantined"
    /\ UNCHANGED Vars

Next ==
    \/ WorkerDeadlock
    \/ WatchdogDetectRecoverable
    \/ ProcManRecover
    \/ MarkStableRecovered
    \/ WatchdogDetectExhausted
    \/ ProcManQuarantine
    \/ StableTerminal
    \/ QuarantineTerminal

Spec ==
    /\ Init
    /\ [][Next]_Vars
    /\ WF_Vars(WorkerDeadlock)
    /\ WF_Vars(WatchdogDetectRecoverable)
    /\ WF_Vars(ProcManRecover)
    /\ WF_Vars(MarkStableRecovered)
    /\ WF_Vars(WatchdogDetectExhausted)
    /\ WF_Vars(ProcManQuarantine)

ThreeFailedCyclesQuarantine ==
    (state = "Deadlocked" /\ retry_count = MaxRetries) ~> state = "Quarantined"

ExhaustionQuarantines ==
    state = "Exhausted" ~> state = "Quarantined"

NormalRecoveryReachesStable ==
    <> (state = "StableRecovered")

THEOREM Spec => []TypeOK
THEOREM Spec => []ActiveNotQuarantined
THEOREM Spec => []FreshUnusedSpareInvariant
THEOREM Spec => []RetryCountBound
=============================================================================
