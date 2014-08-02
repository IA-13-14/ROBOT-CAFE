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


;#### DESIRES Template ####
(deftemplate desire
    (slot step)
    (slot time)
    (slot table)
    (slot type (allowed-values order clean))
    (slot order (default NA))
)

;#### ANSWER-TO-ORDER Template ####
(deftemplate answer-to-order
    (slot step)
    (slot time)
    (slot order)
)

;#### ANSWER-TO-ORDER Template ####
(deftemplate order
    (slot req-id)
    (slot step)
    (slot time)
    (slot table)    
    (slot food)
    (slot drink)
)

;#### MODULE PATH_PLANNER Templates ####
(deftemplate start-path-planning (slot source-direction (allowed-values north south east west)) (slot source-r) (slot source-c)
                                 (slot dest-direction (allowed-values north south east west)) (slot dest-r) (slot dest-c))

(deftemplate path-planning-action (slot sequence) (slot operator))
(deftemplate path-planning-result (slot success (allowed-values yes no)))

;End -- #### MODULE PATH_PLANNER Templates ####

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
    (assert (AGENT__runonce))
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


(defrule test-path-planner
    (declare (salience 50))
    ?f <- (AGENT__runonce)
    (status (step ?s))
    (K-agent (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction ?dir)) ;prova PATH_PLANNER
    (Table (table-id T4) (pos-r ?dr) (pos-c ?dc)) ;prova PATH_PLANNER
    =>
        (retract ?f)

        ;prova PATH_PLANNER
        (assert (start-path-planning (source-direction ?dir) (source-r ?r) (source-c ?c)
                                 (dest-direction ?dir) (dest-r (+ 1 ?dr)) (dest-c ?dc)))
        (focus PATH-PLANNER)
        (assert (path-planner-seq 1))
)

(defrule path-planner-result
    (declare (salience 49))
    (path-planning-result (success yes))
    (path-planning-action (sequence ?seq) (operator ?oper))
    =>
        (printout t " " ?seq ") PP azione " ?oper )
        ;(retract ?f)
)

(deffunction pp-oper-decode (?oper)
    (switch ?oper
      (case fwd-up then Forward)
      (case fwd-down then Forward)
      (case fwd-left then Forward)
      (case fwd-right then Forward)
      (case turn-left then Turnleft)
      (case turn-right then Turnright)
    )
)

(defrule path-planner-result-exec-step
    (declare (salience 48))
    (status (step ?s) (time ?t))
    (not (exec (step ?s)))
    (path-planning-result (success yes))
    ?f <- (path-planner-seq ?seq)
    (path-planning-action (sequence ?seq) (operator ?oper))
    =>
        (printout t " " ?seq ") Eseguo azione " ?oper " da stato " crlf)
        (retract ?f)
        (assert (path-planner-seq (+ 1 ?seq)))
        (assert (exec (step ?s) (action (pp-oper-decode ?oper))))
)   

;IMPORTANT: Assert one action per step, actions for future steps will be executed without returning to the agent.
(defrule BDI_loop_3_default
    ;(declare (salience 100))
    (status (step ?s))
    ?bdis <- (BDistatus 2)
    ?fs <- (last-perc (step ?old-s))
    (not (exec (step ?s)))
    =>        
        (modify ?fs (step ?s))
        (retract ?bdis)
        (assert  (BDistatus 0))
        (assert (exec (step ?s) (action Wait)))    
 )   

(defrule BDI_loop_3
    ;(declare (salience 100))
    (status (step ?s))
    ?bdis <- (BDistatus 2)
    ?fs <- (last-perc (step ?old-s))
    =>        
        (modify ?fs (step ?s))
        (retract ?bdis)
        (assert  (BDistatus 0))        
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