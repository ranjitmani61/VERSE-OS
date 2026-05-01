--------------------------- MODULE Sentinel_Lattice ---------------------------
EXTENDS Naturals, Sequences

CONSTANTS MaxMsgs
ASSUME MaxMsgs > 0

\* SMP gap note:
\* Send and Process are modeled as serialized atomic transitions on inbox and
\* delivered. The current proof does not cover multicore dataport interleavings.
\* SMP execution needs extra constraints if multiple clients enqueue at once,
\* Process observes stale or torn queue state, delivered is updated by more than
\* one core, or label metadata can change while a message is being classified.
\* A future SMP model should define linearization points for enqueue/dequeue,
\* use acquire/release ordering on queue state, keep labels immutable or
\* versioned, and make the Process label check and delivery decision atomic.

PUBLIC == 0
INTERNAL == 1
SECRET == 2
Labels == {PUBLIC, INTERNAL, SECRET}

Allowed(src, dst) == src <= dst

VARIABLES inbox, delivered, steps

Init ==
    /\ inbox = << >>
    /\ delivered = << >>
    /\ steps = 0

Send(src, dst) ==
    /\ steps < MaxMsgs
    /\ src \in Labels
    /\ dst \in Labels
    /\ inbox' = Append(inbox, <<src, dst>>)
    /\ steps' = steps + 1
    /\ UNCHANGED delivered

Process ==
    /\ Len(inbox) > 0
    /\ LET msg == Head(inbox)
       IN /\ inbox' = Tail(inbox)
          /\ delivered' =
                IF Allowed(msg[1], msg[2])
                THEN Append(delivered, msg)
                ELSE delivered
    /\ UNCHANGED steps

Next ==
    \/ \E s \in Labels, d \in Labels : Send(s, d)
    \/ Process

NoIllegalDelivery ==
    \A i \in 1..Len(delivered) : Allowed(delivered[i][1], delivered[i][2])

Spec == Init /\ [][Next]_<<inbox, delivered, steps>>

THEOREM Spec => []NoIllegalDelivery
=============================================================================
