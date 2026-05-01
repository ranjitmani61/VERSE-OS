------------------------------- MODULE Recovery_Task -------------------------------
EXTENDS Naturals

CONSTANTS MaxMisses, MaxRestarts
ASSUME MaxMisses > 0 /\ MaxRestarts > 0

\* This specification models the current VERSE OS recovery path only.
\* Recovery is cooperative: Watchdog can detect heartbeat loss, ProcMan can
\* publish a restart_flag, but the worker reaches RESTARTING/RUNNING only if it
\* voluntarily checks that flag. There is no seL4_TCB_Suspend, CSpace revoke, or
\* VSpace teardown in this baseline model.

WorkerStates == {"RUNNING", "DEAD", "RESTARTING"}
WatchdogStates == {"MONITORING", "DETECTED", "REARMING"}
ProcManStates == {"IDLE", "SIGNALING"}

VARIABLES
    worker_state,
    watchdog_state,
    procman_state,
    heartbeat,
    last_heartbeat,
    missed_polls,
    restart_flag,
    restart_count,
    worker_checks_flag

Vars ==
    << worker_state, watchdog_state, procman_state,
       heartbeat, last_heartbeat, missed_polls,
       restart_flag, restart_count, worker_checks_flag >>

Init ==
    /\ worker_state = "RUNNING"
    /\ watchdog_state = "MONITORING"
    /\ procman_state = "IDLE"
    /\ heartbeat = 0
    /\ last_heartbeat = 0
    /\ missed_polls = 0
    /\ restart_flag = FALSE
    /\ restart_count = 0
    /\ worker_checks_flag = FALSE

TypeOK ==
    /\ worker_state \in WorkerStates
    /\ watchdog_state \in WatchdogStates
    /\ procman_state \in ProcManStates
    /\ heartbeat \in Nat
    /\ last_heartbeat \in Nat
    /\ missed_polls \in 0..MaxMisses
    /\ restart_flag \in BOOLEAN
    /\ restart_count \in 0..MaxRestarts
    /\ worker_checks_flag \in BOOLEAN

WorkerTick ==
    /\ worker_state = "RUNNING"
    /\ heartbeat' = heartbeat + 1
    /\ worker_checks_flag' = FALSE
    /\ UNCHANGED << worker_state, watchdog_state, procman_state,
                    last_heartbeat, missed_polls, restart_flag, restart_count >>

WorkerHang ==
    /\ worker_state = "RUNNING"
    /\ worker_state' = "DEAD"
    /\ UNCHANGED << watchdog_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_flag, restart_count, worker_checks_flag >>

WatchdogObserveAlive ==
    /\ watchdog_state = "MONITORING"
    /\ heartbeat # last_heartbeat
    /\ last_heartbeat' = heartbeat
    /\ missed_polls' = 0
    /\ UNCHANGED << worker_state, procman_state, heartbeat,
                    restart_flag, restart_count, worker_checks_flag >>

WatchdogMiss ==
    /\ watchdog_state = "MONITORING"
    /\ worker_state = "DEAD"
    /\ heartbeat = last_heartbeat
    /\ missed_polls < MaxMisses
    /\ missed_polls' = missed_polls + 1
    /\ UNCHANGED << worker_state, watchdog_state, procman_state,
                    heartbeat, last_heartbeat, restart_flag,
                    restart_count, worker_checks_flag >>

WatchdogDetect ==
    /\ watchdog_state = "MONITORING"
    /\ worker_state = "DEAD"
    /\ missed_polls = MaxMisses
    /\ watchdog_state' = "DETECTED"
    /\ UNCHANGED << worker_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_flag, restart_count, worker_checks_flag >>

ProcManSignal ==
    /\ watchdog_state = "DETECTED"
    /\ procman_state = "IDLE"
    /\ restart_count < MaxRestarts
    /\ procman_state' = "SIGNALING"
    /\ restart_flag' = TRUE
    /\ restart_count' = restart_count + 1
    /\ UNCHANGED << worker_state, watchdog_state, heartbeat, last_heartbeat,
                    missed_polls, worker_checks_flag >>

WorkerCheckRestartFlag ==
    /\ worker_state = "DEAD"
    /\ procman_state = "SIGNALING"
    /\ restart_flag = TRUE
    /\ worker_state' = "RESTARTING"
    /\ worker_checks_flag' = TRUE
    /\ UNCHANGED << watchdog_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_flag, restart_count >>

WorkerReinitialize ==
    /\ worker_state = "RESTARTING"
    /\ worker_checks_flag = TRUE
    /\ heartbeat' = heartbeat + 1
    /\ last_heartbeat' = heartbeat + 1
    /\ missed_polls' = 0
    /\ restart_flag' = FALSE
    /\ worker_state' = "RUNNING"
    /\ watchdog_state' = "REARMING"
    /\ procman_state' = "IDLE"
    /\ worker_checks_flag' = FALSE
    /\ UNCHANGED restart_count

WatchdogRearm ==
    /\ watchdog_state = "REARMING"
    /\ watchdog_state' = "MONITORING"
    /\ UNCHANGED << worker_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_flag, restart_count, worker_checks_flag >>

Next ==
    \/ WorkerTick
    \/ WorkerHang
    \/ WatchdogObserveAlive
    \/ WatchdogMiss
    \/ WatchdogDetect
    \/ ProcManSignal
    \/ WorkerCheckRestartFlag
    \/ WorkerReinitialize
    \/ WatchdogRearm

\* Honest baseline liveness target. This depends on fairness for the worker's
\* own flag check; a compromised or hard-hung worker can violate it.
CooperativeRecovery == worker_state = "DEAD" ~> worker_state = "RUNNING"

Spec ==
    /\ Init
    /\ [][Next]_Vars
    /\ WF_Vars(WatchdogDetect)
    /\ WF_Vars(ProcManSignal)
    /\ WF_Vars(WorkerCheckRestartFlag)
    /\ WF_Vars(WorkerReinitialize)
    /\ WF_Vars(WatchdogRearm)

THEOREM Spec => []TypeOK
=============================================================================
