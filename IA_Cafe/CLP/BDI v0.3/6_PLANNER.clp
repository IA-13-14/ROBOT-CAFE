;######## MODULE: Belief Updater Module
; Description:
;
;

;TODO: Replace PATH-PLANNER with the name of the module

;/-----------------------------------------------------------------------------------/
;/*****    GESTIONE PERCEZIONI AMBIENTE (e aggiornamento opportuni fatti)       *****/
;/-----------------------------------------------------------------------------------/
(defmodule PLANNER (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !


;Initilization
(defrule PLANNER__init-rule
    (declare (salience 100))
    (not (PLANNER__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (PLANNER__init)) 
        (assert (PLANNER__runonce))
        (assert (PLANNER__planonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "PLANNER Module invoked")))
        (halt)
)

;runonce section


;End runonce section
(defrule stop-runonce
    ?f <- (PLANNER__runonce)
    =>
    (retract ?f)
)

;Static test to satisfy first order
(defrule static-order-T4
    ?f <- (PLANNER__planonce)
    (intention  (table T4)
                (type order)
                (order ?ordid)
    )
    (order  (req-id ?ordid)            
            (table ?tab)    
            (food ?food)
            (drink ?drink)
    )
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 order) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (assert (plan-action (seq 0) (action Goto) (param1 7) (param2 6)))
        (assert (plan-action (seq 1) (action LoadFood) (param1 7) (param2 5) (param3 1)))
        (assert (plan-action (seq 2) (action LoadDrink) (param1 7) (param2 7) (param3 1)))
        (assert (plan-action (seq 3) (action Goto) (param1 6) (param2 6)))
        (assert (plan-action (seq 4) (action DeliveryFood) (param1 5) (param2 6) (param3 1)))
        (assert (plan-action (seq 5) (action DeliveryDrink) (param1 5) (param2 6) (param3 1)))
        (assert (plan-action (seq 6) (action Goto) (param1 7) (param2 6)))
        (retract ?f)
)

;Static discard other orders
(defrule static-discard-orders
    ?f <- (PLANNER__planonce)
    (intention  (table ?tab)
                (type order)
                (order ?ordid)
    )    
    (order  (req-id ?ordid)            
            (table ?tab)    
            (food ?food)
            (drink ?drink)
    )
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Discared order for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 order) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (retract ?f)
)

;Static test to satisfy first clean request
(defrule static-clean-T4
    ?f <- (PLANNER__planonce)
    (intention  (table ?tab)
                (type clean)
                
    )
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2)") (param1 order) (param2 ?tab)))
        (assert (plan-action (seq 0) (action Goto) (param1 6) (param2 6)))
        (assert (plan-action (seq 1) (action CleanTable) (param1 5) (param2 6)))
        (assert (plan-action (seq 2) (action Goto) (param1 8) (param2 6)))
        (assert (plan-action (seq 3) (action EmptyFood) (param1 8) (param2 5)))
        (assert (plan-action (seq 4) (action EmptyDrink) (param1 8) (param2 7)))   
        (retract ?f)
)

;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (PLANNER__init)
    =>
        (retract ?f)
        (pop-focus)
)