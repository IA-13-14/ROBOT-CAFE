;######## MODULE: Belief Updater Module
; Description:
;
;

;TODO: Replace PATH-PCPC with the name of the module

;/-----------------------------------------------------------------------------------/
;/*****    GESTIONE PERCEZIONI AMBIENTE (e aggiornamento opportuni fatti)       *****/
;/-----------------------------------------------------------------------------------/
(defmodule PCPC (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL) (import PLANNER ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !

;Initilization
(defrule PCPC__init-rule
    (declare (salience 100))
    (not (PCPC__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (PCPC__init)) 
        (assert (PCPC__runonce))
        (assert (PCPC__planonce))
        ;(assert (printGUI (time ?t) (step ?s) (source "AGENT::PCPC") (verbosity 2) (text  "PCPC Module invoked")))
        ;(halt)
)

;runonce section


;End runonce section
;(defrule stop-runonce
;    ?f <- (PCPC__runonce)
;    =>
;    (retract ?f)
;)

(defrule calc-pcpc
    (declare (salience 50))
    (calculate-pcpc (source-r ?src-r) (source-c ?src-c)
                    (dest-r ?dst-r) (dest-c ?dst-c))
    (status (time ?t) (step ?s))
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PCPC") (verbosity 2) (text  "Calculating PCPC")))
        ;calcolo percorso con PATH_PLANNER_HIGH_LEVEL
        (assert (start-path-planning (source-r ?src-r) (source-c ?src-c)
                                 (dest-r ?dst-r) (dest-c ?dst-c) (ignore-perceptions yes)))
        (focus PATH-PLANNER-HL)
)

;#### TODO: C'è sempre un percorso ? Se non considero le persone si ! ####
(defrule path-planner-result-no
    (declare (salience 60))   
    ?cf <- (calculate-pcpc (source-r ?src-r) (source-c ?src-c)
                    (dest-r ?dst-r) (dest-c ?dst-c))
    ?f <- (path-planning-result (success no))
    (status (step ?s) (time ?t))
    =>
        ;(assert (printGUI (time ?t) (step ?s) (source "AGENT::PCPC") (verbosity 2) (text  "Calculating PCPC from (%p1,%p2-%p3) to (%p4,%p5): cost %p6") (param1 ?src-r) (param2 ?src-c) (param3 ?src-d) (param4 ?dst-r) (param5 ?dst-c) (param6 99999)))
        (assert (pcpc (source-r ?src-r) (source-c ?src-c)
                    (dest-r ?dst-r) (dest-c ?dst-c) (cost 99999)))
        (assert (pcpc (source-r ?dst-r) (source-c ?dst-c)
                    (dest-r ?src-r) (dest-c ?src-c) (cost 99999)))
        (retract ?f)
        (retract ?cf)
        ;(halt)
)

;Add PCPC entry (simmetrical) in case of PathPlanning success
(defrule path-planner-result-yes
    (declare (salience 60))
   ?cf <- (calculate-pcpc (source-r ?src-r) (source-c ?src-c)
                    (dest-r ?dst-r) (dest-c ?dst-c))
    ?f <- (path-planning-result (success yes) (cost ?cost))
    (status (step ?s) (time ?t))
    =>
        ;(assert (printGUI (time ?t) (step ?s) (source "AGENT::PCPC") (verbosity 2) (text  "Calculating PCPC from (%p1,%p2-%p3) to (%p4,%p5): cost %p6") (param1 ?src-r) (param2 ?src-c) (param3 ?src-d) (param4 ?dst-r) (param5 ?dst-c) (param6 ?cost)))
        (assert (pcpc (source-r ?src-r) (source-c ?src-c)
                    (dest-r ?dst-r) (dest-c ?dst-c) (cost ?cost)))
        (assert (pcpc (source-r ?dst-r) (source-c ?dst-c)
                    (dest-r ?src-r) (dest-c ?src-c) (cost ?cost)))
        (retract ?f)
        (retract ?cf)
        ;(halt)
)

;Clean up PathPlanning results
(defrule calc-pcpc-clean1
    (declare (salience -6))
    ?f <- (path-planning-action (sequence ?seq) (operator ?oper))
    =>
        (retract ?f)
)

;Dispose
(defrule dispose
    (declare (salience -100))
    ?f <- (PCPC__init)
    =>
        (retract ?f)
        (pop-focus)
)