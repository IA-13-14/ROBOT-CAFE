package xclipsjni;

import javax.swing.DefaultListModel;
import javax.swing.ListModel;
import javax.swing.text.DefaultCaret;

/**
 * Questa classe implementa una finestrella di piccole dimensioni contenente una
 * TextArea nella quale si può inserire del testo. È usata all'interno del
 * pannello di controllo per le finestre di Agenda e Fatti, ma alla necessità
 * può essere usata anche per altro.
 *
 * @author Piovesan Luca, Verdoja Francesco Edited by: @author Violanti Luca,
 *         Varesano Marco, Busso Marco, Cotrino Roberto
 */
public class ListPropertyMonitor extends javax.swing.JFrame {

	/**
	 * Crea un nuovo monitor senza titolo
	 * 
	 */
	public ListPropertyMonitor() {
		initComponents();
	}

	/**
	 * Crea un nuovo monitor con il titolo indicato
	 * 
	 * @param title
	 *            il titolo che si vuole dare al monitor
	 */
	public ListPropertyMonitor(String title) {
		initComponents();
		setTitle(title);
	}

	/**
	 * Questo metodo è chiamato dal costruttore e inizializza il form WARNING:
	 * NON modificare assolutamente questo metodo.
	 */
	@SuppressWarnings("unchecked")
	// <editor-fold defaultstate="collapsed"
	// desc="Generated Code">//GEN-BEGIN:initComponents
	private void initComponents() {

		scrollPane = new javax.swing.JScrollPane();
		DefaultListModel lm=new DefaultListModel<String>();

		itemList = new javax.swing.JList<String>(lm);

		setTitle("Property Monitor");
		setMinimumSize(new java.awt.Dimension(200, 200));

		scrollPane.setViewportView(itemList);

		javax.swing.GroupLayout layout = new javax.swing.GroupLayout(
				getContentPane());
		getContentPane().setLayout(layout);
		layout.setHorizontalGroup(layout.createParallelGroup(
				javax.swing.GroupLayout.Alignment.LEADING).addComponent(
				scrollPane, javax.swing.GroupLayout.DEFAULT_SIZE, 325,
				Short.MAX_VALUE));
		layout.setVerticalGroup(layout.createParallelGroup(
				javax.swing.GroupLayout.Alignment.LEADING).addComponent(
				scrollPane, javax.swing.GroupLayout.DEFAULT_SIZE, 325,
				Short.MAX_VALUE));

		pack();
	}// </editor-fold>//GEN-END:initComponents

	public DefaultListModel<String> getListModel() {
		return (DefaultListModel<String>) itemList.getModel();
	}

	void setAutoScroll() {
		// DefaultCaret caret = (DefaultCaret)this.textArea.getCaret();
		// caret.setUpdatePolicy(DefaultCaret.ALWAYS_UPDATE);
	}

	// Variables declaration - do not modify//GEN-BEGIN:variables
	private javax.swing.JScrollPane scrollPane;
	private javax.swing.JList<String> itemList;
	// End of variables declaration//GEN-END:variables
}