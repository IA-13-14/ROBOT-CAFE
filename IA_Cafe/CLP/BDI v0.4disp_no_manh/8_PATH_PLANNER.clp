;######## MODULE: Path Planner Module
; Description:
;
;

;TODO: Replace PATH-PLANNER with the name of the module

;/-----------------------------------------------------------------------------------/
;/*****    GESTIONE PERCEZIONI AMBIENTE (e aggiornamento opportuni fatti)       *****/
;/-----------------------------------------------------------------------------------/
(defmodule PATH-PLANNER (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

;WARNING: Deftemplates used by AGENT must be defined in AGENT Module !


; Initilization
(defrule init-rule
    (declare (salience 100))
    (not (PATH-PLANNER__init))
    (status (step ?s) (time ?t))    
    =>
        (assert (PATH-PLANNER__init)) 
        (assert (PATH-PLANNER__runonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::PATH-PLANNER") (verbosity 2) (text  "PATH-PLANNER Module invoked")))
)

;UPDATE-BEL:runonce section
;(defrule clean-old-K-cell
;    (declare (salience 90))
;    (UPDATE-BEL:runonce)
    ;[...]
;)

;End UPDATE-BEL:runonce section
(defrule stop-runonce
    ?f <- (PATH-PLANNER__:runonce)
    =>
    (retract ?f)
)

;/-----------------------------------------------------------------------------------/
;/*****    PIANIFICAZIONE PERCORSO MOVIMENTO (Con ricerca A*)                   *****/
;/-----------------------------------------------------------------------------------/


(deftemplate node (slot ident) (slot gcost) (slot fcost) (slot father) (slot direction (allowed-values north south east west))
                  (slot pos-r) (slot pos-c) (slot open))
(deftemplate newnode (slot ident) (slot gcost) (slot fcost) (slot father) (slot direction (allowed-values north south east west))
                  (slot pos-r) (slot pos-c))

(deftemplate goal (slot direction (allowed-values north south east west any)) (slot pos-r) (slot pos-c))



;Regola per iniziare la ricerca, controllo posizione irraggiungibile
(defrule start-path-planning-check-unreachable
    ?f1 <- (start-path-planning (source-direction ?s-dir) (source-r ?s-r) (source-c ?s-c)
                                (dest-direction ?d-dir) (dest-c ?d-c) (dest-r ?d-r))
    (K-cell (pos-r ?d-r) (pos-c ?d-c) (contains ~Empty&~Parking))
    (status (step ?s) (time ?t)) 
    =>
    (retract ?f1)  
    (assert (path-planning-result (success no)))
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::PATH-PLANNER") (verbosity 2) (text  "Searching path from (%p1,%p2-%p3) to (%p4,%p5-%p6) - UNREACHEABLE DESTINATION !") (param1 ?s-r) (param2 ?s-c) (param3 ?s-dir) (param4 ?d-r) (param5 ?d-c) (param6 ?d-dir)))
    (pop-focus)
)

;Regola per iniziare la ricerca
(defrule start-path-planning-check
    ?f1 <- (start-path-planning (source-direction ?s-dir) (source-r ?s-r) (source-c ?s-c)
                                (dest-direction ?d-dir) (dest-c ?d-c) (dest-r ?d-r) (ignore-perceptions ?ip))
    (status (step ?s) (time ?t)) 
    =>
    (retract ?f1)
    (assert (ignore-perceptions ?ip))
    ;Inizializza stato iniziale
    (assert (node (ident 0) (gcost 0) (fcost 0) (father NA) (direction ?s-dir) (pos-r ?s-r) (pos-c ?s-c) (open yes))) 
    (assert (current 0))
    (assert (lastnode 0))
    (assert (open-worse 0))
    (assert (open-better 0))
    (assert (alreadyclosed 0))
    (assert (numberofnodes 0))
    ;Inizializza goal
    (assert (goal (direction ?d-dir) (pos-r ?d-r) (pos-c ?d-c)))

    (assert (printGUI (time ?t) (step ?s) (source "AGENT::PATH-PLANNER") (verbosity 2) (text  "Searching path from (%p1,%p2-%p3) to (%p4,%p5-%p6)") (param1 ?s-r) (param2 ?s-c) (param3 ?s-dir) (param4 ?d-r) (param5 ?d-c) (param6 ?d-dir)))
)

;Controllo arrivato al goal
(defrule achieved-goal-any-dir
    (declare (salience 100))
    (current ?id)
    (goal (direction any) (pos-r ?r) (pos-c ?c))
    (node (ident ?id) (pos-r ?r) (pos-c ?c) (gcost ?g))  
    
    =>
   ;(halt); for debug purpose
    (printout t "(HALTED FOR DEBUG) Esiste soluzione per goal (" ?r "," ?c ") con costo "  ?g crlf)
    (assert (stampa ?id 0 -1))
    (assert (path-planning-result (success yes) (cost ?g)))
)

;Controllo arrivato al goal
(defrule achieved-goal
    (declare (salience 100))
    (current ?id)
    (goal (direction ?dir) (pos-r ?r) (pos-c ?c))
    (node (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g))  
    
    =>
    ;(halt); for debug purpose
    (printout t "(HALTED FOR DEBUG) Esiste soluzione per goal (" ?r "," ?c ") con costo "  ?g crlf)
    (assert (stampa ?id 0 -1))
    (assert (path-planning-result (success yes) (cost ?g)))
)

;Stampa soluzione
(defrule stampaSol
(declare (salience 110))
?f<-(stampa ?id ?seq ?rev)
    (node (ident ?id) (father ?anc&~NA))  
    (pp-exec ?anc ?id ?oper ?r ?c)
=> (printout t " " ?seq ") Eseguo azione " ?oper " da stato (" ?r "," ?c ") " crlf)
   (assert (path-planning-action (sequence ?rev) (operator ?oper)))
   (assert (stampa ?anc (+ 1 ?seq) (- ?rev 1)))
   (retract ?f)
)

;Inverti ordine soluzione
(defrule invertiStampaSol
    (declare (salience 105))
    ?f<-(stampa ?id ?seq ?rev)
    ?f1<-(path-planning-action (sequence ?act-seq&:(< ?act-seq 0)))
    =>
        (modify ?f1 (sequence (+ ?act-seq ?seq)))
        ;(retract ?f)       
        ;(assert (stampa ?id ?seq (+ ?rev 1)))       
)

;Stampa soluzione fine
(defrule stampa-fine
    (declare (salience 102))
       ?f <- (stampa ?id $?)
       (node (ident ?id) (father ?anc&NA))
       (open-worse ?worse)
       (open-better ?better)
       (alreadyclosed ?closed)
       (numberofnodes ?n )  
=> (printout t " stati espansi " ?n crlf)
   (printout t " stati generati gi� in closed " ?closed crlf)
   (printout t " stati generati gi� in open (open-worse) " ?worse crlf)
   (printout t " stati generati gi� in open (open-better) " ?better crlf)
   (assert (ppclean))
   (retract ?f)
;   (pop-focus)
)

(defrule clean-path-planning-node
    (declare (salience 1000))
    (ppclean)
    ?f <- (node (ident ?i))
    => (retract ?f))
(defrule clean-pp-pp-exec
    (declare (salience 1000))
    (ppclean)
    ?f <- (pp-exec $?)
    => (retract ?f))
(defrule clean-pp-apply
    (declare (salience 1000))
    (ppclean)
    ?f <- (apply $?)
    => (retract ?f))
(defrule clean-pp-current
    (declare (salience 1000))
    (ppclean)
    ?f <- (current $?)
    => (retract ?f))
(defrule clean-pp-lastnode
    (declare (salience 1000))
    (ppclean)
    ?f <- (lastnode $?)
    => (retract ?f))
(defrule clean-pp-open-worse
    (declare (salience 1000))
    (ppclean)
    ?f <- (open-worse $?)
    => (retract ?f))
(defrule clean-pp-open-better
    (declare (salience 1000))
    (ppclean)
    ?f <- (open-better $?)
    => (retract ?f))
(defrule clean-pp-alreadyclosed
    (declare (salience 1000))
    (ppclean)
    ?f <- (alreadyclosed $?)
    => (retract ?f))
(defrule clean-pp-numberofnodes
    (declare (salience 1000))
    (ppclean)
    ?f <- (numberofnodes $?)
    => (retract ?f))
(defrule clean-pp-goal
    (declare (salience 1000))
    (ppclean)
    ?f <- (goal (direction ?d))
    => (retract ?f))
(defrule clean-ignore-perceptions
    (declare (salience 1000))
    (ppclean)
    ?f <- (ignore-perceptions)
    => (retract ?f))
(defrule clean-pp-end
    (declare (salience 999))
    ?f <- (ppclean)
    ?fi <- (PATH-PLANNER__init)
    =>
    (retract ?f)
    (retract ?fi)
    ;(halt)
    (pop-focus)
)

;-----------------OPERATORI--------------

(defrule forward-apply-north
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction north) (pos-r ?r) (pos-c ?c) (open yes))
        (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains Empty|Parking)) ;Cella presa dalla Kbase dell'agent
		(not (K-cell (pos-r =(+ ?r 1)) (pos-c ?c) (contains ~Empty&~Parking))) ;non esiste percezione con cella occupata
        =>
        (assert (apply ?curr up ?r ?c))
)

;ATTENZIONE ai costi e alle direction !
(deffunction h-cost (?r ?c ?d-r ?d-c)
    (* 2 (+ (abs (- ?d-r ?r)) (abs (- ?d-c ?c)) ))
)

(deffunction f-cost(?r ?c ?d-r ?d-c ?g ?a-g)
    (+ (+ ?g ?a-g) (h-cost ?r ?c ?d-r ?d-c) )
)

(defrule up-exec
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr up ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 1) fwd-up ?r ?c)
        (newnode (ident (+ ?n 1));regola 1
                 (direction ?dir) (pos-r (+ ?r 1)) (pos-c ?c) 
                 (gcost (+ ?g 2)) (fcost (f-cost (+ ?r 1) ?c ?x ?y ?g 2)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)

;Move south
(defrule forward-apply-south
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction south) (pos-r ?r) (pos-c ?c) (open yes))
        (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains Empty|Parking)) ;Cella presa dalla Kbase dell'agent
		(or (ignore-perceptions yes) (not (K-cell (pos-r =(- ?r 1)) (pos-c ?c) (contains ~Empty&~Parking)))) ;non esiste percezione con cella occupata
        =>
        (assert (apply ?curr down ?r ?c))
)

