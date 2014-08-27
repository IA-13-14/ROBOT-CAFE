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
    (slot type (allowed-values deliver clean empty load))
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
)

;runonce section

;#### Load plan ####

;Start conditional plan for load
(defrule load-start
    (PLANNER__runonce)
    (not (planning))
	?i <- (intention 
                (type load)
                (order ?ordid)
                (table ?tab)
                (food ?food)
                (drink ?drink)
                (planned no)
    )
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 load) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (assert (planning (type load) (step intentions) (pseq 0) (param1 ?food) (param2 ?drink)))
        (modify ?i (planned yes))
)

;Add to plan foods and drinks from other intentions
(defrule load-add-intention
	(declare (salience 100))
	?p <- (planning (type load) (step intentions) (param1 ?p-food) (param2 ?p-drink))
	?i <- (intention 
                (type load)
                (table ?tab)
                (food ?food)
                (drink ?drink)
                (planned no)
    )
    (status (step ?s) (time ?t))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Added to plan intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 load) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (modify ?p (param1 (+ ?p-food ?food)) (param2 (+ ?p-drink ?drink)))
        (modify ?i (planned yes))
)

;No more intentions
(defrule load-intentions-done
	(declare (salience 99))
	?p <- (planning (type load) (step intentions))
	=>
		(modify ?p (step pcpc))
)

(defrule load-food-pcpc
	(declare (salience 50))
	(planning (type load) (step pcpc) (param1 ?food))
	(test (> ?food 0))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	(not (access-cell (pos-r ?ag-r) (pos-c ?ag-c))) ;if we are on an access cell pcpc was calculated at start
	(access-cell (object FD) (pos-r ?ac-r) (pos-c ?ac-c))
	(not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
	=>
		(assert (calculate-pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
		(focus PCPC)
)

(defrule load-drink-pcpc
	(declare (salience 50))
	(planning (type load) (step pcpc) (param2 ?drink))
	(test (> ?drink 0))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	(not (access-cell (pos-r ?ag-r) (pos-c ?ag-c))) ;if we are on an access cell pcpc was calculated at start
	(access-cell (object DD) (pos-r ?ac-r) (pos-c ?ac-c))
	(not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
	=>
		(assert (calculate-pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
		(focus PCPC)
)

(defrule load-pcpc-done
	(declare (salience 49))
	?pln <- (planning (type load) (step pcpc))
	=>
		(modify ?pln (step load))
)

(defrule load-food-first
	(declare (salience 30))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 ?food&:(> ?food 0)) (param2 ?drink&:(> ?drink 0)))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	;find best path food-drink and check that it's better than any path drink-food
	(access-cell (object FD) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?fd-r) (obj-c ?fd-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost-af)) ;cost from agent to food
	(access-cell (object DD) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?dd-r) (obj-c ?dd-c))
	(pcpc (source-r ?acf-r) (source-c ?acf-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost-fd)) ;cost from food to drink
	(not 
		(and
			(access-cell (object FD) (pos-r ?acf2-r) (pos-c ?acf2-c))
			(and
				(access-cell (object DD) (pos-r ?acd2-r) (pos-c ?acd2-c))
				(and
					(or ;foor first or drink first
						(and
							(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-af))
							(and
								(pcpc (source-r ?acf2-r) (source-c ?acf2-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-fd))
								(test (< (+ ?cost2-af ?cost2-fd) (+ ?cost-af ?cost-fd)))
							)
						)
						(and
							(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-ad))
							(and
								(pcpc (source-r ?acd2-r) (source-c ?acd2-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-df))
								(test (< (+ ?cost2-ad ?cost2-df) (+ ?cost-af ?cost-fd)))
							)
						)
					)
				)
			)
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?food)))
		(assert (plan-action (seq (+ ?seq 2)) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 3)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?drink)))
		(retract ?pln)
		(retract ?f)
)

(defrule load-drink-first
	(declare (salience 29))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 ?food&:(> ?food 0)) (param2 ?drink&:(> ?drink 0)))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	;find best path drink-food
	(access-cell (object DD) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?dd-r) (obj-c ?dd-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost-ad)) ;cost from agent to drink
	(access-cell (object FD) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?fd-r) (obj-c ?fd-c))
	(pcpc (source-r ?acd-r) (source-c ?acd-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost-df)) ;cost from drink to food
	(not 
		(and
			(access-cell (object DD) (pos-r ?acd2-r) (pos-c ?acd2-c))
			(and
				(access-cell (object FD) (pos-r ?acf2-r) (pos-c ?acf2-c))
				(and
					(and
						(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-ad))
						(and
							(pcpc (source-r ?acd2-r) (source-c ?acd2-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-df))
							(test (< (+ ?cost2-ad ?cost2-df) (+ ?cost-ad ?cost-df)))
						)
					)
				)
			)
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?drink)))
		(assert (plan-action (seq (+ ?seq 2)) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 3)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?food)))
		(retract ?pln)
		(retract ?f)
)

