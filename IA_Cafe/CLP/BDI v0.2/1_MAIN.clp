;// MAIN                                                
;// ����������������������������������������������������������������������������������������������������������������������� 

(defmodule MAIN (export ?ALL))

;// DEFTEMPLATE

;#####  required for GUI #####
; Per le stampe (interpretabili da CLIPSJNI)
(deftemplate printGUI    
            (slot time (default ?NONE)) 
            (slot step (default ?NONE))
            (slot source (type STRING) (default ?NONE)) 
            (slot verbosity (type INTEGER) (allowed-integers 0 1 2) (default 0))  ;Tre livelli di verbositÃ 
            (slot text (type STRING)) 
            (slot param1 (default ""))
            (slot param2 (default ""))
            (slot param3 (default ""))
            (slot param4 (default ""))
            (slot param5 (default ""))   
            (slot param6 (default ""))                 
            (slot param7 (default ""))
            (slot param8 (default ""))
)
;END -- #####  required for GUI #####

(deftemplate exec 
	(slot step) 	;// l'environment incrementa il passo 
	(slot action  (allowed-values Forward Turnright Turnleft Wait 
                                      LoadDrink LoadFood DeliveryFood DeliveryDrink 
                                      CleanTable EmptyFood Release CheckFinish Inform))
        (slot param1)
        (slot param2)
        (slot param3))


(deftemplate msg-to-agent 
           (slot request-time)
           (slot step)
           (slot sender)
           (slot type (allowed-values order finish))
           (slot  drink-order)
           (slot food-order))

        
(deftemplate status (slot step) (slot time) (slot result (default no)))	;//struttura interna

(deftemplate perc-vision	;// la percezione di visione avviene dopo ogni azione, fornisce informazioni sullo stato del sistema
	(slot step)
        (slot time)	
	(slot pos-r)		;// informazioni sulla posizione del robot (riga)
	(slot pos-c)		;// (colonna)
	(slot direction)		;// orientamento del robot
	;// percezioni sulle celle adiacenti al robot: (il robot � nella 5 e punta sempre verso la 2):		        
	         
        (slot perc1  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc2  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc3  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc4  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc5  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc6  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc7  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc8  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        (slot perc9  (allowed-values  Wall Person  Empty Parking Table Seat TrashBasket
                                                      RecyclableBasket DrinkDispenser FoodDispenser))
        )



(deftemplate perc-bump  	;// percezione di urto contro persone o ostacoli
	(slot step)
        (slot time)		
	(slot pos-r)		;// la posizione in cui si trova (la stessa in cui era prima dell'urto)
	(slot pos-c)
	(slot direction)
	(slot bump (allowed-values no yes)) ;//restituisce yes se sbatte
)


(deftemplate perc-load
                      (slot step)
                      (slot time)
                      (slot load  (allowed-values yes no)) ) 


(deftemplate perc-finish  
         (slot step)
         (slot time)
         (slot finish (allowed-values no yes)))


(deftemplate Table (slot table-id) (slot pos-r) (slot pos-c))
(deftemplate TrashBasket (slot TB-id) (slot pos-r) (slot pos-c))
(deftemplate RecyclableBasket (slot  RB-id) (slot pos-r) (slot pos-c))
(deftemplate FoodDispenser  (slot FD-id) (slot pos-r) (slot pos-c))
(deftemplate DrinkDispenser (slot DD-id) (slot pos-r) (slot pos-c))

(deftemplate initial_agentposition (slot pos-r)  (slot pos-c) (slot direction))

(deftemplate prior-cell  (slot pos-r) (slot pos-c) 
                         (slot contains (allowed-values Wall Person  Empty Parking Table Seat TB
                                                      RB DD FD)))


(deffacts init 
	(create)
)


;; regola per inizializzazione
;; legge anche initial map (prior cell), initial agent status e durata simulazione (in numero di passi)

(defrule createworld 
    ?f<-   (create) =>
           (load-facts "InitMap.txt")
           (assert (create-map) (create-initial-setting)
                   (create-history))  
           (retract ?f)
           (focus ENV))

;// SI PASSA AL MODULO AGENT SE NON  E' ESAURITO IL TEMPO (indicato da maxduration)
(defrule go-on-agent		
	(declare (salience 20))
	(maxduration ?d)
	(status (step ?t&:(< ?t ?d)))	;// controllo sul tempo
 => 
;	(printout t crlf)
	(focus AGENT)		;// passa il focus all'agente, che dopo un'azione lo ripassa al main.
)

;// SI PASSA AL MODULO ENV DOPO CHE AGENTE HA DECISO AZIONE DA FARE
(defrule go-on-env	
	(declare (salience 21))
?f1<-	(status (step ?t))
	(exec (step ?t)) 	;// azione da eseguire al al passo T, viene simulata dall'environment
=>
;	(printout t crlf)
	(focus ENV)
)

;// quando finisce il tempo l'esecuzione si interrompe e vengono stampate le penalit�
(defrule game-over	
	(declare (salience 10))
	(maxduration ?d)
	(status (step ?d))
	(penalty ?p)
=> 
	(printout t crlf " TIME OVER - Penalit� accumulate: " ?p crlf crlf)
	(halt)
)