(defrule down-exec
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr down ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 1) fwd-down ?r ?c)
        (newnode (ident (+ ?n 1));azione 1 (down è solo variante di north ma l'azione è Forward)
                 (direction ?dir) (pos-r (- ?r 1)) (pos-c ?c) 
                 (gcost (+ ?g 2)) (fcost (f-cost (- ?r 1) ?c ?x ?y ?g 2)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)

;Move east
(defrule forward-apply-east
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction east) (pos-r ?r) (pos-c ?c) (open yes))
        (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains Empty|Parking)) ;Cella presa dalla Kbase dell'agent
		(not (K-cell (pos-r ?r) (pos-c =(+ ?c 1)) (contains ~Empty&~Parking))) ;non esiste percezione con cella occupata
        =>
        (assert (apply ?curr right ?r ?c))
)

(defrule left-exec
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr left ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 1) fwd-left ?r ?c)
        (newnode (ident (+ ?n 1));azione 1 (down è solo variante di north ma l'azione è Forward)
                 (direction ?dir) (pos-r ?r) (pos-c (- ?c 1)) 
                 (gcost (+ ?g 2)) (fcost (f-cost ?r (- ?c 1) ?x ?y ?g 2)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)

;Move west
(defrule forward-apply-west
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction west) (pos-r ?r) (pos-c ?c) (open yes))
        (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains Empty|Parking)) ;Cella presa dalla Kbase dell'agent
		(not (K-cell (pos-r ?r) (pos-c =(- ?c 1)) (contains ~Empty&~Parking))) ;non esiste percezione con cella occupata
        =>
        (assert (apply ?curr left ?r ?c))
)

