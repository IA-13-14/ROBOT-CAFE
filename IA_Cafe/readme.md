# Console di gestione della simulazione

Console che ospita l'esecuzione dell'ambiente CLIPS in ambiente Java (tramite libreria CLIPSJNI), contenente una visualizzazione 2D della mappa che rappresenta lo stato del mondo, oltre che alcune finestre utili per il debug.

Ispirata a: https://code.google.com/p/monitor-2012-2013/


### Istruzioni

1) Rinominare il file CLIPSJNI.dll usando l'apposita versione, che dipende dal SO e dalla Java VM:
- per sistemi a 64 bit usare la CLIPSJNI.dll e la relativa JRE a 64-bit.
- per sistemi a 32 bit usare la CLIPSJNI_x86.dll (rinominare in CLIPSJNI.dll) e la relativa JRE 32-bit.
- per sistemi misti provarle entrambe, ma non è garantito il funzionamento.

2) Avviare la console mediante la classe Main
