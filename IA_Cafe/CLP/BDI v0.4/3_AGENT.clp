;// AGENT

(defmodule AGENT (import MAIN ?ALL) (export ?ALL))

(defglobal ?*SLOTS* = 4)

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

;### Template to store robot-accessible cells around Tables, FDs and so on ###
(deftemplate access-cell
    (slot object (allowed-values Table TB RB DD FD))
    (slot pos-r)
    (slot pos-c)
    (slot obj-r)
    (slot obj-c)
)

;### Action Execution History Template ###
(deftemplate exec-history 
	(slot step) 	
	(slot action  (allowed-values Forward Turnright Turnleft Wait 
                                      LoadDrink LoadFood DeliveryFood DeliveryDrink 
                                      CleanTable EmptyFood Release CheckFinish Inform))
    (slot param1)
    (slot param2)
    (slot param3)
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

(deftemplate intentions_changed
    (slot changed (allowed-values yes no))
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
    (declare (salience 20))
    (status (step 0))
    ;(not (exec (step 0)))
    ;#GUI#
    (not (init-agent (done yes))) 
    (prior-cell (pos-r ?r) (pos-c ?c) (contains ?x)) 
=>
    (assert (K-cell (pos-r ?r) (pos-c ?c) (contains ?x) (initial yes))) ;K-Cell iniziali  
    (assert (req-id-counter 0))
)
            
;Gets robot-accessible cells around FD, DD, Tables, etc.
(defrule  beginagent_map_accessible_object_cell_north
    (declare (salience 15))    
    (not (init-agent (done yes)))
    (K-cell (pos-r ?r) (pos-c ?c) (contains ?obj&~Wall&~Person&~Empty&~Parking&~Seat) (initial yes))
    (K-cell (pos-r ?r2&:(= ?r2(+ ?r 1))) (pos-c ?c) (contains ?obj2&Parking|Empty) (initial yes))
    =>
        (assert (access-cell (object ?obj) (obj-r ?r) (obj-c ?c) (pos-r ?r2) (pos-c ?c)))            
)

(defrule  beginagent_map_accessible_object_cell_south
    (declare (salience 15))    
    (not (init-agent (done yes)))
    (K-cell (pos-r ?r) (pos-c ?c) (contains ?obj&~Wall&~Person&~Empty&~Parking&~Seat) (initial yes))
    (K-cell (pos-r ?r2&:(= ?r2(- ?r 1))) (pos-c ?c) (contains ?obj2&Parking|Empty) (initial yes))
    =>
        (assert (access-cell (object ?obj) (obj-r ?r) (obj-c ?c) (pos-r ?r2) (pos-c ?c)))            
)

(defrule  beginagent_map_accessible_object_cell_east
    (declare (salience 15))    
    (not (init-agent (done yes)))
    (K-cell (pos-r ?r) (pos-c ?c) (contains ?obj&~Wall&~Person&~Empty&~Parking&~Seat) (initial yes))
    (K-cell (pos-r ?r) (pos-c ?c2&:(= ?c2(+ ?c 1))) (contains ?obj2&Parking|Empty) (initial yes))
    =>
        (assert (access-cell (object ?obj) (obj-r ?r) (obj-c ?c) (pos-r ?r) (pos-c ?c2)))            
)

(defrule  beginagent_map_accessible_object_cell_west
    (declare (salience 15))    
    (not (init-agent (done yes)))
    (K-cell (pos-r ?r) (pos-c ?c) (contains ?obj&~Wall&~Person&~Empty&~Parking&~Seat) (initial yes))
    (K-cell (pos-r ?r) (pos-c ?c2&:(= ?c2(- ?c 1))) (contains ?obj2&Parking|Empty) (initial yes))
    =>
        (assert (access-cell (object ?obj) (obj-r ?r) (obj-c ?c) (pos-r ?r) (pos-c ?c2)))            
)
;----
 
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
    (assert (intentions_changed (changed no)))
)

;### BDI Control Loop ###

