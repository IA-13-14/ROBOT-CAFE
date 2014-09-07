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
        ;(assert (printGUI (time ?t) (step ?s) (source "AGENT::DELIBERATE") (verbosity 2) (text  "DELIBERATE Module invoked")))
)

;runonce section


;End runonce section
(defrule stop-runonce
    ?f <- (DELIBERATE__runonce)
    =>
    (retract ?f)
)

;TEST: Clean table are less important than orders.

;FIFO Strategy + Clean priority
(defrule fifo-deliberation-clean-priority
    (declare (salience 80))
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

;#### TODO: Check if order can be served (not table dirty) !! ####
;FIFO Strategy
(defrule fifo-deliberation
    (declare (salience 90))
    (not (intention))
    (status (step ?s) (time ?t))
    ;Find oldest desire
    (desire (step ?d-s)
            (time ?d-t)
            (table ?d-table)
            (type ?d-type)
            (order ?d-order)
    )
    (not (desire (step ?d-s2&:(< ?d-s2 ?d-s))))
    ;Check if order can be served = table clean
    (K-table (step ?s) (table ?d-table) (state Clean))
    ?f <- (intentions_changed (changed ?))
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