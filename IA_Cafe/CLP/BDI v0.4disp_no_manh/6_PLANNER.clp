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

;MOVED TO MAIN for loading purpose
;(deftemplate pcpc
;    (slot source-direction (allowed-values north south east west))
;    (slot source-r)
;    (slot source-c)
;    (slot dest-direction (allowed-values north south east west any))
;    (slot dest-r)
;    (slot dest-c)   
;    (slot cost) 
;)

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
        ;(assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "PLANNER Module invoked")))
        ;(halt)
)

;runonce section


;End runonce section
;(defrule stop-runonce
;    ?f <- (PLANNER__runonce)
;    =>
;    (retract ?f)
;)

(deffunction manh-cost(?r ?c ?d-r ?d-c)
    (+ (abs (- ?d-r ?r)) (abs (- ?d-c ?c)))
)

;Distance sum of object between table and current agent pos (using manhatthan cost)
(deffunction dist-btw-pos-table-manh(?ag-r ?ag-c ?tb-r ?tb-c ?ob-r ?ob-c)
    (+ ;Sum of single distances
        (manh-cost ?ag-r ?ag-c ?ob-r ?ob-c) ;Distance(pos, obj)
        (manh-cost ?tb-r ?tb-c ?ob-r ?ob-c) ;Distance(table, obj)
    )
)

;Distance sum of object between table and current agent pos
(deffunction dist-btw-pos-table(?cost-pos-obj ?cost-obj-tab)
    (+ ;Sum of single distances
        ?cost-pos-obj ;Distance(pos, obj)
        ?cost-obj-tab ;Distance(table, obj)
    )
)

;#### Beginning plan -> goto FD ####
(defrule beginning-plan-goto-FD
	(declare (salience 95))
	?f <- (PLANNER__runonce)
	(status (step ?s&:(= ?s 0)) (time ?t))	    
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	;FD Best position
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object FD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
	=>
		(assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for Beginning-plan-goto-FD")))
        (assert (plan-action (seq 0) (action Goto) (param1 ?r) (param2 ?c)))
        (retract ?f)
)

;#### Serve table plan ####

;Start conditional plan for serve order
(defrule serve-order-start
    (PLANNER__runonce)
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
;PCPC from Pos to FD not calculated yet 
(defrule serve-order-if-foods-to-load-true-find-best-FD-pcpc-calculate-from-pos-to-FD
    (declare (salience 98))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vlf <- (var loadedFood ?lf)
    ?vfb <- (var foodOnBoard ?fb)
    (and (test (> ?food ?lf)) (test (> ?slots 0)))
    ;PCPC from Pos to FD not calculated yet    
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?ag-r) (source-c ?ag-c)
                                 (dest-direction any) (dest-r ?fdac-r) (dest-c ?fdac-c)))
        (focus PCPC)
)

;PCPC from FD to Table not calculated yet 
(defrule serve-order-if-foods-to-load-true-find-best-FD-pcpc-calculate-from-FD-to-table
    (declare (salience 98))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vlf <- (var loadedFood ?lf)
    ?vfb <- (var foodOnBoard ?fb)
    (and (test (> ?food ?lf)) (test (> ?slots 0)))
    ;PCPC from Pos to FD not calculated yet    
    (var tablepos ?tb-r ?tb-c)    
    ;Table access-cell
    (access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbac-r) (pos-c ?tbac-c))
    ;FD access-cell
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?fdac-r) (source-c ?fdac-c) (dest-r ?tbac-r) (dest-c ?tbac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?fdac-r) (source-c ?fdac-c)
                                 (dest-direction any) (dest-r ?tbac-r) (dest-c ?tbac-c)))
        (focus PCPC)
)

