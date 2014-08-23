;######## MODULE: Deliberation Module
; Description:
;
;

;/-----------------------------------------------------------------------------------/
;/*****    DELIBERAZIONE: Scelta delle intenzioni ad ogni step			        *****/
;/-----------------------------------------------------------------------------------/
(defmodule DELIBERATE (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !

(deffunction manh-cost(?r ?c ?d-r ?d-c)
    (+ (abs (- ?d-r ?r)) (abs (- ?d-c ?c)) )
)

;Initialization
(defrule DELIBERATE__init-rule
    (declare (salience 100))
    (not (DELIBERATE__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (DELIBERATE__init)) 
        (assert (DELIBERATE__runonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "DELIBERATE Module invoked")))
)

;runonce section


;End runonce section
(defrule stop-runonce
    ?f <- (DELIBERATE__runonce)
    =>
    (retract ?f)
)

;Desires order if a load exists: deliver, clean(on table that made an order), empty, load
;Desires order if there's no load desire: deliver, clean, empty
(defrule deliberation-deliver
    (declare (salience 100))
    (not (intention))
    (status (step ?s) (time ?t))
    (K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
    ;Find closest deliver desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (food ?d-food)
            (drink ?d-drink)
            (type deliver)
            (order ?d-order)
            (id ?d-id)
    )
    (Table (table-id ?d-table) (pos-r ?tabr) (pos-c ?tabc))
    (not (and
    	 (desire (type deliver) (table ?tab2))
    	 (Table (table-id ?tab2) (pos-r ?tabr2) (pos-c ?tabc2&:(< (manh-cost ?ag-r ?ag-c ?tabr2 ?tabc2) (manh-cost ?ag-r ?ag-c ?tabr ?tabc))))
    	 )
    )
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 deliver) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (food ?d-food)
                            (drink ?d-drink)
                            (type deliver)
                            (order ?d-order)
                            (desire ?d-t)
                            (desire-id ?d-id)
                )
        )  
    (modify ?f (changed yes))
)

(defrule deliberation-clean-load
    (declare (salience 90))
    (not (intention))
    (status (step ?s) (time ?t))
    ;A load exists
    (desire (type load) (table ?d-table))
    ;Find a clean desire for table with load
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type clean)
            (order ?d-order)
    )
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 clean) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (type clean)
                            (order ?d-order)
                            (desire ?d-t)
                )
        )  
    (modify ?f (changed yes))
)

(defrule deliberation-clean-noload
    (declare (salience 90))
    (not (intention))
    (status (step ?s) (time ?t))
    ;There are no load desires
    (not (desire (type load)))
    ;Find oldest clean desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type clean)
            (order ?d-order)
    )
    (not (desire (type clean) (step ?d-s2&:(< ?d-s2 ?d-s))))
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 clean) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (type clean)
                            (order ?d-order)
                            (desire ?d-t)
                )
        )  
    (modify ?f (changed yes))
)

;empty desire is unique
(defrule deliberation-empty
    (declare (salience 80))
    (not (intention))
    (status (step ?s) (time ?t))
    (desire (step ?d-s)
            (time ?d-t)
            (type empty)
            (id ?d-id)
    )
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2)") (param1 ?d-t) (param2 empty)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (type empty)
                            (desire ?d-t)
                            (desire-id ?d-id)
                )
        )  
    (modify ?f (changed yes))
)

(defrule deliberation-load
    (declare (salience 70))
    (not (intention))
    (status (step ?s) (time ?t))
    ;Find biggest load desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (food ?d-food)
            (drink ?d-drink)
            (type load)
            (order ?d-order)
            (id ?d-id)
    )
    (not (desire (type load) (food ?f2) (drink ?d2&:(> (+ ?f2 ?d2) (+ ?d-food ?d-drink)))))
    ;Check if order can be served = table not dirty
    (K-table (step ?s) (table ?d-table) (state ~Dirty))
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 load) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (food ?d-food)
                            (drink ?d-drink)
                            (type load)
                            (order ?d-order)
                            (desire ?d-t)
                            (desire-id ?d-id)
                )
        )  
        (assert (var free (- ?*SLOTS* (+ ?d-food ?d-drink))))
    (modify ?f (changed yes))
)

(defrule deliberation-add-load
	(declare (salience 50))
	(intention (type load))
	?vf <- (var free ?free)
	(test (> ?free 0))
	(status (step ?s) (time ?t))
	;Find a not picked load desire that can be combined
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (food ?d-food)
            (drink ?d-drink&:(<= (+ ?d-food ?d-drink) ?free))
            (type load)
            (order ?d-order)
            (id ?d-id)
    )
    (not (intention (desire ?d-t) (desire-id ?d-id)))
    ;Check if order can be served = table not dirty
    (K-table (step ?s) (table ?d-table) (state ~Dirty))
    =>
    	(assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Added intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 load) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (food ?d-food)
                            (drink ?d-drink)
                            (type load)
                            (order ?d-order)
                            (desire ?d-t)
                            (desire-id ?d-id)
                )
        )  
    	(retract ?vf)
    	(assert (var free (- ?free (+ ?d-food ?d-drink))))
)

(defrule deliberation-done-load
	(declare (salience 40))
	(intention (type load))
	?vf <- (var free ?)
	=>
		(retract ?vf)
)

;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (DELIBERATE__init)
    =>
        (retract ?f)
        (pop-focus)
)