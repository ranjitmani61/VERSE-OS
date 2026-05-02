------------------------------- MODULE Recovery_TCB -------------------------------
EXTENDS Naturals

CONSTANTS TCBMaxMisses, TCBMaxRestarts
ASSUME TCBMaxMisses > 0 /\ TCBMaxRestarts > 0

\* TCB refinement model for the native seL4 path under implementation.
\* This module models forced recovery authority. Unlike Recovery_Task, the
\* worker does not need to read restart_flag for recovery to advance after
\* ProcMan has the worker TCB cap.
\*
\* The refinement mapping below is a proof obligation. It has been structured
\* so TCB_SUSPEND maps to the abstract ProcManSignal step, ResourceRevoke maps
\* to the abstract WorkerCheckRestartFlag step, FreshTCB stutters, and
\* ResumeFreshTCB maps to WorkerReinitialize. This file does not contain a
\* completed TLAPS proof.

TCBWorkerStates == {"RUNNING", "DEAD", "SUSPENDED", "REVOKING", "FRESH", "ESCALATED"}
TCBWatchdogStates == {"MONITORING", "DETECTED", "REARMING"}
TCBProcManStates == {"IDLE", "SUSPENDING", "REVOKING", "FRESH"}

WorkerStates == {"RUNNING", "DEAD", "RESTARTING", "ESCALATED"}
WatchdogStates == {"MONITORING", "DETECTED", "REARMING"}
ProcManStates == {"IDLE", "SIGNALING"}

VARIABLES
    worker_state,
    watchdog_state,
    procman_state,
    heartbeat,
    last_heartbeat,
    missed_polls,
    restart_count,
    fault_endpoint_fired,
    worker_tcb_live,
    resources_revoked,
    fresh_tcb_ready

TCBVars ==
    << worker_state, watchdog_state, procman_state,
       heartbeat, last_heartbeat, missed_polls, restart_count,
       fault_endpoint_fired, worker_tcb_live, resources_revoked,
       fresh_tcb_ready >>

TCBInit ==
    /\ worker_state = "RUNNING"
    /\ watchdog_state = "MONITORING"
    /\ procman_state = "IDLE"
    /\ heartbeat = 0
    /\ last_heartbeat = 0
    /\ missed_polls = 0
    /\ restart_count = 0
    /\ fault_endpoint_fired = FALSE
    /\ worker_tcb_live = TRUE
    /\ resources_revoked = FALSE
    /\ fresh_tcb_ready = FALSE

TCBTypeOK ==
    /\ worker_state \in TCBWorkerStates
    /\ watchdog_state \in TCBWatchdogStates
    /\ procman_state \in TCBProcManStates
    /\ heartbeat \in Nat
    /\ last_heartbeat \in Nat
    /\ missed_polls \in 0..TCBMaxMisses
    /\ restart_count \in 0..TCBMaxRestarts
    /\ fault_endpoint_fired \in BOOLEAN
    /\ worker_tcb_live \in BOOLEAN
    /\ resources_revoked \in BOOLEAN
    /\ fresh_tcb_ready \in BOOLEAN

\* TLC-only bounded exploration constraint for the TCB refinement model.
TCBStateConstraint ==
    /\ heartbeat \in 0..3
    /\ last_heartbeat \in 0..3
    /\ missed_polls \in 0..TCBMaxMisses
    /\ restart_count \in 0..TCBMaxRestarts

TCBWorkerTick ==
    /\ worker_state = "RUNNING"
    /\ worker_tcb_live
    /\ heartbeat' = heartbeat + 1
    /\ fault_endpoint_fired' = FALSE
    /\ resources_revoked' = FALSE
    /\ fresh_tcb_ready' = FALSE
    /\ UNCHANGED << worker_state, watchdog_state, procman_state,
                    last_heartbeat, missed_polls, restart_count,
                    worker_tcb_live >>

TCBWorkerHang ==
    /\ worker_state = "RUNNING"
    /\ worker_state' = "DEAD"
    /\ fault_endpoint_fired' = FALSE
    /\ UNCHANGED << watchdog_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, worker_tcb_live,
                    resources_revoked, fresh_tcb_ready >>

