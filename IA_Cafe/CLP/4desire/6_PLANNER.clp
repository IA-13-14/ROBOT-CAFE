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

(deffunction manh-cost(?r ?c ?d-r ?d-c)
    (+ (abs (- ?d-r ?r)) (abs (- ?d-c ?c)) )
)

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
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2,F:%p3,D:%p4)") (param1 load) (param2 ?tab) (param3 ?food) (param4 ?drink)))
        (assert (planning (type load) (step intentions) (pseq 0) (param1 ?food) (param2 ?drink)))
        (modify ?i (planned yes))
        (assert (var agentPos ?ag-r ?ag-c))
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
		(modify ?p (step objectives))
)

(defrule load-objectives-food
	(declare (salience 50))
	(planning (type load) (step objectives) (param1 ?food))
   	(test (> ?food 0))
   	;FD Best position
    (var agentPos ?ag-r ?ag-c)
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object FD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
   	=>
   		(assert (var to-load food))
   		(assert (var destination food ?r ?c ?fd-r ?fd-c))
   		(assert (var distance food (manh-cost ?ag-r ?ag-c ?r ?c)))
)

(defrule load-objectives-drink
	(declare (salience 50))
	(planning (type load) (step objectives) (param2 ?drink))
   	(test (> ?drink 0))
   	;DD Best position
    (var agentPos ?ag-r ?ag-c)
    (access-cell (object DD) (obj-r ?dd-r) (obj-c ?dd-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object DD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
   	=>
   		(assert (var to-load drink))
   		(assert (var destination drink ?r ?c ?dd-r ?dd-c))
   		(assert (var distance drink (manh-cost ?ag-r ?ag-c ?r ?c)))
)

(defrule load-objectives-done
	(declare (salience 49))
	?pln <- (planning (type load) (step objectives))
	=>
		(modify ?pln (step load))
)

(defrule load-food-first
	(declare (salience 30))
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 ?food))
	?vtl <- (var to-load food)
	?vdest <- (var destination food ?r ?c ?fd-r ?fd-c)
	?vdist <- (var distance food ?dist-f)
	(var to-load drink)
	(var distance drink ?dist-d&:(> ?dist-d ?dist-f)) ;DD is farther than FD
	?vpos <- (var agentPos ?ag-r ?ag-c)
	?vdest-d <- (var destination drink $?)
	;DD Best position
    (access-cell (object DD) (obj-r ?dd-r) (obj-c ?dd-c) (pos-r ?r-d) (pos-c ?c-d))
    (not (access-cell (object DD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?r ?c ?r-d ?c-d) (manh-cost ?r ?c ?r1 ?c1)))))
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(retract ?vdest-d)
		(assert (var destination drink ?r-d ?c-d ?dd-r ?dd-c))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?food)))
		(retract ?vtl)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule load-drink-first
	(declare (salience 29))
	?pln <- (planning (type load) (step load) (pseq ?seq) (param2 ?drink))
	?vtl <- (var to-load drink)
	?vdest <- (var destination drink ?r ?c ?dd-r ?dd-c)
	?vdist <- (var distance drink ?dist-d)
	?vpos <- (var agentPos ?ag-r ?ag-c)
	?vdest-f <- (var destination food $?)
	;FD Best position
    (access-cell (object FD) (obj-r ?fd-r) (obj-c ?fd-c) (pos-r ?r-f) (pos-c ?c-f))
    (not (access-cell (object FD) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?r ?c ?r-f ?c-f) (manh-cost ?r ?c ?r1 ?c1)))))
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(retract ?vdest-f)
		(assert (var destination food ?r-f ?c-f ?fd-r ?fd-c))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?drink)))
		(retract ?vtl)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule load-food
	(declare (salience 25))
	?pln <- (planning (type load) (step load) (pseq ?seq) (param1 ?food))
	?vtl <- (var to-load food)
	?vdest <- (var destination food ?r ?c ?fd-r ?fd-c)
	?vdist <- (var distance food ?dist-f)
	?vpos <- (var agentPos ?ag-r ?ag-c)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadFood) (param1 ?fd-r) (param2 ?fd-c) (param3 ?food)))
		(retract ?vtl)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule load-drink
	(declare (salience 25))
	?pln <- (planning (type load) (step load) (pseq ?seq) (param2 ?drink))
	?vtl <- (var to-load drink)
	?vdest <- (var destination drink ?r ?c ?dd-r ?dd-c)
	?vdist <- (var distance drink ?dist-d)
	?vpos <- (var agentPos ?ag-r ?ag-c)
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(assert (plan-action (seq (+ ?seq 1)) (action LoadDrink) (param1 ?dd-r) (param2 ?dd-c) (param3 ?drink)))
		(retract ?vtl)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule load-done
	?pln <- (planning (type load) (step load))
	?f <- (PLANNER__runonce)
	=>
		;plan completed
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
    (not (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
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
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    ;Table Best position
    (Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r-tab) (pos-c ?c-tab))
    (not (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r-tab ?c-tab) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PLANNER") (verbosity 2) (text  "Planning for intention (Type:%p1,T:%p2)") (param1 clean) (param2 ?tab)))
        (assert (plan-action (seq 0) (action Goto) (param1 ?r-tab) (param2 ?c-tab)))
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
    	(assert (planning (type empty) (step objectives) (pseq 0)))
    	(assert (var agentPos ?ag-r ?ag-c))
)

(defrule empty-objectives-food
	(declare (salience 50))
	(planning (type empty) (step objectives))
	(status (step ?s))
   	(K-agent (step ?s) (l_f_waste yes))
   	;TB Best position
    (var agentPos ?ag-r ?ag-c)
    (access-cell (object TB) (obj-r ?tb-r) (obj-c ?tb-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object TB) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
   	=>
   		(assert (var to-unload food))
   		(assert (var destination food ?r ?c ?tb-r ?tb-c))
   		(assert (var distance food (manh-cost ?ag-r ?ag-c ?r ?c)))
)

(defrule empty-objectives-drink
	(declare (salience 50))
	(planning (type empty) (step objectives))
	(status (step ?s))
   	(K-agent (step ?s) (l_d_waste yes))
   	;RB Best position
    (var agentPos ?ag-r ?ag-c)
    (access-cell (object RB) (obj-r ?rb-r) (obj-c ?rb-c) (pos-r ?r) (pos-c ?c))
    (not (access-cell (object RB) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?ag-r ?ag-c ?r ?c) (manh-cost ?ag-r ?ag-c ?r1 ?c1)))))
   	=>
   		(assert (var to-unload drink))
   		(assert (var destination drink ?r ?c ?rb-r ?rb-c))
   		(assert (var distance drink (manh-cost ?ag-r ?ag-c ?r ?c)))
)

