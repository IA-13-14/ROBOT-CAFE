;######## MODULE: Deliberation Module
; Description:
;
;

;/-----------------------------------------------------------------------------------/
;/*****    DELIBERAZIONE: Scelta delle intenzioni ad ogni step			        *****/
;/-----------------------------------------------------------------------------------/
(defmodule DELIBERATE (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !

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

;Desires order if a (possible) load exists: deliver, clean(on table that made an order), empty, load
;Desires order if there's no load desire: deliver, clean, empty, move-away

(defrule deliberation-deliver-pcpc ;calculate pcpc if not present
	(declare (salience 99))
	(not (intention))
	(desire (type deliver)
			(table ?tab)
	)
	(status (step ?s))
	(K-agent (step ?s) (pos-r ?ag-r) (pos-c ?ag-c))
	(not (access-cell (pos-r ?ag-r) (pos-c ?ag-c))) ;if we are on an access cell pcpc was calculated at start
	(Table (table-id ?tab) (pos-r ?tabr) (pos-c ?tabc))
	(access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?ac-r) (pos-c ?ac-c))
	(not (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
	=>
		(assert (calculate-pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c)))
		(focus PCPC)
)

(defrule deliberation-deliver
    (declare (salience 95))
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
            (possible yes)
    )
    (Table (table-id ?d-table) (pos-r ?tabr) (pos-c ?tabc))
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?ac-r) (pos-c ?ac-c))
    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c) (cost ?cost))
    (not (and
    	 	(desire (type deliver) (table ?tab2) (possible yes))
    	 	(and
    	 		(Table (table-id ?tab2) (pos-r ?tabr2) (pos-c ?tabc2))
    	 		(and
    	 			(access-cell (object Table) (obj-r ?tabr2) (obj-c ?tabc2) (pos-r ?ac-r2) (pos-c ?ac-c2))
    	 			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r2) (dest-c ?ac-c2) (cost ?cost2&:(< ?cost2 ?cost)))
    	 		)	
    	 	)
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
    (desire (type load) (table ?d-table) (possible yes))
    ;Find closest clean desire for a table with load
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type clean)
            (order ?d-order)
            (possible yes)
    )
    (Table (table-id ?d-table) (pos-r ?tabr) (pos-c ?tabc))
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?ac-r) (pos-c ?ac-c))
    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c) (cost ?cost))
    (not (and
    		(desire (type load) (table ?tab2) (possible yes))
    		(and
	    	 	(desire (type clean) (table ?tab2) (possible yes))
	    	 	(and
	    	 		(Table (table-id ?tab2) (pos-r ?tabr2) (pos-c ?tabc2))
	    	 		(and
	    	 			(access-cell (object Table) (obj-r ?tabr2) (obj-c ?tabc2) (pos-r ?ac-r2) (pos-c ?ac-c2))
	    	 			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r2) (dest-c ?ac-c2) (cost ?cost2&:(< ?cost2 ?cost)))
	    	 		)	
	    		)
	    	)
    	 )
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
    (not (desire (type load) (possible yes)))
    ;Find closest clean desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type clean)
            (order ?d-order)
            (possible yes)
    )
    (Table (table-id ?d-table) (pos-r ?tabr) (pos-c ?tabc))
    (access-cell (object Table) (obj-r ?tabr) (obj-c ?tabc) (pos-r ?ac-r) (pos-c ?ac-c))
    (pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r) (dest-c ?ac-c) (cost ?cost))
    (not (and
    	 	(desire (type clean) (table ?tab2) (possible yes))
    	 	(and
    	 		(Table (table-id ?tab2) (pos-r ?tabr2) (pos-c ?tabc2))
    	 		(and
    	 			(access-cell (object Table) (obj-r ?tabr2) (obj-c ?tabc2) (pos-r ?ac-r2) (pos-c ?ac-c2))
    	 			(pcpc (source-r ?ag-r) (source-c ?ag-c) (dest-r ?ac-r2) (dest-c ?ac-c2) (cost ?cost2&:(< ?cost2 ?cost)))
    	 		)	
    	 	)
    	 )
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

;empty desire is unique
(defrule deliberation-empty
    (declare (salience 80))
    (not (intention))
    (status (step ?s) (time ?t))
    (desire (step ?d-s)
            (time ?d-t)
            (type empty)
            (id ?d-id)
            (possible yes)
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
    (not (desire (type empty))) ;can't load if garbage isn't emptied
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
            (possible yes)
    )
    (not (desire (type load) (food ?f2) (drink ?d2&:(> (+ ?f2 ?d2) (+ ?d-food ?d-drink))) (possible yes)))
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
            (possible yes)
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

(defrule deliberation-move-away
	(declare (salience 10))
	(not (intention))
	(status (step ?s) (time ?t))
	(desire (type move-away) (pos-r ?r) (pos-c ?c) (step ?d-s) (time ?d-t) (id ?d-id) (possible yes))
	?f <- (intentions_changed)
	=>
		(assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Added intention (Time:%p1,Type:%p2,P:%p3-%p4)") (param1 ?d-t) (param2 move-away) (param3 ?r) (param4 ?c)))
		(assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (type move-away)
                            (pos-r ?r)
                            (pos-c ?c)
                            (desire ?d-t)
                            (desire-id ?d-id)
                )
        )
        (modify ?f (changed yes))
)
;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (DELIBERATE__init)
    =>
        (retract ?f)
        (pop-focus)
)