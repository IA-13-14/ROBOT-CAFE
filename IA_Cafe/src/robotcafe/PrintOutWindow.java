/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package robotcafe;

import java.awt.Color;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.Map;
import javax.swing.JLabel;
import javax.swing.JSlider;
import javax.swing.SwingConstants;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.TableColumn;
import javax.swing.text.BadLocationException;
import javax.swing.text.Document;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;

/**
 *
 * @author Davide
 */
public class PrintOutWindow extends javax.swing.JFrame {

    //enumerazione di colori per la finestra di output
    private final Map<String, Color> sources;
    
    private static MonitorView monitor_view;
    
    //dizionario per le label dello slider della verbosity
    Hashtable<Integer, JLabel> table;
    /**
     * Creates new form PintOutWindow
     */
    public PrintOutWindow(MonitorView father) {
        initComponents();
        
        //tabella dei colori
        sources = new HashMap<>();
        sources.put("SYSTEM", Color.decode("#32CD32"));
        sources.put("AGENT", Color.blue);
        sources.put("PLANNER", Color.darkGray);
        sources.put("ENV", Color.red);
        sources.put("AGENT::UPDATER-BEL", Color.PINK);
        
        table = new Hashtable<>();
        table.put(0, new JLabel("Low"));
        table.put(1, new JLabel("Medium"));
        table.put(2, new JLabel("High"));
        this.jSlider1.setLabelTable(table);
        
        monitor_view = father;
        
        /*imposto l'allineamento centrale per le celle della tabella dell'agentstatus*/
        DefaultTableCellRenderer centerRenderer = new DefaultTableCellRenderer();
        centerRenderer.setHorizontalAlignment(SwingConstants.CENTER);
        for(int i=0; i< jTable1.getColumnModel().getColumnCount(); i++)
            jTable1.getColumnModel().getColumn(i).setCellRenderer(centerRenderer);
    }

    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jScrollPane1 = new javax.swing.JScrollPane();
        output = new javax.swing.JTextPane();
        jSlider1 = new javax.swing.JSlider();
        jLabel1 = new javax.swing.JLabel();
        jSeparator1 = new javax.swing.JSeparator();
        jLabel3 = new javax.swing.JLabel();
        jLabel4 = new javax.swing.JLabel();
        jLabel5 = new javax.swing.JLabel();
        jScrollPane2 = new javax.swing.JScrollPane();
        jTable1 = new javax.swing.JTable();
        jLabel2 = new javax.swing.JLabel();
        AgentStatusStepLabel = new javax.swing.JLabel();

        setDefaultCloseOperation(javax.swing.WindowConstants.DO_NOTHING_ON_CLOSE);
        setTitle("Output");

        output.setEditable(false);
        output.setBorder(javax.swing.BorderFactory.createEtchedBorder(new java.awt.Color(204, 102, 0), null));
        output.setContentType("text/html"); // NOI18N
        output.setText("<html>\n  <head>\n\n  </head>\n  <body style=\"margin: 7px 10px 7px 10px\">\n    <p style=\"margin: 1px\">\n      \n    </p>\n  </body>\n</html>\n");
        jScrollPane1.setViewportView(output);

        jSlider1.setMajorTickSpacing(1);
        jSlider1.setMaximum(2);
        jSlider1.setPaintLabels(true);
        jSlider1.setPaintTicks(true);
        jSlider1.setName(""); // NOI18N
        jSlider1.addChangeListener(new javax.swing.event.ChangeListener() {
            public void stateChanged(javax.swing.event.ChangeEvent evt) {
                jSlider1StateChanged(evt);
            }
        });      

        jLabel1.setText("Verbosity grade");

        jSeparator1.setOrientation(javax.swing.SwingConstants.VERTICAL);

        jLabel3.setText("Step");

        jLabel4.setText("Source");

        jLabel5.setText("Message");

