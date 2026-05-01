-------------------------- MODULE CortexMM_Capability -------------------------
EXTENDS Naturals, FiniteSets

CONSTANTS Clients, Pages
ASSUME Clients # {} /\ Pages # {}

VARIABLES granted, accesses

Init ==
    /\ granted = [c \in Clients |-> {}]
    /\ accesses = {}

Grant(c, p) ==
    /\ c \in Clients
    /\ p \in Pages
    /\ granted' = [granted EXCEPT ![c] = @ \cup {p}]
    /\ UNCHANGED accesses

Access(c, p) ==
    /\ c \in Clients
    /\ p \in granted[c]
    /\ accesses' = accesses \cup {<<c, p>>}
    /\ UNCHANGED granted

Next ==
    \/ \E c \in Clients, p \in Pages : Grant(c, p)
    \/ \E c \in Clients, p \in Pages : Access(c, p)

NoIllegalAccess ==
    \A a \in accesses : a[2] \in granted[a[1]]

Spec == Init /\ [][Next]_<<granted, accesses>>

THEOREM Spec => []NoIllegalAccess
=============================================================================