(defrule load-food
	(declare (salience 25))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 ?food&:(> ?food 0)) (param2 0))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	;find nearest access-cell for FD
	(access-cell (object FD) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?fd-r) (obj-c ?fd-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost)) ;cost from agent to food
	(not
		(and
			(access-cell (object FD) (pos-r ?acf2-r) (pos-c ?acf2-c))
			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2&:(< ?cost2 ?cost)))
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?food)))
		(retract ?pln)
		(retract ?f)
)

(defrule load-drink
	(declare (salience 25))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 0) (param2 ?drink&:(> ?drink 0)))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	;find nearest access-cell for DD
	(access-cell (object DD) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?dd-r) (obj-c ?dd-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost)) ;cost from agent to drink
	(not
		(and
			(access-cell (object DD) (pos-r ?acd2-r) (pos-c ?acd2-c))
			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2&:(< ?cost2 ?cost)))
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?drink)))
		(retract ?pln)
		(retract ?f)
)

;#### END - Load plan ####

;### Deliver plan ###

;Planning for deliver - start and goto Table
(defrule deliver-start
    (PLANNER__runonce)
    (not (planning))
    (intention 
        (type deliver)
        (table ?tab)
        (food ?food)
        (drink ?drink)
    )
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    ;Table Best position
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r) (pos-c ?c))
    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?r) (dest-c ?c) (cost ?cost))
    (not 
    	(and 
    		(access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1))
    		(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?r1) (dest-c ?c1) (cost ?cost1&:(< ?cost1 ?cost)))
    	)
    )
    =>
    	(assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 deliver) (param2 ?tab) (param3 ?food) (param4 ?drink)))
    	;Goto Table
        (assert (plan-action (seq 0) (action Goto) (param1 ?r) (param2 ?c)))
        (assert (planning (type deliver) (step food) (pseq 1) (param1 ?tab) (param2 ?food) (param3 ?drink)))
)

(defrule deliver-food
	(declare (salience 50))
    ?pln <- (planning (type deliver) (step food) (pseq ?pseq) (param1 ?tab) (param2 ?food))
    (test (> ?food 0))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    =>
        (assert (plan-action (seq ?pseq) (action DeliveryFood) (param1 ?tabr) (param2 ?tabc) (param3 ?food)))
        (modify ?pln (pseq (+ 1 ?pseq)) (step drink))
)

(defrule deliver-food-none
	(declare (salience 49))
	?pln <- (planning (type deliver) (step food))
	=>
		(modify ?pln (step drink))
)

(defrule deliver-drink
	(declare (salience 40))
    ?pln <- (planning (type deliver) (step drink) (pseq ?pseq) (param1 ?tab) (param3 ?drink))
    (test (> ?drink 0))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    =>
        (assert (plan-action (seq ?pseq) (action DeliveryDrink) (param1 ?tabr) (param2 ?tabc) (param3 ?drink)))
        (modify ?pln (pseq (+ 1 ?pseq)) (step done))
)

(defrule deliver-drink-none
	(declare (salience 39))
	?pln <- (planning (type deliver) (step drink))
	=>
		(modify ?pln (step done))
)

(defrule deliver-done
    ?f <- (PLANNER__runonce)
    ?pln <- (planning (type deliver) (step done))
    =>
        ;plan completed
        (retract ?pln)
        (retract ?f)
)

;#### END - Deliver plan ####

;#### Clean table plan ####

(defrule clean-table
    ?f <- (PLANNER__runonce)
    (not (planning))
	(intention  (table ?tab)
                (type clean)
    )
    (K-table (table ?tab) (state Dirty))
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    ;Table Best position
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r) (pos-c ?c))
    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?r) (dest-c ?c) (cost ?cost))
    (not 
    	(and 
    		(access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1))
    		(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?r1) (dest-c ?c1) (cost ?cost1&:(< ?cost1 ?cost)))
    	)
    )
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2)") (param1 clean) (param2 ?tab)))
        (assert (plan-action (seq 0) (action Goto) (param1 ?r) (param2 ?c)))
        (assert (plan-action (seq 1) (action CleanTable) (param1 ?tabr) (param2 ?tabc)))
        (retract ?f)
)

;#### END - Clean table plan ####

;#### Empty garbage plan ####