; Initilization
(defrule BDI_loop_0
    (declare (salience 100))
    (not (AGENT__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (AGENT__init))
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
        (modify ?fs (step ?s)) ;For the GUI Step Mode
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
    (status (step ?s) (time ?t))        
    =>
        (retract ?bdis)
        ;### TODO: Deliberate 
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI - Deliberating !")))
        (focus DELIBERATE)
        (assert (BDistatus BDI-4))
)

; !!!!!!!!!!!!!!!!!!!!!!!!!!!
;### TODO !!!! Empty Plan ###
; !!!!!!!!!!!!!!!!!!!!!!!!!!!
;CHECK IF WORKS
;Planning required -> clear old plan actions
(defrule BDI_loop_4_planning_clear_old_plan_actions
    (declare (salience 81))
    ?bdis <- (BDistatus BDI-4)    
    ?pa <- (plan-action)  
    ?f <- (intentions_changed (changed yes))     
    =>
        (retract ?pa)        
)

;Planning required -> clear old basic actions
(defrule BDI_loop_4_planning_clear_old_basic_actions
    (declare (salience 81))
    ?bdis <- (BDistatus BDI-4)    
    ?pa <- (basic-action)  
    ?f <- (intentions_changed (changed yes))     
    =>
        (retract ?pa)        
)

;Planning
(defrule BDI_loop_4_planning
    (declare (salience 80))
    ?bdis <- (BDistatus BDI-4)    
    ?paseq <- (plan-actions-seq ?)
    (status (step ?s) (time ?t))   
    ?f <- (intentions_changed (changed yes))     
    =>
        (retract ?bdis)
        (modify ?f (changed no))
        ;### TODO: Plan if needed 
        (retract ?paseq)
        (assert (plan-actions-seq 0))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI - Planning !")))
        (focus PLANNER)
        (assert (BDistatus BDI-5))
)

;Planning not needed
(defrule BDI_loop_4_planning_not_needed
    (declare (salience 80))
    ?bdis <- (BDistatus BDI-4)    
    (status (step ?s) (time ?t))        
    =>
        (retract ?bdis)
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI - Planning not needed !")))
        (assert (BDistatus BDI-5))
)

;Head plan action useless (goto same position)
(defrule BDI_loop_5_plan_head_useless
    (declare (salience 76))
    ?bdis <- (BDistatus BDI-5)
    ?paseq-f <- (plan-actions-seq ?paseq)
    ?pa-f <- (plan-action (seq ?paseq)
            (action Goto)
            (param1 ?p1)
            (param2 ?p2)
            (param3 ?p3))
    (status (step ?s)) 
    (K-agent (step ?s) (pos-r ?p1) (pos-c ?p2))
    =>
        ;(retract ?bdis)
        (retract ?pa-f)
        (retract ?paseq-f) ;Advance Plan Action Sequence Counter
        (assert (plan-actions-seq (+ 1 ?paseq)))
        ;(assert (BDistatus BDI-EXEC-check-plan))
)

; !!!!!!!!!!!!!!!!!!!!!!!!!!!
;### DONE - CHECK !!!! Empty Basic Action ###
; !!!!!!!!!!!!!!!!!!!!!!!!!!!
;CHECK IF WORKS

;Actions-Planning
(defrule BDI_loop_5
    (declare (salience 75))
    ;### TODO: Check if needed to replan
    ?bdis <- (BDistatus BDI-5)
    ;(not (basic-action));### TODO: Add or condition (actions_retry_counter ?art&:(> ?art 0)))    
    (or (not (basic-action)) (actions_retry_counter ?art&:(> ?art 0)))    
    (plan-actions-seq ?seq)
    ?baseq-f <- (basic-actions-seq ?ba-seq)
    (plan-action (seq ?seq)
            (action ?plan-action)
            (param1 ?p1)
            (param2 ?p2)
            (param3 ?p3))
    (status (step ?s) (time ?t))        
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI - Actions planning for plan action (%p1,%p2,%p3,%p4)") (param1 ?plan-action) (param2 ?p1) (param3 ?p2) (param4 ?p3)))
        (retract ?bdis)
        (assert (ACTIONS-PLANNER-decode-action (action ?plan-action) (param1 ?p1) (param2 ?p2) (param3 ?p3)))
        (focus ACTIONS-PLANNER) ;Decode planning actions to basic actions
        (assert (BDistatus BDI-6))
        (retract ?baseq-f) ;Reset Basic Action Sequence Counter
        (assert (basic-actions-seq 0))
)

;Actions-Planning- No replan -> Execute next action if there is one
(defrule BDI_loop_5_no_replan_other_actions
    (declare (salience 74))
    ?bdis <- (BDistatus BDI-5)     
    ?baseq-f <- (basic-actions-seq ?ba-seq)   
    (basic-action)
    (status (step ?s) (time ?t))        
    =>
        (retract ?bdis)
        (assert (BDistatus BDI-6))
)

;Actions-Planning- No plan -> Wait
(defrule BDI_loop_5_no_plan
    (declare (salience 74))
    ?bdis <- (BDistatus BDI-5)     
    ?baseq-f <- (basic-actions-seq ?ba-seq)   
    (not (basic-action))
    (status (step ?s) (time ?t))        
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT") (verbosity 2) (text  "BDI - Nothing to do, will Wait !")))
        (assert (exec (step ?s) (action Wait))) ;Waiting action
        (retract ?baseq-f) ;Reset Basic Action Sequence Counter
        (assert (basic-actions-seq 0))
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-check-plan))
)

