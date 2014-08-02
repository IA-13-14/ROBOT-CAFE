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

;#### INTENTIONS Template ####
(deftemplate intention
    (slot step)
    (slot time)
    (slot accepted-time)
    (slot accepted-step)
    (slot table)
    (slot type (allowed-values order clean))
    (slot order (default NA))
    (slot desire) ;Desire indexed with time
)

;#### PLAN-ACTIONS Template ####
; Azioni complesse prodotte dalla pianificazione (es Goto e Load/Delivery parametriche)
(deftemplate plan-action
    (slot seq)
    (slot action  (allowed-values Goto Wait LoadDrink LoadFood DeliveryFood DeliveryDrink 
                                      CleanTable EmptyFood EmptyDrink CheckFinish Inform))
        (slot param1)
        (slot param2)
        (slot param3)
)
;Goto (x,y)
;LoadDrink, LoadFood (dispenser x, y, qty [1,4])
;DeliveryDrink, DeliveryFood (table x, y, qty [1,4])
;CleanTable (table x, y)
;EmptyFood (trashbin x, y)
;EmptyDrink (reciclebin x, y)
;CheckFinish (table x, y)

;#### BASIC-ACTIONS Template ####
; Azioni elementari direttamente eseguibili dall'agente
(deftemplate basic-action
    (slot seq)
	(slot action  (allowed-values Forward Turnright Turnleft Wait 
                                      LoadDrink LoadFood DeliveryFood DeliveryDrink 
                                      CleanTable EmptyFood Release CheckFinish Inform))
        (slot param1)
        (slot param2)
        (slot param3)
)
;#### MODULE ACTIONS_PLANNER Templates ####
(deftemplate ACTIONS-PLANNER-decode-action   
        (slot action  (allowed-values Goto Wait LoadDrink LoadFood DeliveryFood DeliveryDrink 
                                      CleanTable EmptyFood EmptyDrink CheckFinish Inform))
        (slot param1)
        (slot param2)
        (slot param3)
)

;#### MODULE PATH_PLANNER Templates ####
(deftemplate start-path-planning (slot source-direction (allowed-values north south east west)) (slot source-r) (slot source-c)
                                 (slot dest-direction (allowed-values north south east west any)) (slot dest-r) (slot dest-c))

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
    (assert (AGENT__runonce))
    (assert (forward_action_retry_counter 0))
    (assert (plan-actions-seq 0))
    (assert (basic-actions-seq 0))
)

 ;### BDI Control Loop ###

; Initilization
(defrule BDI_loop_0
    (declare (salience 100))
    (not (init))
    (status (step ?s) (time ?t))    
    =>
        (assert (init))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI Loop started !")))
        (assert (actions_retry_counter 0))
        (assert (BDistatus BDI-1))
)

;Update Belief
(defrule BDI_loop_1
    (declare (salience 95))
    ?bdis <- (BDistatus BDI-1)
    (status (step ?s))
    ?fs <- (last-perc (step ?old-s))    
    (test (> ?s ?old-s))
    =>
        (retract ?bdis)
        (assert (BDistatus BDI-2))
        (focus UPDATE-BEL)    ;Update Belief Module Invoked
)


;### TODO: answer to new orders immediately and goto 0 !!!!
(defrule BDI_loop_2_check_answer_order
    (declare (salience 90))
    ?bdis <- (BDistatus BDI-2)
    ?ansor <- (answer-to-order (step ?os) (time ?ot) (order ?req-id))
    (order (step ?os) (time ?ot) (req-id ?req-id) (table ?otable) (food ?ofood) (drink ?odrink))
    (status (step ?s))        
    =>
        (retract ?bdis)
        (retract ?ansor)
        ;### TODO: Decidere se accettare o meno
        (assert (exec (step ?s) (action Inform) (param1 ?otable) (param2 ?req-id) (param3 accepted)))  
        (assert (BDistatus BDI-EXEC-ACTION)) ;Execute action and reset
)

(defrule BDI_loop_2_no_answer_order
    (declare (salience 90))
    ?bdis <- (BDistatus BDI-2)          
    =>
        (retract ?bdis)
        (assert (BDistatus BDI-3))
)

; (defrule ask_act
;    ?f <-   (status (step ?i))
;    ?bdis <- (BDistatus 1)
;    =>  (printout t crlf crlf)
;        (printout t "action to be executed at step:" ?i)
;        (printout t crlf crlf)
;        (modify ?f (result no))
;        (retract ?bdis)
;        (assert (BDistatus 2))
;)

;Deliberation
(defrule BDI_loop_3
    (declare (salience 85))
    ?bdis <- (BDistatus BDI-3)    
    (status (step ?s))        
    =>
        (retract ?bdis)
        ;### TODO: Deliberate 
        (assert (BDistatus BDI-4))
)

;Planning
(defrule BDI_loop_4
    (declare (salience 80))
    ?bdis <- (BDistatus BDI-4)    
    (status (step ?s))        
    =>
        (retract ?bdis)
        ;### TODO: Plan if needed 
        (assert (BDistatus BDI-5))
)

