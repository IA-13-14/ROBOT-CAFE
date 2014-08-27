;######## MODULE: Actions Planner Module
; Description:
;
;

;/---------------------------------------------------------------------------------------------------/
;/*****   Trasformazione delle azioni complesse della pianificazione in azioni elementari       *****/
;/---------------------------------------------------------------------------------------------------/
(defmodule ACTIONS-PLANNER (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !

; Initilization
(defrule init-rule
    (declare (salience 100))
    (not (ACTIONS-PLANNER__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (ACTIONS-PLANNER__init)) 
        (assert (runonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::ACTIONS-PLANNER") (verbosity 2) (text  "ACTIONS-PLANNER Module invoked")))
        (assert (actions-seq 0))
)

;End runonce section
(defrule stop-runonce
    ?f <- (runonce)
    =>
    (retract ?f)
)

;### DECODE Action Goto ###
(defrule decode-Goto
    ?f <- (ACTIONS-PLANNER-decode-action (action Goto) (param1 ?d-r) (param2 ?d-c))
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?r) (pos-c ?c) (direction ?dir))
    =>
        (retract ?f)
        ;calcolo percorso con PATH_PLANNER
        (assert (start-path-planning (source-direction ?dir) (source-r ?r) (source-c ?c)
                                 (dest-direction any) (dest-r ?d-r) (dest-c ?d-c)))
        (focus PATH-PLANNER)
        (assert (decoding Goto ?d-r ?d-c))
)

;there is no path to a target access-cell
(defrule path-planner-result-no-ac
    (declare (salience 50))
    ?f <- (decoding Goto ?d-r ?d-c)
    (path-planning-result (success no))
    ?ac <- (access-cell (pos-r ?d-r) (pos-c ?d-c) (reachable yes))
    =>
        (modify ?ac (reachable no))
        (halt);DEBUG
)

(defrule path-planner-result-no
    (declare (salience 49))
    ?f <- (decoding Goto ?d-r ?d-c)
    (path-planning-result (success no))
    (K-agent (step ?s) (pos-r ?r) (pos-c ?c) (direction ?dir))
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::ACTIONS-PLANNER") (verbosity 2) (text  "No path from (%p1,%p2-%p3) to (%p4,%p5)") (param1 ?r) (param2 ?c) (param3 ?dir) (param4 ?d-r) (param5 ?d-c)))
        (assert (ACTIONS-PLANNER-decode-action-result (result no)))
        (retract ?f)
)

(deffunction pp-oper-decode (?oper)
    (switch ?oper
      (case fwd-up then Forward)
      (case fwd-down then Forward)
      (case fwd-left then Forward)
      (case fwd-right then Forward)
      (case turn-left then Turnleft)
      (case turn-right then Turnright)
    )
)

(defrule path-planner-result-yes
    (declare (salience 48))
    (decoding Goto $?)
    ?f <- (actions-seq ?seq)
    (path-planning-result (success yes))
    (path-planning-action (sequence ?seq) (operator ?oper))
    =>
        (assert (basic-action (seq ?seq) (action (pp-oper-decode ?oper))))
        (retract ?f)
        (assert (actions-seq (+ 1 ?seq)))
)

(defrule decode-Goto-clean-1
    (declare (salience -5))
    ?f <- (path-planning-result)
    =>
        (retract ?f)      
)

(defrule decode-Goto-clean-2
    (declare (salience -6))
    ?f <- (path-planning-action (sequence ?seq) (operator ?oper))
    =>
        (retract ?f)
)

(defrule decode-Goto-end
    (declare (salience -10))
    ?f <- (decoding Goto $?)
    =>
        (retract ?f)
)
;End -- ### DECODE Action Goto ###

;### DECODE Action LoadDrink-LoadFood-DeliveryDrink-DeliveryFood ###
(defrule decode-LoadDrink-LoadFood-DeliveryDrink-DeliveryFood
    ?f <- (ACTIONS-PLANNER-decode-action (action ?action&LoadDrink|LoadFood|DeliveryDrink|DeliveryFood) (param1 ?r) (param2 ?c) (param3 ?qty))
    =>
        (retract ?f)
        (assert (decoding ?action ?r ?c ?qty))
)

;Decode requested quantity
(defrule decode-LoadDrink-LoadFood-DeliveryDrink-DeliveryFood-1
    ?f <- (decoding ?action&LoadDrink|LoadFood|DeliveryDrink|DeliveryFood ?r ?c ?qty&:(> ?qty 0))
    ?f1 <- (actions-seq ?seq)
    =>
        (assert (basic-action (seq ?seq) (action ?action) (param1 ?r) (param2 ?c)))
        (retract ?f)
        (retract ?f1)
        (assert (actions-seq (+ 1 ?seq)))        
        (assert (decoding ?action ?r ?c (- ?qty 1)))
)
;### DECODE Action LoadDrink-LoadFood-DeliveryDrink-DeliveryFood ###

(deffunction EmptyDrink-oper-decode (?oper)
    (switch ?oper
      (case EmptyDrink then Release)
      (case EmptyFood then EmptyFood)
      (case CleanTable then CleanTable)      
    )
)

;Decode CleanTable
(defrule decode-CleanTable-EmptyFood-EmptyDrink
    ?f <- (ACTIONS-PLANNER-decode-action (action ?action&CleanTable|EmptyFood|EmptyDrink) (param1 ?r) (param2 ?c) (param3 ?qty))
    =>
        (assert (basic-action (seq 0) (action (EmptyDrink-oper-decode ?action)) (param1 ?r) (param2 ?c)))
        (retract ?f)
)

;Clean up
(defrule clean
    (declare (salience -90))
    ?f <- (actions-seq ?seq)
    =>
        (retract ?f)
)

;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (ACTIONS-PLANNER__init)
    =>
        (retract ?f)
        (pop-focus)
)