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

(deftemplate planning
    (slot type (allowed-values order cleantable))
    (slot step)
    (slot pseq)
    (slot param1 (default NA))
    (slot param2 (default NA))
    (slot param3 (default NA))
    (slot param4 (default NA))
    (slot param5 (default NA))
)

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
;(defrule stop-runonce
;    ?f <- (PLANNER__runonce)
;    =>
;    (retract ?f)
;)

(deffunction manh-cost(?r ?c ?d-r ?d-c)
    (* 2 (+ (abs (- ?d-r ?r)) (abs (- ?d-c ?c)) ))
)

;#### Serve table plan ####

;Start conditional plan for serve order
(defrule serve-order-start
    ?f <- (PLANNER__runonce)
    (not (planning))
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
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 order) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (assert (planning (type order) (step 1) (pseq 0) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        ;Initializing helper planning variables        
        (assert (var loadedFood 0))
        (assert (var loadedDrink 0))
        (assert (var foodOnBoard 0))
        (assert (var drinkOnBoard 0))
        (assert (var freeSlots ?*SLOTS*))
        (assert (var tablepos ?tabr ?tabc))
        (assert (var agentPos ?ag-r ?ag-c))
)

;Planning for serve order - While A - True
;While(there are any drink or food left to serve)
(defrule serve-order-while-A-foods-or-drinks-true
    (declare (salience 100))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 1) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    (var loadedDrink ?ld)
    (var loadedFood ?lf)
    (or (test (> ?food ?lf)) (test (> ?drink ?ld)))
    =>
        (modify ?pln (step 2))
)

;Planning for serve order - While A - False
(defrule serve-order-while-A-foods-or-drinks-false
    (declare (salience 99))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 1) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        ;Nothing else to do, end the plan
        (retract ?f)
        (retract ?pln)
)

;TODO: Precedenza a food o drink o calcolo in base alle richieste ?

;Planning for serve order - If B - True
(defrule serve-order-if-foods-to-load-true
    (declare (salience 98))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vlf <- (var loadedFood ?lf)
    ?vfb <- (var foodOnBoard ?fb)
    (and (test (> ?food ?lf)) (test (> ?slots 0)))
    ;FD Best position
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object FD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
    =>
        ;Goto FD
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?r) (param2 ?c)))
        (retract ?vpos)
        (assert (var agentPos ?r ?c))
        ;Load Food (min needed and possible qty)
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 (min ?slots (- ?food ?lf)))))
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (- ?slots (min ?slots (- ?food ?lf)))))
        (retract ?vlf)
        (assert (var loadedFood (+ ?lf (min ?slots (- ?food ?lf)))))
        (retract ?vfb)
        (assert (var foodOnBoard (min ?slots (- ?food ?lf))))
        (modify ?pln (step 3) (pseq (+ 2 ?pseq)))
)

;Planning for serve order - If B - False
(defrule serve-order-if-foods-to-load-false
    (declare (salience 97))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 3))
)

;Planning for serve order - If C - True
(defrule serve-order-if-drinks-to-load-true
    (declare (salience 96))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 3) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vld <- (var loadedDrink ?ld)
    ?vdb <- (var drinkOnBoard ?db)
    (and (test (> ?drink ?ld)) (test (> ?slots 0)))
    ;DD Best position
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object DD) (obj-r ?dd-r) (obj-c ?dd-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object DD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
    =>
        ;Goto DD
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?r) (param2 ?c)))
        (retract ?vpos)
        (assert (var agentPos ?r ?c))
        ;Load Drink (min needed and possible qty)
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 (min ?slots (- ?drink ?ld)))))
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (- ?slots (min ?slots (- ?drink ?ld)))))
        (retract ?vld)
        (assert (var loadedDrink (+ ?ld (min ?slots (- ?drink ?ld)))))
        (retract ?vdb)
        (assert (var drinkOnBoard (min ?slots (- ?drink ?ld))))
        (modify ?pln (step 4) (pseq (+ 2 ?pseq)))
)

;Planning for serve order - If C - False
(defrule serve-order-if-drinks-to-load-false
    (declare (salience 95))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 3) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 4))
)

;Planning for serve order - goto Table
(defrule serve-order-goto-table
    (declare (salience 95))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 4) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    (var tablepos ?tabr ?tabc)
    ;Table Best position
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
    =>
        ;Goto Table
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?r) (param2 ?c)))  
        (retract ?vpos)
        (assert (var agentPos ?r ?c)) 
        (modify ?pln (step 5) (pseq (+ 1 ?pseq)))
)

;Planning for serve order - delivery food - true
(defrule serve-order-delivery-food-true
    (declare (salience 94))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 5) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vlf <- (var loadedFood ?lf)
    ?vfb <- (var foodOnBoard ?fb)
    (and (test (>= ?food ?lf)) (test (> ?fb 0)))
    (var tablepos ?tabr ?tabc)
    =>
        ;Delivery Food
        (assert (plan-action (seq ?pseq) (action DeliveryFood) (param1 ?tabr) (param2 ?tabc) (param3 ?fb)))
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (+ ?slots ?fb)))
        (retract ?vfb)
        (assert (var foodOnBoard 0))
        (modify ?pln (step 6) (pseq (+ 1 ?pseq)))
)

;Planning for serve order - delivery food - false
(defrule serve-order-delivery-food-false
    (declare (salience 93))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 5) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 6))
)

;Planning for serve order - delivery drink - true
(defrule serve-order-delivery-drink-true
    (declare (salience 92))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 6) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vld <- (var loadedDrink ?ld)
    ?vdb <- (var drinkOnBoard ?db)
    (and (test (>= ?drink ?ld)) (test (> ?db 0)))
    (var tablepos ?tabr ?tabc)
    =>
        ;Delivery Drink
        (assert (plan-action (seq ?pseq) (action DeliveryDrink) (param1 ?tabr) (param2 ?tabc) (param3 ?db)))
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (+ ?slots ?db)))
        (retract ?vdb)
        (assert (var drinkOnBoard 0))
        (modify ?pln (step 1) (pseq (+ 1 ?pseq)))
)

;Planning for serve order - delivery drink - false
(defrule serve-order-delivery-drink-false
    (declare (salience 91))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 6) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 1))
)

;#### END - Serve table plan ####

;#### Clean table plan ####

;Static test to satisfy first clean request
(defrule static-clean-T4
    ?f <- (PLANNER__runonce)
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

;#### END - Clean table plan ####

(defrule dispose_1
    (declare (salience -99))
    ?f <- (var $?)
    =>
        (retract ?f)
)

(defrule dispose_2
    (declare (salience -99))
    ?f <- (planning)
    =>
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