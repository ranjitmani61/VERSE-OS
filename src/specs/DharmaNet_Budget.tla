---------------------------- MODULE DharmaNet_Budget --------------------------
EXTENDS Naturals

CONSTANTS BudgetA, BudgetB, MaxUse
ASSUME BudgetA > 0 /\ BudgetB > 0 /\ MaxUse > 0

VARIABLES useA, useB, severity

OK == 0
WARN == 1
CRIT == 2

Init ==
    /\ useA = 0
    /\ useB = 0
    /\ severity = OK

Observe(a, b) ==
    /\ a \in 0..MaxUse
    /\ b \in 0..MaxUse
    /\ useA' = a
    /\ useB' = b
    /\ severity' =
        IF a > BudgetA \/ b > BudgetB
        THEN CRIT
        ELSE IF (a * 100 > BudgetA * 80) \/ (b * 100 > BudgetB * 80)
             THEN WARN
             ELSE OK

Next == \E a \in 0..MaxUse, b \in 0..MaxUse : Observe(a, b)

BudgetViolationFlagged ==
    (useA > BudgetA \/ useB > BudgetB) => severity = CRIT

Spec == Init /\ [][Next]_<<useA, useB, severity>>

THEOREM Spec => []BudgetViolationFlagged
=============================================================================

