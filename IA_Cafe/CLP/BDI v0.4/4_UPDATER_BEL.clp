;######## Belief Updater Module

;/-----------------------------------------------------------------------------------/
;/*****    GESTIONE PERCEZIONI AMBIENTE (e aggiornamento opportuni fatti)       *****/
;/-----------------------------------------------------------------------------------/
(defmodule UPDATE-BEL (import MAIN ?ALL) (import AGENT ?ALL) (export ?ALL))

; Initilization
(defrule init-rule-new-step
    (declare (salience 100))
    (not (UPDATER-BEL__init))
    (status (step ?s) (time ?t)) 
    (K-agent (step ?o-s)
                (time ?o-t)
                (pos-r ?o-r) 
            	(pos-c ?o-c) 
            	(direction ?o-dir) 
            	(l-drink ?o-ld)
                (l-food ?o-lf)
                (l_d_waste ?o-ldw)
                (l_f_waste ?o-lfw)
    )
    (not (K-agent (step ?s) (time ?t)))
    =>
        (assert (UPDATER-BEL__init)) 
        (assert (UPDATER-BEL__runonce))
        (assert (UPDATER-BEL__exec-history-runonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "UPDATER-BEL Module invoked")))
        (assert (K-agent (step ?s)
                    (time ?t) 
                    (pos-r ?o-r) 
                	(pos-c ?o-c) 
                	(direction ?o-dir) 
                	(l-drink ?o-ld)
                    (l-food ?o-lf)
                    (l_d_waste ?o-ldw)
                    (l_f_waste ?o-lfw))
        )
)

(defrule init-rule-no-new-step
    (declare (salience 100))
    (not (UPDATER-BEL__init))
    (status (step ?s) (time ?t))  
    =>
        (assert (UPDATER-BEL__init)) 
        (assert (UPDATER-BEL__runonce))
        (assert (UPDATER-BEL__exec-history-runonce))
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "UPDATER-BEL Module invoked")))
)

;Regola per rimuovere le vecchie percezioni, ormai obsolete
(defrule clean-old-K-cell
    (declare (salience 90))
    (runonce)
    ?f <- (K-cell (initial no))
    =>
    (retract ?f)
)

(defrule stop-runonce
    ?f <- (UPDATER-BEL__runonce)
    =>
    (retract ?f)
)

; Regola per aggiornare il believe-state dell'ambiente (K-cell) in base alle percezioni dell'agente
; in questo caso se l'agente si muove verso WEST.
(defrule  perc-west
    ?ka <- (K-agent (step ?s) (time ?t))
    (status (step ?s)) ;sono nello stato (clock) ?s
    ?p <- (perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction west) ;c'è una percezione in questo stato (per direzione west)
            (perc1 ?x1) (perc2 ?x2) (perc3 ?x3)
			(perc4 ?x4) (perc5 ?x5) (perc6 ?x6)
			(perc7 ?x7) (perc8 ?x8) (perc9 ?x9)
    ) ;estraggo tutte le percezioni delle celle adiacenti


    =>
    ;si modifica il believe-state (attenzione alla configurazione delle celle che varia a seconda della direzione 
    ;dell'agente, in questo caso WEST - inoltre vanno portate da posizione relativa all'agente a quella assoluta di K-cell):
    ;    3    6    9
    ;    2  <-5    8
    ;    1    4    7
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (- ?c 1)) (contains ?x1))) ;perc1
    (assert (K-cell (pos-r ?r)       (pos-c (- ?c 1)) (contains ?x2))) ;perc2
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (- ?c 1)) (contains ?x3))) ;perc3
    (assert (K-cell (pos-r (- ?r 1)) (pos-c ?c)       (contains ?x4))) ;perc4
    (assert (K-cell (pos-r ?r)       (pos-c ?c)       (contains ?x5))) ;perc5
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c ?c)       (contains ?x6))) ;perc6
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (+ ?c 1)) (contains ?x7))) ;perc7
    (assert (K-cell (pos-r ?r)       (pos-c (+ ?c 1)) (contains ?x8))) ;perc8
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (+ ?c 1)) (contains ?x9))) ;perc9
    
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Watch position (%p1,%p2), direction (west)") (param1 ?r) (param2 ?c)))    
    
    (retract ?p) ; Elimina la percezione originale così da non ripetere l'aggiornamento (tanto ormai è diventata inutile !)

    (modify ?ka (pos-r ?r) (pos-c ?c) (direction west)) ;update K-agent
)