(defrule right-exec
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr right ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 1) fwd-right ?r ?c)
        (newnode (ident (+ ?n 1));azione 1 (down è solo variante di north ma l'azione è Forward)
                 (direction ?dir) (pos-r ?r) (pos-c (+ ?c 1)) 
                 (gcost (+ ?g 2)) (fcost (f-cost ?r (+ ?c 1) ?x ?y ?g 2)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)

;-----------TURN ACTION---------------
(deffunction turn-value-left (?dir)
    (switch ?dir
      (case north then west)
      (case west then south)
      (case south then east)
      (case east then north)
    )
)

(deffunction turn-value-right (?dir)
    (switch ?dir
      (case north then east)
      (case east then south)
      (case south then west)
      (case west then north)
    )
)

;Turn left
(defrule turn-apply-left
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction ?dir) (pos-r ?r) (pos-c ?c) (open yes))

        =>
        (assert (apply ?curr turn left ?r ?c))
)

(defrule turn-exec-left
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr turn left ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 2) turn-left ?r ?c)
        (newnode (ident (+ ?n 2));azione 2 TurnLeft
                 (direction (turn-value-left ?dir)) 
                 (pos-r ?r) (pos-c ?c) 
                 (gcost (+ ?g 1)) (fcost (f-cost ?r ?c ?x ?y ?g 1)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)

;Turn right
(defrule turn-apply-right
        (declare (salience 50))
        (current ?curr)
        (node (ident ?curr) (direction ?dir) (pos-r ?r) (pos-c ?c) (open yes))

        =>
        (assert (apply ?curr turn right ?r ?c))
)

(defrule turn-exec-right
        (declare (salience 50))
        (current ?curr)
        (lastnode ?n)
 ?f1<-  (apply ?curr turn right ?r ?c)
        (node (ident ?curr) (gcost ?g) (direction ?dir))
        (goal (pos-r ?x) (pos-c ?y))
        
        =>
        (assert (pp-exec ?curr (+ ?n 3) turn-right ?r ?c)
        (newnode (ident (+ ?n 3));azione 3 TurnLeft
                 (direction (turn-value-right ?dir)) 
                 (pos-r ?r) (pos-c ?c) 
                 (gcost (+ ?g 1)) (fcost (f-cost ?r ?c ?x ?y ?g 1)) ;h(x)=distanza di Manhattan * 2
                 (father ?curr)))
        (retract ?f1)
        (focus PATH_PLANNING_NEW)
)
;-----------------ALGORITMO A*-----------
; Scelta del nodo migliore (coda con priorità !)
; C'è nodo open e non esiste altro nodo diverso da questo, tale che abbia costo minore.
(defrule change-current
         (declare (salience 49))
?f1 <-   (current ?curr)
?f2 <-   (node (ident ?curr))
         (node (ident ?best&:(neq ?best ?curr)) (fcost ?bestcost) (open yes))
         (not (node (ident ?id&:(neq ?id ?curr)) (fcost ?gg&:(< ?gg ?bestcost)) (open yes)))
?f3 <-   (lastnode ?last)
   =>    (assert (current ?best) (lastnode (+ ?last 4))) ;ATTENZIONE: 4= numero azioni + 1 !!!!!
         (retract ?f1 ?f3)
         (modify ?f2 (open no))) 

;Ricerca inconcludente (non ho più nodi open da esplorare)
(defrule open-empty
         (declare (salience 49))
?f1 <-   (current ?curr)
?f2 <-   (node (ident ?curr))
         (not (node (ident ?id&:(neq ?id ?curr))  (open yes)))
     => 
         (retract ?f1)
         (modify ?f2 (open no))
         (printout t "(HALTED FOR DEBUG) fail (last  node expanded " ?curr ")" crlf)
         ;(halt)
         (assert (path-planning-result (success no)))
         (assert (ppclean))
)   

;Eseguito ad ogni nuova applicazione di una azione (EXEC)
(defmodule PATH_PLANNING_NEW (import PATH-PLANNER ?ALL) (export ?ALL))

;Se ho generato un nuovo nodo già in closed lo scarto.
;ATTENZIONE: Questo sistema funziona solo con euristica CONSISTENTE !
(defrule check-closed
(declare (salience 50)) 
 ?f1 <-    (newnode (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c))
           (node (ident ?old) (direction ?dir) (pos-r ?r) (pos-c ?c) (open no))
 ?f2 <-    (alreadyclosed ?a) ;solo contatore, ignorare
    =>
           (assert (alreadyclosed (+ ?a 1)))
           (retract ?f1)
           (retract ?f2)
           (pop-focus))

;Controllo se ho generato un nuovo nodo che ha costo maggiore di uno medesimo già esistente, allora lo scarto.
(defrule check-open-worse
(declare (salience 50)) 
 ?f1 <-    (newnode (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g) (father ?anc))
           (node (ident ?old) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g-old) (open yes))
           (test (or (> ?g ?g-old) (= ?g-old ?g)))
 ?f2 <-    (open-worse ?a)
    =>
           (assert (open-worse (+ ?a 1)))
           (retract ?f1)
           (retract ?f2)
           (pop-focus))