;Planning for serve order - If B - True
(defrule serve-order-if-foods-to-load-true
    (declare (salience 97))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vlf <- (var loadedFood ?lf)
    ?vfb <- (var foodOnBoard ?fb)
    (and (test (> ?food ?lf)) (test (> ?slots 0)))
    ;FD Best position
       (var tablepos ?tb-r ?tb-c)    
        ;Table access-cell
        (access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbac-r) (pos-c ?tbac-c))
        ?vpos <- (var agentPos ?ag-r ?ag-c)
        ;FD access-cell
        (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
            (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c) (cost ?pos-fd))
            (pcpc (source-r ?fdac-r) (source-c ?fdac-c) (dest-r ?tbac-r) (dest-c ?tbac-c) (cost ?fd-tab))
        ;Not exists any FD closer to both pos and table
        (not 
            (and
                (access-cell (object FD) (pos-r ?fdb-r) (pos-c ?fdb-c))
                (and
                	(access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbb-r) (pos-c ?tbb-c))
                	(and
	                    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdb-r) (dest-c ?fdb-c) (cost ?pos-fdb))
	                    (and 
	                        (pcpc (source-r ?fdb-r) (source-c ?fdb-c) (dest-r ?tbb-r) (dest-c ?tbb-c) (cost ?fdb-tab))    
	                        (and
	                            (test (> (dist-btw-pos-table ?pos-fd ?fd-tab) (dist-btw-pos-table ?pos-fdb ?fdb-tab)))
	                        )            
	                    )
	                )
                )
            )
        )
    =>
        ;Goto FD (temp var to check if FD is closer than DD)
        (assert (var load-food-check ?pos-fd ?fd-r ?fd-c ?fdac-r ?fdac-c (min ?slots (- ?food ?lf))))        
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (- ?slots (min ?slots (- ?food ?lf)))))
        (retract ?vlf)
        (assert (var loadedFood (+ ?lf (min ?slots (- ?food ?lf)))))
        (retract ?vfb)
        (assert (var foodOnBoard (min ?slots (- ?food ?lf))))
        (modify ?pln (step 3))
        ;(halt)
)

;Planning for serve order - If B - False
(defrule serve-order-if-foods-to-load-false
    (declare (salience 97))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 2) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 3))
        ;(halt)
)

;Planning for serve order - If C - True
;PCPC from Pos to DD not calculated yet 
(defrule serve-order-if-drinks-to-load-true-find-best-DD-pcpc-calculate-from-pos-to-DD
    (declare (salience 97))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 3) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vld <- (var loadedDrink ?ld)
    ?vdb <- (var drinkOnBoard ?db)
    (and (test (> ?drink ?ld)) (test (> ?slots 0)))
    ;PCPC from Pos to DD not calculated yet    
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object DD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?ag-r) (source-c ?ag-c)
                                 (dest-direction any) (dest-r ?fdac-r) (dest-c ?fdac-c)))
        (focus PCPC)
)

;PCPC from DD to Table not calculated yet 
(defrule serve-order-if-drinks-to-load-true-find-best-DD-pcpc-calculate-from-FD-to-table
    (declare (salience 97))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 3) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    ?vslots <- (var freeSlots ?slots)
    ?vld <- (var loadedDrink ?ld)
    ?vdb <- (var drinkOnBoard ?db)
    (and (test (> ?drink ?ld)) (test (> ?slots 0)))
    ;PCPC from Pos to FD not calculated yet    
    (var tablepos ?tb-r ?tb-c)    
    ;Table access-cell
    (access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbac-r) (pos-c ?tbac-c))
    ;DD access-cell
    (access-cell (object DD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?fdac-r) (source-c ?fdac-c) (dest-r ?tbac-r) (dest-c ?tbac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?fdac-r) (source-c ?fdac-c)
                                 (dest-direction any) (dest-r ?tbac-r) (dest-c ?tbac-c)))
        (focus PCPC)
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
    ;FD Best position
       (var tablepos ?tb-r ?tb-c)    
        ;Table access-cell
        (access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbac-r) (pos-c ?tbac-c))
        ?vpos <- (var agentPos ?ag-r ?ag-c)
        ;DD access-cell
        (access-cell (object DD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
            (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c) (cost ?pos-fd))
            (pcpc (source-r ?fdac-r) (source-c ?fdac-c) (dest-r ?tbac-r) (dest-c ?tbac-c) (cost ?fd-tab))
        ;Not exists any DD closer to both pos and table
        (not 
            (and
                (access-cell (object DD) (pos-r ?fdb-r) (pos-c ?fdb-c))
                (and
                	(access-cell (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?tbb-r) (pos-c ?tbb-c))
                	(and
	                    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdb-r) (dest-c ?fdb-c) (cost ?pos-fdb))
	                    (and 
	                        (pcpc (source-r ?fdb-r) (source-c ?fdb-c) (dest-r ?tbb-r) (dest-c ?tbb-c) (cost ?fdb-tab))    
	                        (and
	                            (test (> (dist-btw-pos-table ?pos-fd ?fd-tab) (dist-btw-pos-table ?pos-fdb ?fdb-tab)))
	                        )            
	                    )
	                )
                )
            )
        )=>
        ;Goto DD (temp var to check if FD is closer than DD)
        (assert (var load-drink-check ?pos-fd ?fd-r ?fd-c ?fdac-r ?fdac-c (min ?slots (- ?drink ?ld))))   
        ;update vars
        (retract ?vslots)
        (assert (var freeSlots (- ?slots (min ?slots (- ?drink ?ld)))))
        (retract ?vld)
        (assert (var loadedDrink (+ ?ld (min ?slots (- ?drink ?ld)))))
        (retract ?vdb)
        (assert (var drinkOnBoard (min ?slots (- ?drink ?ld))))
        (modify ?pln (step 4))
        ;(halt)
)