(defrule empty
	(PLANNER__runonce)
	(not (planning))
	(intention (type empty))
	(status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    =>
    	(assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1)") (param1 empty)))
    	(assert (planning (type empty) (step pcpc) (pseq 0)))
    	(assert (var agentPos ?ag-r ?ag-c))
)

(defrule empty-food-pcpc
	(declare (salience 50))
	(planning (type empty) (step pcpc))
	(status (step ?s))
   	(K-agent (step ?s) (l_f_waste yes) (pos-r ?ag-r) (pos-c ?ag-c))
	(not (access-cell (pos-r ?ag-r) (pos-c ?ag-c))) ;if we are on an access cell pcpc was calculated at start
	(access-cell (object TB) (pos-r ?ac-r) (pos-c ?ac-c))
	(not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
	=>
		(assert (calculate-pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
		(focus PCPC)
)

(defrule empty-drink-pcpc
	(declare (salience 50))
	(planning (type empty) (step pcpc))
	(status (step ?s))
   	(K-agent (step ?s) (l_d_waste yes) (pos-r ?ag-r) (pos-c ?ag-c))
	(not (access-cell (pos-r ?ag-r) (pos-c ?ag-c))) ;if we are on an access cell pcpc was calculated at start
	(access-cell (object RB) (pos-r ?ac-r) (pos-c ?ac-c))
	(not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
	=>
		(assert (calculate-pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
		(focus PCPC)
)

(defrule empty-pcpc-done
	(declare (salience 49))
	?pln <- (planning (type empty) (step pcpc))
	=>
		(modify ?pln (step unload))
)

(defrule empty-unload-food-first
	(declare (salience 30))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c) (l_f_waste yes) (l_d_waste yes))
	;find best path food-drink and check that it's better than any path drink-food
	(access-cell (object TB) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?tb-r) (obj-c ?tb-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost-af)) ;cost from agent to food
	(access-cell (object RB) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?rb-r) (obj-c ?rb-c))
	(pcpc (source-r ?acf-r) (source-c ?acf-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost-fd)) ;cost from food to drink
	(not 
		(and
			(access-cell (object TB) (pos-r ?acf2-r) (pos-c ?acf2-c))
			(and
				(access-cell (object RB) (pos-r ?acd2-r) (pos-c ?acd2-c))
				(and
					(or ;foor first or drink first
						(and
							(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-af))
							(and
								(pcpc (source-r ?acf2-r) (source-c ?acf2-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-fd))
								(test (< (+ ?cost2-af ?cost2-fd) (+ ?cost-af ?cost-fd)))
							)
						)
						(and
							(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-ad))
							(and
								(pcpc (source-r ?acd2-r) (source-c ?acd2-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-df))
								(test (< (+ ?cost2-ad ?cost2-df) (+ ?cost-af ?cost-fd)))
							)
						)
					)
				)
			)
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyFood) (param1 ?tb-r) (param2 ?tb-c)))
		(assert (plan-action (seq (+ ?seq 2)) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 3)) (action EmptyDrink) (param1 ?rb-r) (param2 ?rb-c)))
		(retract ?pln)
		(retract ?f)
)

(defrule empty-unload-drink-first
	(declare (salience 29))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c) (l_f_waste yes) (l_d_waste yes))
	;find best path drink-food
	(access-cell (object RB) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?rb-r) (obj-c ?rb-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost-ad)) ;cost from agent to drink
	(access-cell (object TB) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?tb-r) (obj-c ?tb-c))
	(pcpc (source-r ?acd-r) (source-c ?acd-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost-df)) ;cost from drink to food
	(not 
		(and
			(access-cell (object RB) (pos-r ?acd2-r) (pos-c ?acd2-c))
			(and
				(access-cell (object TB) (pos-r ?acf2-r) (pos-c ?acf2-c))
				(and
					(and
						(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2-ad))
						(and
							(pcpc (source-r ?acd2-r) (source-c ?acd2-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2-df))
							(test (< (+ ?cost2-ad ?cost2-df) (+ ?cost-ad ?cost-df)))
						)
					)
				)
			)
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyDrink) (param1 ?rb-r) (param2 ?rb-c)))
		(assert (plan-action (seq (+ ?seq 2)) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 3)) (action EmptyFood) (param1 ?tb-r) (param2 ?tb-c)))
		(retract ?pln)
		(retract ?f)
)

(defrule empty-unload-food
	(declare (salience 25))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c) (l_f_waste yes) (l_d_waste no))
	;find nearest access-cell for TB
	(access-cell (object TB) (pos-r ?acf-r) (pos-c ?acf-c) (obj-r ?tb-r) (obj-c ?tb-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf-r) (dest-c ?acf-c) (cost ?cost)) ;cost from agent to TB
	(not
		(and
			(access-cell (object TB) (pos-r ?acf2-r) (pos-c ?acf2-c))
			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acf2-r) (dest-c ?acf2-c) (cost ?cost2&:(< ?cost2 ?cost)))
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acf-r) (param2 ?acf-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyFood) (param1 ?tb-r) (param2 ?tb-c)))
		(retract ?pln)
		(retract ?f)
)

(defrule empty-unload-drink
	(declare (salience 25))
	?f <- (PLANNER__runonce)
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c) (l_f_waste no) (l_d_waste yes))
	;find nearest access-cell for RB
	(access-cell (object RB) (pos-r ?acd-r) (pos-c ?acd-c) (obj-r ?rb-r) (obj-c ?rb-c))
	(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd-r) (dest-c ?acd-c) (cost ?cost)) ;cost from agent to RB
	(not
		(and
			(access-cell (object RB) (pos-r ?acd2-r) (pos-c ?acd2-c))
			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?acd2-r) (dest-c ?acd2-c) (cost ?cost2&:(< ?cost2 ?cost)))
		)
	)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?acd-r) (param2 ?acd-c)))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyDrink) (param1 ?rb-r) (param2 ?rb-c)))
		(retract ?pln)
		(retract ?f)
)

;#### END - Empty garbage plan ####

;End runonce section
;(defrule stop-runonce
;    ?f <- (PLANNER__runonce)
;    =>
;    (retract ?f)
;)

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