TCBWorkerFault ==
    /\ worker_state = "RUNNING"
    /\ worker_state' = "DEAD"
    /\ fault_endpoint_fired' = TRUE
    /\ UNCHANGED << watchdog_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, worker_tcb_live,
                    resources_revoked, fresh_tcb_ready >>

TCBWatchdogObserveAlive ==
    /\ watchdog_state = "MONITORING"
    /\ heartbeat # last_heartbeat
    /\ last_heartbeat' = heartbeat
    /\ missed_polls' = 0
    /\ UNCHANGED << worker_state, watchdog_state, procman_state, heartbeat, restart_count,
                    fault_endpoint_fired, worker_tcb_live, resources_revoked,
                    fresh_tcb_ready >>

TCBWatchdogMiss ==
    /\ watchdog_state = "MONITORING"
    /\ worker_state = "DEAD"
    /\ ~fault_endpoint_fired
    /\ heartbeat = last_heartbeat
    /\ missed_polls < TCBMaxMisses
    /\ missed_polls' = missed_polls + 1
    /\ UNCHANGED << worker_state, watchdog_state, procman_state,
                    heartbeat, last_heartbeat, restart_count,
                    fault_endpoint_fired, worker_tcb_live, resources_revoked,
                    fresh_tcb_ready >>

TCBWatchdogDetect ==
    /\ watchdog_state = "MONITORING"
    /\ worker_state = "DEAD"
    /\ missed_polls = TCBMaxMisses
    /\ watchdog_state' = "DETECTED"
    /\ UNCHANGED << worker_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, fault_endpoint_fired,
                    worker_tcb_live, resources_revoked, fresh_tcb_ready >>

FaultEndpointFired ==
    /\ watchdog_state = "MONITORING"
    /\ worker_state = "DEAD"
    /\ fault_endpoint_fired
    /\ watchdog_state' = "DETECTED"
    /\ UNCHANGED << worker_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, fault_endpoint_fired,
                    worker_tcb_live, resources_revoked, fresh_tcb_ready >>

TCB_SUSPEND ==
    /\ watchdog_state = "DETECTED"
    /\ procman_state = "IDLE"
    /\ worker_state = "DEAD"
    /\ restart_count < TCBMaxRestarts
    /\ worker_state' = "SUSPENDED"
    /\ procman_state' = "SUSPENDING"
    /\ worker_tcb_live' = FALSE
    /\ restart_count' = restart_count + 1
    /\ UNCHANGED << watchdog_state, heartbeat, last_heartbeat, missed_polls,
                    fault_endpoint_fired, resources_revoked, fresh_tcb_ready >>

ResourceRevoke ==
    /\ worker_state = "SUSPENDED"
    /\ procman_state = "SUSPENDING"
    /\ worker_state' = "REVOKING"
    /\ procman_state' = "REVOKING"
    /\ resources_revoked' = TRUE
    /\ UNCHANGED << watchdog_state, heartbeat, last_heartbeat, missed_polls,
                    restart_count, fault_endpoint_fired, worker_tcb_live,
                    fresh_tcb_ready >>

FreshTCB ==
    /\ worker_state = "REVOKING"
    /\ procman_state = "REVOKING"
    /\ resources_revoked
    /\ worker_state' = "FRESH"
    /\ procman_state' = "FRESH"
    /\ worker_tcb_live' = TRUE
    /\ fresh_tcb_ready' = TRUE
    /\ UNCHANGED << watchdog_state, heartbeat, last_heartbeat, missed_polls,
                    restart_count, fault_endpoint_fired, resources_revoked >>

ResumeFreshTCB ==
    /\ worker_state = "FRESH"
    /\ procman_state = "FRESH"
    /\ worker_tcb_live
    /\ fresh_tcb_ready
    /\ worker_state' = "RUNNING"
    /\ watchdog_state' = "REARMING"
    /\ procman_state' = "IDLE"
    /\ heartbeat' = heartbeat + 1
    /\ last_heartbeat' = heartbeat + 1
    /\ missed_polls' = 0
    /\ fault_endpoint_fired' = FALSE
    /\ resources_revoked' = FALSE
    /\ fresh_tcb_ready' = FALSE
    /\ UNCHANGED << restart_count, worker_tcb_live >>

TCBWatchdogRearm ==
    /\ watchdog_state = "REARMING"
    /\ watchdog_state' = "MONITORING"
    /\ UNCHANGED << worker_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, fault_endpoint_fired,
                    worker_tcb_live, resources_revoked, fresh_tcb_ready >>

