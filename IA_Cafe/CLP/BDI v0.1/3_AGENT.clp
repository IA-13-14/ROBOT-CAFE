;// AGENT

(defmodule AGENT (import MAIN ?ALL) (export ?ALL))

;#####  required for GUI #####
(deftemplate init-agent (slot done (allowed-values yes no))) ; Ci dice se l'inizializzazione dell'agente è conclusa

; Mantiene lo step in cui è stata effettuata l'ultima percezione (onde evitare loop su una stessa percezione)
(deftemplate last-perc (slot step))

;END -- #####  required for GUI #####

(deftemplate K-cell  (slot pos-r) (slot pos-c) 
                     (slot contains (allowed-values Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
                     (slot initial (type SYMBOL) (allowed-symbols no yes) (default no)) ;campo per distinguere i dati iniziali dalle future percezioni temporanee
)

(deftemplate K-agent
	(slot step)
        (slot time) 
	(slot pos-r) 
	(slot pos-c) 
	(slot direction) 
	(slot l-drink)
        (slot l-food)
        (slot l_d_waste) ;COS'E' ?
        (slot l_f_waste)
)


;### DESIRES Template ###
(deftemplate desire
    (slot step)
    (slot time)
    (slot table)
    (slot type (allowed-values order clean))
    (slot order (default NA))
)

;### ANSWER-TO-ORDER Template ###
(deftemplate answer-to-order
    (slot step)
    (slot time)
    (slot order)
)

;### ANSWER-TO-ORDER Template ###
(deftemplate order
    (slot req-id)
    (slot step)
    (slot time)
    (slot table)    
    (slot food)
    (slot drink)
)
        
(defrule  beginagent1
    (declare (salience 11))
    (status (step 0))
    ;(not (exec (step 0)))
    ;#GUI#
    (not (init-agent (done yes))) 
    (prior-cell (pos-r ?r) (pos-c ?c) (contains ?x)) 
=>
    (assert (K-cell (pos-r ?r) (pos-c ?c) (contains ?x) (initial yes))) ;K-Cell iniziali  
    (assert (req-id-counter 0))
)
            


 
(defrule  beginagent2
    (declare (salience 11))
    (status (step 0))
    ;(not (exec (step 0)))
    ;#GUI#
    (not (init-agent (done yes))) 
    (initial_agentposition (pos-r ?r) (pos-c ?c) (direction ?d))
=> 
    (assert (K-agent (step 0) (time 0) (pos-r ?r) (pos-c ?c) (direction ?d)
                              (l-drink 0) (l-food 0) (l_d_waste no) (l_f_waste no)))

    ;#GUI#                          
    (assert (last-perc (step -1)))
    (assert (init-agent (done yes)))

    (assert (printGUI (time 0) (step 0) (source "AGENT") (verbosity 2) (text  "AGENT INITIALIZED !")))
    (assert (BDistatus 0))
)

 ;### BDI Control Loop ###


 (defrule BDI_loop_0
    (declare (salience 100))
    (status (step ?s))
    ?fs <- (last-perc (step ?old-s))
    ?bdis <- (BDistatus 0)
    (test (> ?s ?old-s))
    ;(perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction west)) ;o altre percezioni
    =>
        (retract ?bdis)
        (assert (BDistatus 1))
        (focus UPDATE-BEL)    
 )


;### TODO: answer to new orders immediately and goto 0 !!!!
(defrule BDI_check_answer-order
    (declare (salience 100))
    ?ansor <- (answer-to-order (step ?os) (time ?ot) (order ?req-id))
    (order (step ?os) (time ?ot) (req-id ?req-id) (table ?otable) (food ?ofood) (drink ?odrink))
    (status (step ?s))
    ?bdis <- (BDistatus 1)
    ;(perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction west)) ;o altre percezioni
    =>
        (retract ?bdis)
        (retract ?ansor)
        (assert (BDistatus -1))
        ;### TODO: Decidere se accettare o meno
        (assert (exec (step ?s) (action Inform) (param1 ?otable) (param2 ?req-id) (param3 accepted)))  
 )


 (defrule ask_act
    ?f <-   (status (step ?i))
    ?bdis <- (BDistatus 1)
    =>  (printout t crlf crlf)
        (printout t "action to be executed at step:" ?i)
        (printout t crlf crlf)
        (modify ?f (result no))
        (retract ?bdis)
        (assert (BDistatus 2))
)

;IMPORTANT: Assert one action per step, actions for future steps will be executed without returning to the agent.
(defrule BDI_loop_3
    (declare (salience 100))
    (status (step ?s))
    ?bdis <- (BDistatus 2)
    ?fs <- (last-perc (step ?old-s))
    =>        
        (modify ?fs (step ?s))
        (retract ?bdis)
        (assert  (BDistatus 0))
        (assert (exec (step ?s) (action Wait)))
 )

(defrule exec_act    
    ;(declare (salience 2))
    ?bdis <- (BDistatus ?)
    (status (step ?i) (time ?t))
    (exec (step ?i) (action ?oper))    
    =>
        (printout t crlf  "== AGENT ==" crlf) (printout t "Start the execution of the action: " ?oper)
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "Start the execution of the action: %p1") (param1 ?oper)))      
        ;(pop-focus)
        (retract ?bdis)
        (assert (BDistatus 0))
        (pop-focus)
)

;(defrule BDI_loop
;    (status (step ?s))
;    (BDistatus 2)
;    =>
;        ;remove perc        
;        (focus DELIBERATE)
; )

; (defrule BDI_loop
;    (status (step ?s))
;    (BDistatus 3)
;    =>
;        ;remove perc        
;        (focus PLANNER)
; )

; (defrule BDI_loop
;    (status (step ?s))
;    (BDistatus 4)
;    =>
;        ;remove perc        
;        (focus ACTIONS-PLANNER)
; )

 
;OLD default implementation
;(defrule ask_act
; ?f <-   (status (step ?i))
;    =>  (printout t crlf crlf)
;        (printout t "action to be executed at step:" ?i)
;        (printout t crlf crlf)
;        (modify ?f (result no)))


;(defrule exec_act
;    (status (step ?i))
;    (exec (step ?i))
; => (pop-focus))

; alcune azioni per testare il sistema
; (assert (exec (step 0) (action Forward)))
; (assert (exec (step 1) (action Inform) (param1 T4) (param2 2) (param3 accepted)))
; (assert (exec (step 2) (action LoadDrink) (param1 7) (param2 7)))
; (assert (exec (step 3) (action LoadFood) (param1 7) (param2 5)))
; (assert (exec (step 4) (action Forward)))
; (assert (exec (step 5) (action DeliveryDrink) (param1 5) (param2 6)))
; (assert (exec (step 6) (action DeliveryFood) (param1 5) (param2 6)))
; (assert (exec (step 7) (action Inform) (param1 T3) (param2 20) (param3 delayed)))
; (assert (exec (step 8) (action Inform) (param1 T3) (param2 16) (param3 delayed)))
; (assert (exec (step 9) (action Turnleft)))
; (assert (exec (step 10) (action Turnleft)))
; (assert (exec (step 11) (action CleanTable) (param1 5) (param2 6)))
; (assert (exec (step 12) (action Forward)))
; (assert (exec (step 13) (action Forward)))
; (assert (exec (step 14) (action Release) (param1 8) (param2 7)))
; (assert (exec (step 15) (action EmptyFood) (param1 8) (param2 5)))
; (assert (exec (step 16) (action Release) (param1 8) (param2 7)))