        jScrollPane2.setHorizontalScrollBarPolicy(javax.swing.ScrollPaneConstants.HORIZONTAL_SCROLLBAR_NEVER);
        jScrollPane2.setVerticalScrollBarPolicy(javax.swing.ScrollPaneConstants.VERTICAL_SCROLLBAR_NEVER);

        jTable1.setModel(new javax.swing.table.DefaultTableModel(
            new Object [][] {
                {null, null, null, null}
            },
            new String [] {
                "Food Quantity", "Drink Quantity", "Food Waste", "Drink Waste"
            }
        ) {
            Class[] types = new Class [] {
                java.lang.Integer.class, java.lang.Integer.class, java.lang.String.class, java.lang.String.class
            };
            boolean[] canEdit = new boolean [] {
                false, false, false, false
            };

            public Class getColumnClass(int columnIndex) {
                return types [columnIndex];
            }

            public boolean isCellEditable(int rowIndex, int columnIndex) {
                return canEdit [columnIndex];
            }
        });
        jTable1.setAutoscrolls(false);
        jTable1.setMinimumSize(new java.awt.Dimension(60, 20));
        jTable1.setRowHeight(30);
        jTable1.setRowSelectionAllowed(false);
        jTable1.getTableHeader().setReorderingAllowed(false);
        jScrollPane2.setViewportView(jTable1);

        jLabel2.setText("Agent status");