TCBEscalate ==
    /\ worker_state = "DEAD"
    /\ watchdog_state = "DETECTED"
    /\ procman_state = "IDLE"
    /\ restart_count = TCBMaxRestarts
    /\ worker_state' = "ESCALATED"
    /\ UNCHANGED << watchdog_state, procman_state, heartbeat, last_heartbeat,
                    missed_polls, restart_count, fault_endpoint_fired,
                    worker_tcb_live, resources_revoked, fresh_tcb_ready >>

TCBTerminal ==
    /\ worker_state = "ESCALATED"
    /\ UNCHANGED TCBVars

TCBNext ==
    \/ TCBWorkerTick
    \/ TCBWorkerHang
    \/ TCBWorkerFault
    \/ TCBWatchdogObserveAlive
    \/ TCBWatchdogMiss
    \/ TCBWatchdogDetect
    \/ FaultEndpointFired
    \/ TCB_SUSPEND
    \/ ResourceRevoke
    \/ FreshTCB
    \/ ResumeFreshTCB
    \/ TCBWatchdogRearm
    \/ TCBEscalate
    \/ TCBTerminal

AbsWorkerState ==
    IF worker_state = "RUNNING" THEN "RUNNING"
    ELSE IF worker_state = "ESCALATED" THEN "ESCALATED"
    ELSE IF worker_state = "SUSPENDED" THEN "DEAD"
    ELSE IF worker_state \in {"REVOKING", "FRESH"} THEN "RESTARTING"
    ELSE "DEAD"

AbsWatchdogState == watchdog_state
AbsProcManState == IF procman_state = "IDLE" THEN "IDLE" ELSE "SIGNALING"
AbsRestartFlag == worker_state \in {"SUSPENDED", "REVOKING", "FRESH"}
AbsWorkerChecksFlag == worker_state \in {"REVOKING", "FRESH"}

RefinementMapping ==
    [ worker_state |-> AbsWorkerState,
      watchdog_state |-> AbsWatchdogState,
      procman_state |-> AbsProcManState,
      heartbeat |-> heartbeat,
      last_heartbeat |-> last_heartbeat,
      missed_polls |-> missed_polls,
      restart_flag |-> AbsRestartFlag,
      restart_count |-> restart_count,
      worker_checks_flag |-> AbsWorkerChecksFlag ]

TCBSpec ==
    /\ TCBInit
    /\ [][TCBNext]_TCBVars
    /\ WF_TCBVars(TCBWatchdogObserveAlive)
    /\ WF_TCBVars(TCBWatchdogMiss)
    /\ WF_TCBVars(TCBWatchdogDetect)
    /\ WF_TCBVars(FaultEndpointFired)
    /\ WF_TCBVars(TCB_SUSPEND)
    /\ WF_TCBVars(ResourceRevoke)
    /\ WF_TCBVars(FreshTCB)
    /\ WF_TCBVars(ResumeFreshTCB)
    /\ WF_TCBVars(TCBWatchdogRearm)
    /\ WF_TCBVars(TCBEscalate)

TCBRecoveryResolution ==
    worker_state = "DEAD" ~> (worker_state = "RUNNING" \/ worker_state = "ESCALATED")

TaskSafetyUnderRefinement ==
    /\ AbsWorkerState \in WorkerStates
    /\ AbsWatchdogState \in WatchdogStates
    /\ AbsProcManState \in ProcManStates
    /\ heartbeat \in Nat
    /\ last_heartbeat \in Nat
    /\ missed_polls \in 0..TCBMaxMisses
    /\ AbsRestartFlag \in BOOLEAN
    /\ restart_count \in 0..TCBMaxRestarts
    /\ AbsWorkerChecksFlag \in BOOLEAN

THEOREM TCBSpec => []TCBTypeOK

\* Refinement proof obligation: every Recovery_TCB behavior maps to a behavior
\* satisfying the abstract Recovery_Task safety shape. TLC can check this under
\* bounded constants; a full proof remains future TLAPS work.
THEOREM Recovery_TCB_Refines_Recovery_Task_Safety ==
    TCBSpec => []TaskSafetyUnderRefinement
=============================================================================
