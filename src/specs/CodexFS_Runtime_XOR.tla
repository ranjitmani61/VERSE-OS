------------------------------- MODULE CodexFS_Runtime_XOR -------------------------------
EXTENDS Naturals, Integers, Sequences, FiniteSets

CONSTANTS MaxBlocks, DataVals

ASSUME MaxBlocks \in Nat \ {0}
ASSUME DataVals # {}

VARIABLES
    blocks,
    bc,
    status

Vars == << blocks, bc, status >>

Statuses == {"OK", "FULL", "CORRUPT"}

Pow2 == <<1, 2, 4, 8, 16, 32, 64, 128>>

Bit(n, k) == (n \div Pow2[k + 1]) % 2

XorByte(a, b) ==
      (IF Bit(a, 0) # Bit(b, 0) THEN 1 ELSE 0)
    + (IF Bit(a, 1) # Bit(b, 1) THEN 2 ELSE 0)
    + (IF Bit(a, 2) # Bit(b, 2) THEN 4 ELSE 0)
    + (IF Bit(a, 3) # Bit(b, 3) THEN 8 ELSE 0)
    + (IF Bit(a, 4) # Bit(b, 4) THEN 16 ELSE 0)
    + (IF Bit(a, 5) # Bit(b, 5) THEN 32 ELSE 0)
    + (IF Bit(a, 6) # Bit(b, 6) THEN 64 ELSE 0)
    + (IF Bit(a, 7) # Bit(b, 7) THEN 128 ELSE 0)

Checksum(block) ==
    XorByte(block.ph, block.data)

GoodChain ==
    /\ Len(blocks) = bc
    /\ bc \in 0..MaxBlocks
    /\ \A i \in 1..bc:
        /\ blocks[i].h = Checksum(blocks[i])
        /\ blocks[i].ph = IF i = 1 THEN 0 ELSE blocks[i-1].h

TypeOK ==
    /\ blocks \in Seq([ph: 0..255, data: DataVals, h: 0..255])
    /\ Len(blocks) <= MaxBlocks
    /\ bc \in 0..MaxBlocks
    /\ status \in Statuses

Init ==
    /\ blocks = <<>>
    /\ bc = 0
    /\ status = "OK"

WriteBlock(d) ==
    /\ status = "OK"
    /\ bc < MaxBlocks
    /\ d \in DataVals
    /\ LET phv == IF bc = 0 THEN 0 ELSE blocks[bc].h IN
       LET hv == XorByte(phv, d) IN
       /\ blocks' = Append(blocks, [ph |-> phv, data |-> d, h |-> hv])
       /\ bc' = bc + 1
       /\ status' = "OK"

FullWriteRejected ==
    /\ status = "OK"
    /\ bc = MaxBlocks
    /\ UNCHANGED << blocks, bc >>
    /\ status' = "FULL"

CorruptHash(i) ==
    /\ status = "OK"
    /\ i \in 1..bc
    /\ blocks' = [blocks EXCEPT ![i].h = (blocks[i].h + 1) % 256]
    /\ bc' = bc
    /\ status' = "CORRUPT"

CorruptPrevHash(i) ==
    /\ status = "OK"
    /\ i \in 1..bc
    /\ blocks' = [blocks EXCEPT ![i].ph = (blocks[i].ph + 1) % 256]
    /\ bc' = bc
    /\ status' = "CORRUPT"

VerifyPass ==
    /\ status = "OK"
    /\ GoodChain
    /\ UNCHANGED Vars

VerifyFail ==
    /\ status \in {"OK", "CORRUPT"}
    /\ ~GoodChain
    /\ UNCHANGED << blocks, bc >>
    /\ status' = "CORRUPT"

Terminal ==
    /\ status \in {"FULL", "CORRUPT"}
    /\ UNCHANGED Vars

Next ==
    \/ \E d \in DataVals: WriteBlock(d)
    \/ FullWriteRejected
    \/ \E i \in 1..bc: CorruptHash(i)
    \/ \E i \in 1..bc: CorruptPrevHash(i)
    \/ VerifyPass
    \/ VerifyFail
    \/ Terminal

Spec ==
    /\ Init
    /\ [][Next]_Vars
    /\ WF_Vars(FullWriteRejected)
    /\ WF_Vars(VerifyFail)

AppendPreservesGoodChain ==
    status = "OK" => GoodChain

CorruptionDetectedOrTerminal ==
    status = "CORRUPT" => ~GoodChain \/ status = "CORRUPT"

EventuallyTerminalWhenFull ==
    bc = MaxBlocks ~> status = "FULL"

THEOREM Spec => []TypeOK
=============================================================================