;Controllo se ho generato un nuovo nodo che ha costo minore di uno medesimo già esistente, allora aggiorno il nodo esistente,
; mettendolo in open (utile se fosse stato in closed)
(defrule check-open-better
(declare (salience 50)) 
 ?f1 <-    (newnode (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g) (fcost ?f) (father ?anc))
 ?f2 <-    (node (ident ?old)(direction ?dir)  (pos-r ?r) (pos-c ?c) (gcost ?g-old) (open yes))
           (test (<  ?g ?g-old))
 ?f3 <-    (open-better ?a)
    =>     (assert (node (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g) (fcost ?f) (father ?anc) (open yes))
                   )
           (assert (open-better (+ ?a 1)))
           (retract ?f1 ?f2 ?f3)
           (pop-focus))

;Nessuno dei casi precedenti, allora aggiungi il nuovo nodo agli open.
(defrule add-open
       (declare (salience 49))
 ?f1 <-    (newnode (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g) (fcost ?f)(father ?anc))
 ?f2 <-    (numberofnodes ?a)
    =>     (assert (node (ident ?id) (direction ?dir) (pos-r ?r) (pos-c ?c) (gcost ?g) (fcost ?f)(father ?anc) (open yes))
                   )
           (assert (numberofnodes (+ ?a 1)))
           (retract ?f1 ?f2)
           (pop-focus))             