        AgentStatusStepLabel.setText("(Step 0)");

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addComponent(jScrollPane1)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jSlider1, javax.swing.GroupLayout.PREFERRED_SIZE, 135, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addGroup(layout.createSequentialGroup()
                                .addGap(21, 21, 21)
                                .addComponent(jLabel1)))
                        .addGap(18, 18, 18)
                        .addComponent(jSeparator1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jScrollPane2)
                            .addGroup(layout.createSequentialGroup()
                                .addComponent(jLabel2)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                                .addComponent(AgentStatusStepLabel)
                                .addGap(0, 0, Short.MAX_VALUE))))
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel3)
                        .addGap(47, 47, 47)
                        .addComponent(jLabel4)
                        .addGap(30, 30, 30)
                        .addComponent(jLabel5)
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel3)
                    .addComponent(jLabel4)
                    .addComponent(jLabel5))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 287, Short.MAX_VALUE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING, false)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel1)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addComponent(jSlider1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE))
                    .addComponent(jSeparator1)
                    .addGroup(layout.createSequentialGroup()
                        .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jLabel2)
                            .addComponent(AgentStatusStepLabel))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                        .addComponent(jScrollPane2, javax.swing.GroupLayout.PREFERRED_SIZE, 50, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void jSlider1StateChanged(javax.swing.event.ChangeEvent evt) {//GEN-FIRST:event_jSlider1StateChanged
        JSlider source = (JSlider)evt.getSource();
        if (!source.getValueIsAdjusting()) {
            int fps = (int)source.getValue();
            monitor_view.setVerbosityMode(fps);
            monitor_view.updateOutput();
        }
    }//GEN-LAST:event_jSlider1StateChanged

    /**
     * @param args the command line arguments
     */
//    public static void main(String args[]) {
//        /* Set the Nimbus look and feel */
//        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
//        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
//         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
//         */
//        try {
//            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
//                if ("Nimbus".equals(info.getName())) {
//                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
//                    break;
//                }
//            }
//        } catch (ClassNotFoundException ex) {
//            java.util.logging.Logger.getLogger(PrintOutWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
//        } catch (InstantiationException ex) {
//            java.util.logging.Logger.getLogger(PrintOutWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
//        } catch (IllegalAccessException ex) {
//            java.util.logging.Logger.getLogger(PrintOutWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
//        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
//            java.util.logging.Logger.getLogger(PrintOutWindow.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
//        }
//        //</editor-fold>
//
//        /* Create and display the form */
//        java.awt.EventQueue.invokeLater(new Runnable() {
//            public void run() {
//                new PrintOutWindow(monitor_view).setVisible(true);
//            }
//        });
//    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JLabel AgentStatusStepLabel;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JScrollPane jScrollPane2;
    private javax.swing.JSeparator jSeparator1;
    private javax.swing.JSlider jSlider1;
    private javax.swing.JTable jTable1;
    private javax.swing.JTextPane output;
    // End of variables declaration//GEN-END:variables


    /*
    Metodi per l'inserimento di testo nella finestra di output.
    */
    
    //Permette di appendere una normale stringa alla finestra di output
    
    public void write(String s) {
        try {
           Document doc = output.getDocument();
           doc.insertString(doc.getLength(), s+"\n", new SimpleAttributeSet());
           output.setCaretPosition(output.getDocument().getLength());
        } catch(BadLocationException exc) {
        }
     }
    /**
     * Permette di appendere alla finestra di output una stringa di un determinato colore
     * @param s la strinfa da appendere
     * @param color una stringa rappresentante il colore.
     *              Il colore corrispondente verrà recuperato dalla hasmap definita nel costruttore della classe
     *  
     */
    public void write(String s, String color) {
        try {
           Document doc = output.getDocument();
           SimpleAttributeSet keyWord = new SimpleAttributeSet();
           if(sources.get(color)==null)
        	   StyleConstants.setForeground(keyWord, Color.BLACK);
           else
        	   StyleConstants.setForeground(keyWord, sources.get(color));

            //StyleConstants.setBackground(keyWord, color);
           
           doc.insertString(doc.getLength(), s+"\n", keyWord);
            output.setCaretPosition(output.getDocument().getLength());
        } catch(Exception exc) {
        	System.out.println("[ERROR]: Cannot log print GUI ("+s+") "+ exc);
        }
     }
    
    /**
     * Permette di appendere alla finestra di output una stringa di un determinato colore in bold
     * @param s la strinfa da appendere
     * @param color una stringa rappresentante il colore.
     *              Il colore corrispondente verrà recuperato dalla hasmap definita nel costruttore della classe
     * @param bold se true scrive la stringa in bold
     * 
     */
    public void write(String s, String color, Boolean bold) {
        try {
           Document doc = output.getDocument();
           SimpleAttributeSet keyWord = new SimpleAttributeSet();
           StyleConstants.setForeground(keyWord, sources.get(color));

            //StyleConstants.setBackground(keyWord, color);
           if(bold)
               StyleConstants.setBold(keyWord, true);
           
           doc.insertString(doc.getLength(), s+"\n", keyWord);
            output.setCaretPosition(output.getDocument().getLength());
        } catch(BadLocationException exc) {
        }
     }
    
    /**
     * Metodo che resetta il documento contenuto nella finestra.
     * @param s
     * @param color 
     */
    public void resetDocument() {
        try {
           Document doc = output.getDocument();
           doc.remove(0, doc.getLength());
        } catch(BadLocationException exc) {
        }
     }
    /**
     * aggiorna la tabella relativa allo stato dell'agente.
     * Può essere personalizzata a seconda delle necesità del dominio in uso
     * Nel caso specifico inserisce in tabella i valori dei vari oggetti che l'agente può portare/contenere
     * @param step lo step corrente
     * @param food il numero di food
     * @param drink il numero di drink
     * @param food_waste la presenza di food_waste
     * @param drink_waste la presenza di drink_waste
     */
    public void updateAgentStatusWindow(int step, int food, int drink, String food_waste, String drink_waste){
            //aggiorno la label indicante lo step
            this.AgentStatusStepLabel.setText("(Step "+step+")");
            
            //aggiorno i valori nella tabella
            DefaultTableModel model = (DefaultTableModel) jTable1.getModel();
            model.setNumRows(0);
            model.addRow(new Object[]{ food, drink, food_waste, drink_waste}
            ); 
    }

    public JSlider getVerboseSlider() {
        return this.jSlider1;
    }
}