(defrule empty-objectives-done
	(declare (salience 49))
	?pln <- (planning (type empty) (step objectives))
	=>
		(modify ?pln (step unload))
)

(defrule empty-unload-food-first
	(declare (salience 30))
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	?vtu <- (var to-unload food)
	?vdest <- (var destination food ?r ?c ?tb-r ?tb-c)
	?vdist <- (var distance food ?dist-f)
	(var to-unload drink)
	(var distance drink ?dist-d&:(> ?dist-d ?dist-f)) ;RB is farther than TB
	?vpos <- (var agentPos ?ag-r ?ag-c)
	?vdest-d <- (var destination drink $?)
	;RB Best position
    (access-cell (object RB) (obj-r ?rb-r) (obj-c ?rb-c) (pos-r ?r-d) (pos-c ?c-d))
    (not (access-cell (object RB) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?r ?c ?r-d ?c-d) (manh-cost ?r ?c ?r1 ?c1)))))
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(retract ?vdest-d)
		(assert (var destination drink ?r-d ?c-d ?rb-r ?rb-c))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyFood) (param1 ?tb-r) (param2 ?tb-c)))
		(retract ?vtu)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule empty-unload-drink-first
	(declare (salience 29))
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	?vtu <- (var to-unload drink)
	?vdest <- (var destination drink ?r ?c ?rb-r ?rb-c)
	?vdist <- (var distance drink ?dist-d)
	?vpos <- (var agentPos ?ag-r ?ag-c)
	?vdest-f <- (var destination food $?)
	;TB Best position
    (access-cell (object TB) (obj-r ?rb-r) (obj-c ?rb-c) (pos-r ?r-f) (pos-c ?c-f))
    (not (access-cell (object TB) (pos-r ?r1) (pos-c ?c1&:(> (manh-cost ?r ?c ?r-f ?c-f) (manh-cost ?r ?c ?r1 ?c1)))))
	=>
		(assert (plan-action (seq ?seq) (action Goto) (param1 ?r) (param2 ?c)))
		(retract ?vpos)
		(assert (var agentPos ?r ?c))
		(retract ?vdest-f)
		(assert (var destination food ?r-f ?c-f ?rb-r ?rb-c))
		(assert (plan-action (seq (+ ?seq 1)) (action EmptyDrink) (param1 ?rb-r) (param2 ?rb-c)))
		(retract ?vtu)
		(retract ?vdest)
		(retract ?vdist)
		(modify ?pln (pseq (+ ?seq 2)))
)

(defrule empty-unload-food
	(declare (salience 25))
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
	?vtu <- (var to-unload food)
	?vdest <- (var destination food ?r ?c ?tb-r ?tb-c)
	?vdist <- (var distance food ?dist-f)
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

(defrule empty-unload-drink
	(declare (salience 25))
	?pln <- (planning (type empty) (step unload) (pseq ?seq))
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

(defrule empty-unload-done
	?pln <- (planning (type empty) (step unload))
	?f <- (PLANNER__runonce)
	=>
		;plan completed
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