;Actions-Planning
(defrule BDI_loop_5
    (declare (salience 75))
    ;### TODO: Check if needed to replan
    ?bdis <- (BDistatus BDI-5)
    (not (basic-actions));### TODO: Add or condition (actions_retry_counter ?art&:(> ?art 0)))    
    (plan-actions-seq ?seq)
    ?baseq-f <- (basic-actions-seq ?ba-seq)
    (plan-action (seq ?seq)
            (action ?plan-action)
            (param1 ?p1)
            (param2 ?p2)
            (param3 ?p3))
    (status (step ?s))        
    =>
        (retract ?bdis)
        (assert (ACTIONS-PLANNER-decode-action (action ?plan-action) (param1 ?p1) (param2 ?p2) (param3 ?p3)))
        (focus ACTIONS-PLANNER) ;Decode planning actions to basic actions
        (assert (BDistatus BDI-6))
        (retract ?baseq-f) ;Reset Basic Action Sequence Counter
        (assert (basic-actions-seq 0))
)

;Exec head basic action if possible
(defrule BDI_loop_6_possible_A_head
    (declare (salience 70))
    ?bdis <- (BDistatus BDI-6)
    ?baseq-f <- (basic-actions-seq ?baseq)
    ?ba-f <- (basic-action
                (seq ?baseq)
                (action ?action)
                (param1 ?p1)
                (param2 ?p2)
                (param3 ?p3))
    (status (step ?s)) 
    ;### TODO: Check if action is possible
    =>
        (retract ?bdis)
        (retract ?ba-f)
        (assert (exec (step ?s) (action ?action)))
        (retract ?baseq-f) ;Advance Basic Action Sequence Counter
        (assert (basic-actions-seq (+ 1 ?baseq)))
        (assert (BDistatus BDI-EXEC-check-plan))
)

;Check Empty basic actions -> Remove plan -> next rule
(defrule BDI-EXEC-check-plan  
    (declare (salience 50))
    ?bdis <- (BDistatus BDI-EXEC-check-plan)
    (status (step ?i) (time ?t))
    (not (basic-action))
    ?pa <- (plan-action (seq ?seq) (action ?action))
    =>
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "No more basic actions for plan action (%p1-%p2), removing plan action.") (param1 ?seq) (param2 ?action)))      
        (retract ?pa)
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-check-intention))              
)

;Check Empty plan -> Remove intention and related desire -> execute action next rule
(defrule BDI-EXEC-check-intention  
    (declare (salience 45))
    ?bdis <- (BDistatus BDI-EXEC-check-intention)
    (status (step ?i) (time ?t))
    (not (plan-action))
    ?intention <- (intention (desire ?des-t))
    ?desire <- (desire (time ?des-t))
    =>
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "No more plan actions for intention (%p1), removing intention and desire.") (param1 ?des-t)))      
        (retract ?intention)
        (retract ?desire)            
)

(defrule BDI-EXEC-check-intention-end
    (declare (salience 40))
    ?bdis <- (BDistatus BDI-EXEC-check-intention)
    =>        
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-ACTION))              
)

;(defrule path-planner-result-exec-step
;    (declare (salience 48))
;    (status (step ?s) (time ?t))
;    (not (exec (step ?s)))
;    (path-planning-result (success yes))
;    ?f <- (path-planner-seq ?seq)
;    (path-planning-action (sequence ?seq) (operator ?oper))
;    =>
;        (printout t " " ?seq ") Eseguo azione " ?oper " da stato " crlf)
;        (retract ?f)
;        (assert (path-planner-seq (+ 1 ?seq)))
;        (assert (exec (step ?s) (action (pp-oper-decode ?oper))))
;)   

;IMPORTANT: Assert one action per step, actions for future steps will be executed without returning to the agent.
;(defrule BDI_loop_3_default
;    ;(declare (salience 100))
;    (status (step ?s))
;    ?bdis <- (BDistatus 2)
;    ?fs <- (last-perc (step ?old-s))
;    (not (exec (step ?s)))
;    =>        
;        (modify ?fs (step ?s))
;        (retract ?bdis)
;        (assert  (BDistatus 0))
;        (assert (exec (step ?s) (action Wait)))    
; )   

;(defrule BDI_loop_3
;    ;(declare (salience 100))
;    (status (step ?s))
;    ?bdis <- (BDistatus 2)
;    ?fs <- (last-perc (step ?old-s))
;    =>        
;        (modify ?fs (step ?s))
;        (retract ?bdis)
;        (assert  (BDistatus 0))        
; )   



;Executes Action and reset module initialization
(defrule BDI-EXEC-ACTION    
    (declare (salience 20))
    ?bdis <- (BDistatus BDI-EXEC-ACTION)
    (status (step ?i) (time ?t))
    (exec (step ?i) (action ?oper))   
    ?f <- (init) 
    =>
        (printout t crlf  "== AGENT ==" crlf) (printout t "Start the execution of the action: " ?oper)
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "Start the execution of the action: %p1") (param1 ?oper)))      
        (retract ?bdis)
        (assert (BDistatus BDI-0))      
        (retract ?f)
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