;Planning for serve order - If C - False
(defrule serve-order-if-drinks-to-load-false
    (declare (salience 95))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 3) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
    =>
        (modify ?pln (step 4))
        ;(halt)
)

;Choose to go first to FD or DD: first to FD, than DD
(defrule serve-order-check-FD-closer-than-DD
    (declare (salience 96))    
    ?pln <- (planning (type order) (step 4) (pseq ?pseq))
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    ?lfc <- (var load-food-check ?pos-fd ?fd-r ?fd-c ?fdac-r ?fdac-c ?f-qty)
    ?ldc <- (var load-drink-check ?pos-dd ?dd-r ?dd-c ?ddac-r ?ddac-c ?d-qty)
    (test (<= ?pos-fd ?pos-dd))
    =>
        (retract ?lfc)
        (retract ?ldc)
        ;Goto FD           
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?fdac-r) (param2 ?fdac-c)))
        ;Load Food
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?f-qty)))       
        ;Goto DD           
        (assert (plan-action (seq (+ 2 ?pseq)) (action Goto) (param1 ?ddac-r) (param2 ?ddac-c)))
        ;Load Drink
        (assert (plan-action (seq (+ 3 ?pseq)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?d-qty)))       
        ;update vars
        (retract ?vpos)
        (assert (var agentPos ?ddac-r ?ddac-c))
        (modify ?pln (step 4-bis) (pseq (+ 4 ?pseq)))
)

;Choose to go first to FD or DD: first to DD, than FD
(defrule serve-order-check-DD-closer-than-FD
    (declare (salience 96))    
    ?pln <- (planning (type order) (step 4) (pseq ?pseq))
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    ?lfc <- (var load-food-check ?pos-fd ?fd-r ?fd-c ?fdac-r ?fdac-c ?f-qty)
    ?ldc <- (var load-drink-check ?pos-dd ?dd-r ?dd-c ?ddac-r ?ddac-c ?d-qty)
    (test (<= ?pos-dd ?pos-fd))
    =>   
        (retract ?lfc)
        (retract ?ldc)
        ;Goto DD           
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?ddac-r) (param2 ?ddac-c)))
        ;Load Drink
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?d-qty)))       
        ;Goto FD           
        (assert (plan-action (seq (+ 2 ?pseq)) (action Goto) (param1 ?fdac-r) (param2 ?fdac-c)))
        ;Load Food
        (assert (plan-action (seq (+ 3 ?pseq)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?f-qty)))
        ;update vars
        (retract ?vpos)
        (assert (var agentPos ?fdac-r ?fdac-c))
        (modify ?pln (step 4-bis) (pseq (+ 4 ?pseq)))
)