;####################### IMPORTANTE: Implementare il controllo sul forward in caso di persona !!! ed eventuale replan percorso ###################
;####################### IMPORTANTE: Implementare il controllo sul forward in caso di persona !!! ed eventuale replan percorso ###################
;####################### IMPORTANTE: Implementare il controllo sul forward in caso di persona !!! ed eventuale replan percorso ###################

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
    =>
        (retract ?bdis)
        (retract ?ba-f)
        (assert (exec (step ?s) (action ?action) (param1 ?p1) (param2 ?p2) (param3 ?p3)))
        (retract ?baseq-f) ;Advance Basic Action Sequence Counter
        (assert (basic-actions-seq (+ 1 ?baseq)))
        (assert (BDistatus BDI-EXEC-check-plan))
)

;Exec head basic action if possible (goto check)
;(defrule BDI_loop_6_possible_A_head_goto
;    (declare (salience 70))
;    ?bdis <- (BDistatus BDI-6)
;    ?baseq-f <- (basic-actions-seq ?baseq)
;    ?ba-f <- (basic-action
;                (seq ?baseq)
;                (action Forward)
;                (param1 ?p1)
;                (param2 ?p2)
;                (param3 ?p3))
;    (status (step ?s)) 
;    (K-agent (step ?s) (pos-r ?r) (pos-c ?c))
;    ;(K-cell (pos-r ?r 
;    =>
;        (retract ?bdis)
;        (retract ?ba-f)
;        (assert (exec (step ?s) (action ?action) (param1 ?p1) (param2 ?p2) (param3 ?p3)))
;        (retract ?baseq-f) ;Advance Basic Action Sequence Counter
;        (assert (basic-actions-seq (+ 1 ?baseq)))
;        (assert (BDistatus BDI-EXEC-check-plan))
;)

;Check Empty basic actions -> Remove plan -> next rule
(defrule BDI-EXEC-check-plan-empty
    (declare (salience 50))
    ?bdis <- (BDistatus BDI-EXEC-check-plan)
    (status (step ?i) (time ?t))
    (not (basic-action))
    ?paseq <- (plan-actions-seq ?seq)
    ?pa <- (plan-action (seq ?seq) (action ?action))
    =>
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "No more basic actions for plan action (%p1-%p2), removing plan action.") (param1 ?seq) (param2 ?action)))      
        (retract ?pa)
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-check-intention))   
        (retract ?paseq)
        (assert (plan-actions-seq (+ 1 ?seq)));Next Plan action           
)

;Check Empty basic actions -> plan not empy -> next rule
(defrule BDI-EXEC-check-plan-not-empy
    (declare (salience 50))
    ?bdis <- (BDistatus BDI-EXEC-check-plan)
    (status (step ?i) (time ?t))
    =>
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-check-intention))        
)

;Check Empty plan -> Remove intention and related desire -> execute action next rule
(defrule BDI-EXEC-check-intention-empty 
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

;Check Empty plan -> No more empty plan -> execute action next rule
(defrule BDI-EXEC-check-intention-end
    (declare (salience 40))
    ?bdis <- (BDistatus BDI-EXEC-check-intention)
    =>        
        (retract ?bdis)
        (assert (BDistatus BDI-EXEC-ACTION))              
)

;Executes Action and reset module initialization
(defrule BDI-EXEC-ACTION    
    (declare (salience 20))
    ?bdis <- (BDistatus BDI-EXEC-ACTION)
    (status (step ?i) (time ?t))
    (exec (step ?i) (action ?oper) (param1 ?p1) (param2 ?p2) (param3 ?p3))   
    ?f <- (AGENT__init) 
    =>
        (assert (exec-history (step ?i) (action ?oper) (param1 ?p1) (param2 ?p2) (param3 ?p3)))   
        (printout t crlf  "== AGENT ==" crlf) (printout t "Start the execution of the action: " ?oper)
        (assert (printGUI (time ?t) (step ?i) (source "AGENT") (verbosity 1) (text  "Start the execution of the action: %p1 (%p2,%p3,%p4)") (param1 ?oper) (param2 ?p1) (param3 ?p2) (param4 ?p3)))      
        (retract ?bdis)
        (assert (BDistatus BDI-0))      
        (retract ?f)
        (pop-focus)   
)

;### FATTO: Update belief upon action execution (robot loaded, table status, etc)
; Esempio:    Per le azioni di carico/scarico si può verificare il successo al giro successivo con la
;             percezione load. E' necessario tenere traccia dell'azione eseguita nell'istante precedente.
;             Non serve a molto perchè non funziona per cleantable e per scarico rifiuti.
;             Tuttavia, si può usare questo sistema per implementare il risultato della CheckFinish, che però
;             per ora non si ritiene utile usare.