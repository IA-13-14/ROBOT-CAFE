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

;Desires order: deliver, clean, empty, load
(defrule fifo-deliberation-deliver
    (declare (salience 100))
    (not (intention))
    (status (step ?s) (time ?t))
    ;Find oldest deliver desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (food ?d-food)
            (drink ?d-drink)
            (type deliver)
            (order ?d-order)
            (id ?d-id)
    )
    (not (desire (type deliver) (step ?d-s2&:(< ?d-s2 ?d-s))))
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

(defrule fifo-deliberation-clean
    (declare (salience 90))
    (not (intention))
    (status (step ?s) (time ?t))
    ;Find oldest clean desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type ?d-type&clean)
            (order ?d-order)
    )
    (not (desire (type ?d-type&clean) (step ?d-s2&:(< ?d-s2 ?d-s))))
    ?f <- (intentions_changed (changed ?))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 clean) (param3 ?d-table)))        
        (assert (intention  (step ?d-s)
                            (time ?d-t)
                            (accepted-step ?s)
                            (accepted-time ?t)
                            (table ?d-table)
                            (type ?d-type)
                            (order ?d-order)
                            (desire ?d-t)
                )
        )  
    (modify ?f (changed yes))
)

;empty desire is unique
(defrule fifo-deliberation-empty
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
    ;Find oldest load desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (food ?d-food)
            (drink ?d-drink)
            (type load)
            (order ?d-order)
            (id ?d-id)
    )
    (not (desire (type load) (step ?d-s2&:(< ?d-s2 ?d-s))))
    ;Check if order can be served = table clean
    (K-table (step ?s) (table ?d-table) (state Clean))
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