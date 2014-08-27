;######## MODULE: Deliberation Module
; Description:
;
;

;/-----------------------------------------------------------------------------------/
;/*****    DELIBERAZIONE: Scelta delle intenzioni ad ogni step			        *****/
;/-----------------------------------------------------------------------------------/
(defmodule DELIBERATE (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !

;Initilization
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

;TEST: Serve highest penalty desire
;#### TEST: Clean caused by high priority order desire ####
;FIFO Strategy
(defrule fifo-deliberation-highest-penalty-priority-clean-needed
    (declare (salience 90))
    (not (intention)) ;FIFO intention check
    (status (step ?s) (time ?t))
    ?f <- (intentions_changed (changed ?))
    ;Find highest priority desire
    (desire (table ?d-table)
            (type order)
            (penalty ?d-p)
    )
   
    ;Not exists a higher priority desire
    (not (desire (penalty ?d2-p&:(> ?d2-p ?d-p))))
    
    ;Check if desire is an order that can NOT be served != table clean
    (K-table (step ?s) (table ?d-table) (state ~Clean))
    
    ;Find related clean desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type ?d-type&clean)
            (order ?d-order)
    )
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 ?d-type) (param3 ?d-table)))        
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

;TEST: Serve highest penalty desire
;FIFO Strategy
(defrule fifo-deliberation-highest-penalty-priority
    (declare (salience 80))
    (not (intention)) ;FIFO intention check
    (status (step ?s) (time ?t))
    ?f <- (intentions_changed (changed ?))
    ;Find highest priority desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type ?d-type)
            (order ?d-order)
            (penalty ?d-p)
    )
   
    ;Not exists a higher priority desire
    (not (desire (penalty ?d2-p&:(> ?d2-p ?d-p))))
    
    ;Check if desire is an order that can be served = table clean
    (or
    	(test (eq ?d-type clean))
    	(K-table (step ?s) (table ?d-table) (state Clean))
    )
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "Selected intention (Time:%p1,Type:%p2,T:%p3)") (param1 ?d-t) (param2 ?d-type) (param3 ?d-table)))        
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


;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (DELIBERATE__init)
    =>
        (retract ?f)
        (pop-focus)
)