; Vedi precedente, caso EAST.
(defrule perc-east
    ?ka <- (K-agent (step ?s) (time ?t))
    (status (step ?s))
    ?p <- (perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction east)
            (perc1 ?x9) (perc2 ?x8) (perc3 ?x7)
			(perc4 ?x6) (perc5 ?x5) (perc6 ?x4)
			(perc7 ?x3) (perc8 ?x2) (perc9 ?x1)
    )
    ;ATTENZIONE !! Riordino le variabili per non cambiare i numeri di r e c delle celle:
    ;    DIR WEST
    ;    3    6    9
    ;    2  <-5    8
    ;    1    4    7
    ;    DIR EAST
    ;    7    4    1
    ;    8    5->  2
    ;    9    6    3  (vedi ordine ?x in perc)

    =>
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (- ?c 1)) (contains ?x1))) ;perc1
    (assert (K-cell (pos-r ?r)       (pos-c (- ?c 1)) (contains ?x2))) ;perc2
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (- ?c 1)) (contains ?x3))) ;perc3
    (assert (K-cell (pos-r (- ?r 1)) (pos-c ?c)       (contains ?x4))) ;perc4
    (assert (K-cell (pos-r ?r)       (pos-c ?c)       (contains ?x5))) ;perc5
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c ?c)       (contains ?x6))) ;perc6
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (+ ?c 1)) (contains ?x7))) ;perc7
    (assert (K-cell (pos-r ?r)       (pos-c (+ ?c 1)) (contains ?x8))) ;perc8
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (+ ?c 1)) (contains ?x9))) ;perc9

    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Watch position (%p1,%p2), direction (east)") (param1 ?r) (param2 ?c)))    
    
    (retract ?p)

    (modify ?ka (pos-r ?r) (pos-c ?c) (direction east)) ;update K-agent
)

; Vedi precedente, caso NORTH.
(defrule perc-north
    ?ka <- (K-agent (step ?s) (time ?t))
    (status (step ?s))
    ?p <- (perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction north)
      		(perc1 ?x3) (perc2 ?x6) (perc3 ?x9)
			(perc4 ?x2) (perc5 ?x5) (perc6 ?x8)
			(perc7 ?x1) (perc8 ?x4) (perc9 ?x7)
    ) 
    ;ATTENZIONE !! Riordino le variabili per non cambiare i numeri di r e c delle celle (ma siccome le
    ; perc dell'ENV arrivano ordinate in altro modo, funziona usando la regola WEST).
    ;    DIR WEST
    ;    3    6    9
    ;    2  <-5    8
    ;    1    4    7
    ;    DIR NORTH
    ;    1    2    3
    ;    4    5^   6
    ;    7    8    9  (vedi ordine ?x in perc)

    =>
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (- ?c 1)) (contains ?x1))) ;perc1
    (assert (K-cell (pos-r ?r)       (pos-c (- ?c 1)) (contains ?x2))) ;perc2
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (- ?c 1)) (contains ?x3))) ;perc3
    (assert (K-cell (pos-r (- ?r 1)) (pos-c ?c)       (contains ?x4))) ;perc4
    (assert (K-cell (pos-r ?r)       (pos-c ?c)       (contains ?x5))) ;perc5
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c ?c)       (contains ?x6))) ;perc6
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (+ ?c 1)) (contains ?x7))) ;perc7
    (assert (K-cell (pos-r ?r)       (pos-c (+ ?c 1)) (contains ?x8))) ;perc8
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (+ ?c 1)) (contains ?x9))) ;perc9
    
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Watch position (%p1,%p2), direction (north)") (param1 ?r) (param2 ?c)))    
    
    (retract ?p)

    (modify ?ka (pos-r ?r) (pos-c ?c) (direction north)) ;update K-agent
)