;Choose to go first to FD or DD: FD only
(defrule serve-order-check-FD-only
    (declare (salience 95))    
    ?pln <- (planning (type order) (step 4) (pseq ?pseq))
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    ?lfc <- (var load-food-check ?pos-fd ?fd-r ?fd-c ?fdac-r ?fdac-c ?f-qty)
    (not (var load-drink-check $?))
    =>       
        (retract ?lfc)
        ;Goto FD           
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?fdac-r) (param2 ?fdac-c)))
        ;Load Food
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?f-qty)))     
        ;update vars
        (retract ?vpos)
        (assert (var agentPos ?fdac-r ?fdac-c))
        (modify ?pln (step 4-bis) (pseq (+ 2 ?pseq)))
)

;Choose to go first to FD or DD: DD only
(defrule serve-order-check-DD-only
    (declare (salience 95))    
    ?pln <- (planning (type order) (step 4) (pseq ?pseq))
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    ?lfc <- (var load-drink-check ?pos-dd ?dd-r ?dd-c ?ddac-r ?ddac-c ?d-qty)
    (not (var load-food-check $?))
    =>       
        (retract ?lfc)
        ;Goto DD           
        (assert (plan-action (seq ?pseq) (action Goto) (param1 ?ddac-r) (param2 ?ddac-c)))
        ;Load Drink
        (assert (plan-action (seq (+ 1 ?pseq)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?d-qty))) 
        ;update vars
        (retract ?vpos)
        (assert (var agentPos ?ddac-r ?ddac-c))
        (modify ?pln (step 4-bis) (pseq (+ 2 ?pseq)))
)

;Planning for serve order - goto Table
(defrule serve-order-goto-table
    (declare (salience 95))
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type order) (step 4-bis) (pseq ?pseq) (param1 ?ordid) (param2 ?tab) (param3 ?food) (param4 ?drink))
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

(defrule clean-table-plan-start
    (PLANNER__runonce)
    (not (planning))
	(intention  (table ?tab)
                (type clean)
    )
    (K-table (step ?s) (table ?tab) (state Dirty))
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2)") (param1 clean) (param2 ?tab)))
        (assert (planning (type cleantable) (step clean) (pseq 0) (param1 ?tab)))
        (assert (var agentPos ?ag-r ?ag-c))
        (assert (var tablepos ?tabr ?tabc))
)

(defrule clean-table-clean
	?pln <- (planning (type cleantable) (step clean) (pseq 0) (param1 ?tab))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    ;Table Best position
    ?vpos <- (var agentPos ?ag-r ?ag-c)
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r-tab) (pos-c ?c-tab))
    (not (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r-tab ?c-tab) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
    =>
    	(assert (plan-action (seq 0) (action Goto) (param1 ?r-tab) (param2 ?c-tab)))
    	(retract ?vpos)
    	(assert (var agentPos ?r-tab ?c-tab))
        (assert (plan-action (seq 1) (action CleanTable) (param1 ?tabr) (param2 ?tabc)))
        (modify ?pln (step objectives) (pseq 2))
)

;Planning for clean - TrashBasket
;PCPC from Table to TB not calculated yet 
(defrule clean-table-objectives-food-find-best-TB-pcpc-calculate-from-Pos-to-TB
    (declare (salience 51))
    (planning (type cleantable) (step objectives) (param1 ?tab))
   	(K-table (step ?s) (table ?tab) (food ?ft))
   	(test (> ?ft 0))
    ;PCPC from Pos to TB not calculated yet 
    (var agentPos ?ag-r ?ag-c)  
    (access-cell (object TB) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?ag-r) (source-c ?ag-c)
                                 (dest-direction any) (dest-r ?fdac-r) (dest-c ?fdac-c)))
        (focus PCPC)
)