; Vedi precedente, caso SOUTH.
(defrule perc-south
    ?ka <- (K-agent (step ?s) (time ?t))
    (status (step ?s))
    ?p <- (perc-vision (step ?s) (time ?t) (pos-r ?r) (pos-c ?c) (direction south)           
            (perc1 ?x7) (perc2 ?x4) (perc3 ?x1)
			(perc4 ?x8) (perc5 ?x5) (perc6 ?x2)
			(perc7 ?x9) (perc8 ?x6) (perc9 ?x3)
    ) ;estraggo tutte le percezioni delle celle adiacenti
    ;ATTENZIONE !! Riordino le variabili per non cambiare i numeri di r e c delle celle:
    ;    DIR WEST
    ;    3    6    9
    ;    2  <-5    8
    ;    1    4    7
    ;    DIR SOUTH
    ;    9    8    7
    ;    6    5\|  4
    ;    3    2    1  (vedi ordine ?x in perc)

    =>
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (- ?c 1)) (contains ?x1))) ;perc1
    (assert (K-cell (pos-r ?r)       (pos-c (- ?c 1)) (contains ?x2))) ;perc2
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (- ?c 1)) (contains ?x3))) ;perc3
    (assert (K-cell (pos-r (- ?r 1)) (pos-c ?c)       (contains ?x4))) ;perc4
    (assert (K-cell (pos-r ?r)       (pos-c ?c)       (contains ?x5))) ;perc5
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c ?c)       (contains ?x6))) ;perc6
    (assert (K-cell (pos-r (- ?r 1)) (pos-c (+ ?c 1)) (contains ?x7))) ;perc7
    (assert (K-cell (pos-r ?r)       (pos-c (+ ?c 1)) (contains ?x8))) ;perc8
    (assert (K-cell (pos-r (+ ?r 1)) (pos-c (+ ?c 1)) (contains ?x9))) ;perc9

    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Watch position (%p1,%p2), direction (south)") (param1 ?r) (param2 ?c)))    
    
    (retract ?p)

    (modify ?ka (pos-r ?r) (pos-c ?c) (direction south)) ;update K-agent
)


;/-----------------------------------------/
;/*****            TODO               *****/
;/-----------------------------------------/

;    - Gestire le altre percezioni (es bump)
;    - Gestire messaggi degli ordini
;    - PLANNING: Ordinazioni
;    - PLANNING: Movimenti

(defrule perc-msg-to-agent-order   
    ;?ridc <- (req-id-counter ?rid)
    (status (step ?s))
    ?p <- (msg-to-agent
              (request-time ?t)
              (step ?s)
              (sender ?snd)
              (type order)
              (drink-order ?drink)
              (food-order ?food)
           )
    =>

    (assert (dummy))
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Order on table (%p1), food (%p2), drink (%p3)") (param1 ?snd) (param2 ?food) (param3 ?drink)))
    ;do something
    (assert (order (req-id ?t) (step ?s) (time ?t) (table ?snd) (food ?food) (drink ?drink)))
    (assert (desire (step ?s) (time ?t) (table ?snd) (type order) (order ?t)))
    (assert (answer-to-order (order ?t) (step ?s) (time ?t)))
    ;(retract ?ridc)
    ;(assert (req-id-counter (+ 1 ?rid)))
    
    (retract ?p)
)

(defrule perc-msg-to-agent-finish            
    (status (step ?s))
    ?p <- (msg-to-agent
              (request-time ?t)
              (step ?s)
              (sender ?snd)
              (type finish)
           )
    =>

    (assert (dummy))
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Finish on table (%p1)") (param1 ?snd)))
    ;do something
    (assert (desire (step ?s) (time ?t) (table ?snd) (type clean)))

    (retract ?p)
)

(defrule percp-bump
    (status (step ?s))
    ?p <- (perc-bump 
            (step ?s)
            (time ?t)		
	        (pos-r ?r)		;// la posizione in cui si trova (la stessa in cui era prima dell'urto)
	        (pos-c ?c)
	        (direction ?dir)
	        (bump yes)
          ) ;//restituisce yes se sbatte

    =>

    (assert (dummy))
    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Bump on position (%p1,%p2) direction (%p3)") (param1 ?r) (param2 ?c) (param3 ?dir)))
    ;do something

    (retract ?p)
)          

;(defrule percp-load
;    (status (step ?s))
;    ?p <- (perc-load
;            (step ?s)
;            (time ?t)		
;	        (load ?load)
;          )		
;
;    =>
;
;    (assert (dummy))
;    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Load (%p1)") (param1 ?load)))
;    ;do something
;
;    (retract ?p)
;) 