(defrule clean-table-objectives-food
	(declare (salience 50))
	(planning (type cleantable) (step objectives) (param1 ?tab))
   	(K-table (step ?s) (table ?tab) (food ?ft))
   	(test (> ?ft 0))
    ;FD Best position
       (var agentPos ?ag-r ?ag-c)        
        ;TB access-cell
        (access-cell (object TB) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
            (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c) (cost ?pos-fd))
        ;Not exists any TB closer to both pos and table
        (not 
            (and
                (access-cell (object TB) (pos-r ?fdb-r) (pos-c ?fdb-c))
                (and
                    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdb-r) (dest-c ?fdb-c) (cost ?pos-fdb))
                    (and 
                        (test (> ?pos-fd ?pos-fdb))      
                    )
                )
            )
        )
    =>
   		(assert (var to-unload food))
   		(assert (var destination food ?fdac-r ?fdac-c ?fd-r ?fd-c))
   		(assert (var distance food ?pos-fd))
)

;Planning for clean - RecycleBasket
;PCPC from Table to RB not calculated yet 
(defrule clean-table-objectives-drink-find-best-RB-pcpc-calculate-from-Pos-to-RB
    (declare (salience 50))
	(planning (type cleantable) (step objectives) (param1 ?tab))
   	(K-table (step ?s) (table ?tab) (drink ?dt))
   	(test (> ?dt 0))
    ;PCPC from Pos to RB not calculated yet 
    (var agentPos ?ag-r ?ag-c)  
    (access-cell (object RB) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
    (not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c)))
    =>
        ;calculate PCPC
        ;#### TODO: usare direzione reale, se ne vale la pena ! ###
        (assert (calculate-pcpc (source-direction south) (source-r ?ag-r) (source-c ?ag-c)
                                 (dest-direction any) (dest-r ?fdac-r) (dest-c ?fdac-c)))
        (focus PCPC)
)

;#### TODO: usare nuova versione !!!! ####
(defrule clean-table-objectives-drink
	(declare (salience 50))
	(planning (type cleantable) (step objectives) (param1 ?tab))
   	(K-table (step ?s) (table ?tab) (drink ?dt))
   	(test (> ?dt 0))
   	;FD Best position
       (var agentPos ?ag-r ?ag-c)        
        ;RB access-cell
        (access-cell (object RB) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?fdac-r) (pos-c ?fdac-c))
            (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdac-r) (dest-c ?fdac-c) (cost ?pos-fd))
        ;Not exists any RB closer to both pos and table
        (not 
            (and
                (access-cell (object RB) (pos-r ?fdb-r) (pos-c ?fdb-c))
                (and
                    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?fdb-r) (dest-c ?fdb-c) (cost ?pos-fdb))
                    (and 
                        (test (> ?pos-fd ?pos-fdb))      
                    )
                )
            )
        )
   	=>
   		(assert (var to-unload drink))
   		(assert (var destination drink ?fdac-r ?fdac-c ?fd-r ?fd-c))
   		(assert (var distance drink ?pos-fd))
)

(defrule clean-table-objectives-done
	(declare (salience 49))
	?pln <- (planning (type cleantable) (step objectives) (param1 ?tab))
	=>
		(modify ?pln (step unload))
)

(defrule clean-table-unload-food
	(declare (salience 30))
	?pln <- (planning (type cleantable) (step unload) (pseq ?seq) (param1 ?tab))
	?vtu <- (var to-unload food)
	?vdest <- (var destination food ?r ?c ?tb-r ?tb-c)
	?vdist <- (var distance food ?dist-f)
	(or ;no drink to unload or RB is farther than TB
        (not (var to-unload drink))
        (var distance drink ?dist-d&:(> ?dist-d ?dist-f))
    ) 
	?vpos <- (var agentPos ?ag-r ?ag-c)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyFood) (param1 ?tb-r) (param2 ?tb-c)))
		(retract ?vtu)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule clean-table-unload-drink
	(declare (salience 29))
	?pln <- (planning (type cleantable) (step unload) (pseq ?seq) (param1 ?tab))
	?vtu <- (var to-unload drink)
	?vdest <- (var destination drink ?r ?c ?rb-r ?rb-c)
	?vdist <- (var distance drink ?dist-d)
	?vpos <- (var agentPos ?ag-r ?ag-c)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyDrink) (param1 ?rb-r) (param2 ?rb-c)))
		(retract ?vtu)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule clean-table-unload-done
	?pln <- (planning (type cleantable) (step unload))
	?f <- (PLANNER__runonce)
	=>
		;plan completed
		(retract ?pln)
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