;Percezione tavolo da pulire (dopo CheckFinish)
(defrule percp-finish
    (status (step ?s))
    ?p <- (perc-finish
            (step ?s)
            (time ?t)		
	        (finish ?finish)
          )		
    ?ka <- (K-agent (step ?s) (time ?t) (pos-r ?r) (pos-c ?c))
    =>

    (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived table next to (%p1,%p2), dirty (%p3)") (param1 ?r) (param2 ?c) (param3 ?finish)))
    ;do something

    (retract ?p)
)

;### Aggiornamento Belief in base alle azioni precedenti ###

;Aggiorna stato carico food con percezione Load e azione precedente LoadFood
(defrule percp-load-lastaction-LoadFood 
    (status (step ?s))
    ?p <- (perc-load
            (step ?s)
            (time ?t)		
	        (load ?load)
          )		
    (exec-history (step =(- ?s 1)) (action LoadFood) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l-food ?l-food))   
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Load (%p1) with LoadFood, current Food (%p2)") (param1 ?load) (param2 (+ 1 ?l-food))))
        (modify ?ka (l-food (+ 1 ?l-food)))    
        (retract ?p)
)

;Aggiorna stato carico food con percezione Load e azione precedente LoadDrink
(defrule percp-load-lastaction-LoadDrink
    (status (step ?s))
    ?p <- (perc-load
            (step ?s)
            (time ?t)		
	        (load ?load)
          )		
    (exec-history (step =(- ?s 1)) (action LoadDrink) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l-drink ?l-drink))   
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Load (%p1) with LoadDrink, current Drink (%p2)") (param1 ?load) (param2 (+ 1 ?l-drink))))
        (modify ?ka (l-drink (+ 1 ?l-drink)))    
        (retract ?p)
)

;Aggiorna stato carico food con percezione Load e azione precedente DeliveryFood
(defrule percp-load-lastaction-DeliveryFood
    (status (step ?s))
    ?p <- (perc-load
            (step ?s)
            (time ?t)		
	        (load ?load)
          )		
    (exec-history (step =(- ?s 1)) (action DeliveryFood) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l-food ?l-food))   
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Load (%p1) with DeliveryFood, current Food (%p2)") (param1 ?load) (param2 (- ?l-food 1))))
        (modify ?ka (l-food (- ?l-food 1)))    
        (retract ?p)
)

;Aggiorna stato carico food con percezione Load e azione precedente DeliveryDrink
(defrule percp-load-lastaction-DeliveryDrink
    (status (step ?s))
    ?p <- (perc-load
            (step ?s)
            (time ?t)		
	        (load ?load)
          )		
    (exec-history (step =(- ?s 1)) (action DeliveryDrink) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l-drink ?l-drink))   
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "Perceived Load (%p1) with DeliveryDrink, current Drink (%p2)") (param1 ?load) (param2 (- ?l-drink 1))))
        (modify ?ka (l-drink (- ?l-drink 1)))    
        (retract ?p)
)

;Aggiorna stato azione precedente CleanTable
(defrule update-lastaction-CleanTable 
    (status (step ?s))	
    (exec-history (step =(- ?s 1)) (action CleanTable) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l_f_waste ?lw-food) (l_d_waste ?lw-drink))   
    ?f <- (UPDATER-BEL__exec-history-runonce)
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "After CleanTable loaded Waste Food and Drink")))
        (modify ?ka (l_f_waste yes) (l_d_waste yes))    
        (retract ?f)
)

;Aggiorna stato azione precedente EmptyFood
(defrule update-lastaction-EmptyFood 
    (status (step ?s))	
    (exec-history (step =(- ?s 1)) (action EmptyFood) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l_f_waste ?lw-food) (l_d_waste ?lw-drink))   
    ?f <- (UPDATER-BEL__exec-history-runonce)
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "After EmptyFood empty Waste Food")))
        (modify ?ka (l_f_waste no))    
        (retract ?f)
)

;Aggiorna stato azione precedente Release (EmptyDrink)
(defrule update-lastaction-Release 
    (status (step ?s))	
    (exec-history (step =(- ?s 1)) (action Release) (param1 ?p1) (param2 ?p2) (param3 ?p3))
    ?ka <- (K-agent (step ?s) (time ?t) (l_f_waste ?lw-food) (l_d_waste ?lw-drink))   
    ?f <- (UPDATER-BEL__exec-history-runonce)
    =>
        (assert (printGUI (time ?t) (step ?s) (source "AGENT::UPDATER-BEL") (verbosity 2) (text  "After Release empty Waste Drink")))
        (modify ?ka (l_d_waste no))    
        (retract ?f)
)

;### TODO: CheckFinish ?? ###

(defrule dispose
    (declare (salience -100))
    ?f <- (UPDATER-BEL__init)
    =>
        (retract ?f)
        (pop-focus)
)