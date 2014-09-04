package robotcafe;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.GraphicsDevice;
import java.awt.GraphicsEnvironment;
import java.awt.GridLayout;
import java.awt.Image;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.awt.event.ComponentListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Observer;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.SwingConstants;

import xclipsjni.ClipsView;
import xclipsjni.ControlPanel;

/**
 * L'implementazione della classe ClipsView specifica per il progetto Monitor
 * 2012/2013
 *
 * @author Violanti Luca, Varesano Marco, Busso Marco, Cotrino Roberto Edited
 *         by: Enrico Mensa, Matteo Madeddu, Davide Dell'Anna
 */
public class MonitorView extends ClipsView implements Observer {

	/**
	 * Tipi di verbosità.
	 */
	final int Verbosity_HIGH = 2;
	final int Verbosity_MEDIUM = 1;
	final int Verbosity_LOW = 0;

	private MonitorModel model;
	private JFrame view;
	private JPanel mapPanelContainer;
	private JPanel mapPanel;
	private JLabel[][] map;
	private final int MAP_DIMENSION = 550;
	private final int DEFAULT_IMG_SIZE = 85;
	private JPanel cp_JPanel; // Pannello
	private ControlPanel cp_frame; // Effettivo frame (classe ControlPanel)

	// Modificabile dall'interfaccia
	private int verbose_mode = Verbosity_HIGH;

	PrintOutWindow outputFrame;

	// HashMap che attribuisce ad ogni tipo di cella un codice univoco.
	// L'attribuzione è effettuata nel costruttore.
	private final Map<String, String> map_img;

	/**
	 * È il costruttore da chiamare nel main per avviare l'intero sistema, apre
	 * una nuova finestra con il controller, pronto per caricare il file .clp
	 *
	 */
	public MonitorView() {

		// Primo campo: coerente con i file di CLIPS
		// Secondo campo: nome del file (a piacere)
		map_img = new HashMap<>();
		map_img.put("Wall", "wall.jpg");
		map_img.put("Empty", "empty.png");
		map_img.put("Seat", "seat.png");
		map_img.put("Table_clean", "table_clean.png");
		map_img.put("Table_dirty", "table_dirty.png");
		map_img.put("TB", "trash_basket.png");
		map_img.put("RB", "recycle_basket.png");
		map_img.put("DD", "drink_dispenser.png");
		map_img.put("FD", "food_dispenser.png");

		map_img.put("Parking", "parking.png");

		// Per l'agente, il primo campo deve essere di tipo agent_<direction>
		// Dove <direction> è il valore del campo preso da CLIPS.
		map_img.put("agent_east", "agent_east.png");
		map_img.put("agent_west", "agent_west.png");
		map_img.put("agent_north", "agent_north.png");
		map_img.put("agent_south", "agent_south.png");

		// Per gestire le persone. Non vengono sovrapposte, sono vere e proprie
		// celle
		// Le persone hanno valore correlato nella map:
		// person_<Posizione>_<ident>
		// Il terzo valore è l'ident della persona (slot del personstatus)

		// Per poter funzionare, è necessario che vi siano immagini del tipo
		// <ident>-person_empty.png

		// Qualora non si trovi tale immagine, ne viene usata una di default
		// (che ha nome come il secondo campo della mappa)

		map_img.put("person_Person", "person_empty.png"); // Persona in piedi
		map_img.put("person_Seat", "person_seat.png"); // Persona seduta
		map_img.put("person_Empty", "person_empty.png"); // Persona in piedi

		model = new MonitorModel();
		model.addObserver((Observer) this);
		initializeInterface();
	}

	@Override
	protected void onSetup() {
		DebugFrame
				.appendText("[SYSTEM] Setup completato. Mi appresto a visualizzare la mappa.");
		initializeMap(); // Va

	}

	@Override
	protected void onAction() {
		// System.out.println("actionDone");
		DebugFrame.appendText("[SYSTEM] Azione effettuata.");
		try {
			if(mapSizeChanged){
				updateMap(true);
				mapSizeChanged=false;
			}
			else
				updateMap(false);
			updateOutput();
		} catch (IOException ex) {
			Logger.getLogger(MonitorView.class.getName()).log(Level.SEVERE,
					null, ex);
		}
	}

	@Override
	protected void onDispose() {
		// System.out.println("disposeDone");
		DebugFrame.appendText("[SYSTEM] Dispose effettuato.");
		String result = model.getResult();
		int score = model.getScore();
		@SuppressWarnings("UnusedAssignment")
		String advise = "";
		if (result.equals("disaster")) {
			advise = "DISASTRO\n";
		} else if (model.getTime() == model.getMaxDuration()) {
			advise = "Maxduration has been reached.\n";
		} else {
			advise = "The agent says DONE.\n";
		}
		advise = advise + "Penalties: " + score;
		JOptionPane.showMessageDialog(mapPanel, advise, "Termine Esecuzione",
				JOptionPane.INFORMATION_MESSAGE);
	}

	/**
	 * Chiamato nel costruttore inizializza l'interfaccia della finestra,
	 * caricando il modulo del pannello di controllo.
	 *
	 */
	private void initializeInterface() {

		GraphicsDevice gd = GraphicsEnvironment.getLocalGraphicsEnvironment()
				.getDefaultScreenDevice();
		int width = gd.getDisplayMode().getWidth();
		int height = gd.getDisplayMode().getHeight();

		view = new JFrame();
		view.getRootPane().addComponentListener(new ComponentAdapter() {
            public void componentResized(ComponentEvent e) {
                mapSizeChanged=true;
            }
        });
		
		view.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		view.setSize(new Dimension(width / 3, 160));
		view.setResizable(true);
		view.setTitle("Waiter-Bot");
		view.setLayout(new BorderLayout());
		cp_frame = createControlPanel(model);
		cp_JPanel = cp_frame.getControlPanel();
		view.add(cp_JPanel, BorderLayout.NORTH);

		outputFrame = new PrintOutWindow(this);
		outputFrame.setSize(width / 4, 500);
		outputFrame
				.setLocation(width - 2 * outputFrame.getWidth(), view.getY());
		outputFrame.setVisible(true);

		// comando inserito in questa posizione per settare il focus iniziale
		// sulla finestra principale e non su quella di output
		view.setVisible(true);

		// inizializzo il valore dello slider di verbosità
		outputFrame.getVerboseSlider().setValue(this.verbose_mode);

	}

	/**
	 * Crea la prima versione della mappa, quella corrispondente all'avvio
	 * dell'ambiente. Inserisce in ogni elemento del grid (mappa) la corretta
	 * immagine.
	 *
	 */
	private void initializeMap() {		
		
		Integer timeLeft = model.getMaxDuration();

		cp_frame.getLeftTimeTextField().setText(timeLeft.toString()); // Aggiorna
																		// il
																		// timeleft
		String[][] mapString = model.getMap();
		String[][] mapTabString = model.getMapTab();

		int x = mapString.length;
		int y = mapString[0].length;
		map = new JLabel[x][y];
		int cellDimension = Math.round(MAP_DIMENSION / x);

		// bloccata la dimensione massima delle singole immagini
		if (cellDimension > DEFAULT_IMG_SIZE) {
			cellDimension = DEFAULT_IMG_SIZE;
		}
		
		// RelativeLayout rl = new RelativeLayout(RelativeLayout.X_AXIS, 10);
		// rl.setFill(true);
		mapPanelContainer = new JPanel();
		mapPanelContainer.setLayout(new BorderLayout());
		mapPanel = new JPanel();
		mapPanel.setLayout(new GridLayout(x, y));
		mapPanelContainer.add(mapPanel, BorderLayout.CENTER);
		mapPanelContainer.setBackground(Color.red);
		mapPanel.setBackground(Color.white);

		// Inserisce in ogni elemento del grid la corretta immagine.

		for (int i = x - 1; i >= 0; i--) {
			for (int j = 0; j < y; j++) {
				ImageIcon icon = new ImageIcon("img" + File.separator
						+ map_img.get(mapString[i][j])); // Sfrutta la HashTable
															// per trovare
															// l'immagine
															// correlata al nome
				Image image = icon.getImage().getScaledInstance(cellDimension,
						cellDimension, Image.SCALE_SMOOTH);
				icon = new ImageIcon(image);
				map[i][j] = new JLabel(icon);
				map[i][j].setToolTipText("(" + (i + 1) + ", " + (j + 1) + ")");
				
				//Disegna numero tavolo in sovraimpressione
				if(mapString[i][j].equals("Table")){
					map[i][j].setText(mapTabString[i][j]);
					
					map[i][j].setHorizontalTextPosition(SwingConstants.CENTER);
					
					//Font per disegno numero tavolo in sovraimpressione
					JLabel label = map[i][j];
					Font labelFont = label.getFont();
					String labelText = label.getText();

					int stringWidth = label.getFontMetrics(labelFont).stringWidth(labelText);
					int componentWidth = cellDimension;

					// Find out how much the font can grow in width.
					double widthRatio = (double)componentWidth / (double)stringWidth;

					int newFontSize = (int)(labelFont.getSize() * widthRatio);
					int componentHeight = cellDimension;

					// Pick a new font size so it will not be larger than the height of label.
					int fontSizeToUse = (int) (Math.min(newFontSize, componentHeight) * 0.7);

					// Set the label's font size to the newly determined size.
					Font font = new Font(labelFont.getName(), Font.PLAIN, fontSizeToUse);
					
					map[i][j].setFont(font);
				}				
				
				mapPanel.add(map[i][j]);
			}
		}
		view.add(mapPanelContainer, BorderLayout.CENTER);

		view.pack();

	}

	/*
	 * public void updateMap() {
	 * 
	 * }
	 */

	public class MapPanel extends JPanel implements ComponentListener {

		@Override
		public void componentHidden(ComponentEvent e) {
			// TODO Auto-generated method stub

		}

		@Override
		public void componentMoved(ComponentEvent e) {
			// TODO Auto-generated method stub

		}

		@Override
		public void componentResized(ComponentEvent e) {
			try {
				updateMap(true);
			} catch (IOException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
		}

		@Override
		public void componentShown(ComponentEvent e) {
			// TODO Auto-generated method stub

		}

	}

	String[][] oldMapString = null;

	public class MapCell {
		int x;
		int y;
		String data;

		public MapCell(int x, int y, String data) {
			super();
			this.x = x;
			this.y = y;
			this.data = data;
		}
	}

	public List<MapCell> changedMapCells(String[][] mapString) {
		List<MapCell> list = new ArrayList<MapCell>();
		if (oldMapString == null) {
			oldMapString=new String [mapString.length][map[0].length];
			for (int i = map.length - 1; i >= 0; i--) {
				for (int j = 0; j < map[0].length; j++) {
					list.add(new MapCell(i, j, mapString[i][j]));
					oldMapString[i][j]=mapString[i][j];
				}
			}
			return list;
		} else {

			for (int i = map.length - 1; i >= 0; i--) {
				for (int j = 0; j < map[0].length; j++) {
					if (!mapString[i][j].equals(oldMapString[i][j]) || (mapString[i][j].contains("agent_"))) {
						list.add(new MapCell(i, j, mapString[i][j]));
						oldMapString[i][j]=mapString[i][j];
					}
				}
			}
		}
		return list;
	}

	boolean mapSizeChanged=false;
	
	/**
	 * Aggiorna la mappa visualizzata nell'interfaccia per farla allineare alla
	 * versione nel modello.
	 *
	 */
	private void updateMap(boolean redraw) throws IOException {
		
		outputFrame.updateOrderStatus(model.getOrdersStatusString()+"\n"+model.getCleansStatusString());
		
		System.out.println("[PENALTIES]: "+model.getScore());
		
		Integer step = model.getStep();
		Integer time = model.getTime();
		Integer leftTime = model.getMaxDuration() - model.getTime();
		cp_frame.getTimeTextField().setText(time.toString());
		cp_frame.getLeftTimeTextField().setText(leftTime.toString());
		cp_frame.getStepTextField().setText(step.toString());

		String[][] mapString = model.getMap();

		//int cellDimension = Math.round(MAP_DIMENSION / map.length);
		int dim = mapPanel.getSize().width;
		int cellDimension = Math.round(dim / map.length);
		if (redraw) {
			oldMapString = null;						
		}

		List<MapCell> chgCells = changedMapCells(mapString);		

		// int dim =
		// Math.min(mapPanel.getSize().width,mapPanel.getSize().height);
		

		long start = System.currentTimeMillis();
		for (MapCell cell : chgCells) {
			int i = cell.x;
			int j = cell.y;
			String cellData = cell.data;
			/*
			 * for (int i = map.length - 1; i >= 0; i--) { for (int j = 0; j <
			 * map[0].length; j++) {
			 */
			@SuppressWarnings("UnusedAssignment")
			String direction = "";
			ImageIcon icon;
			Image image;
			BufferedImage background;
			BufferedImage robot;

			if(!cellData.contains("Table"))
				map[i][j].setText("");
			
			// cerca se, nei primi 6 caratteri (se ce ne sono almeno 6),
			// c'è la stringa "agent_", vedere metodo updateMap in
			// MonitorModel.java
			// Nel modello si ha una stringa del tipo agent_empty se l'agent
			// si trova su una cella empty.
			// In modo da inserire l'icona del robot sopra la cella in cui
			// si trova (le due immagini vengono sovrapposte)
			// ##### SE AGENTE #####
			if (cellData.length() >= 6
					&& cellData.substring(0, 6).equals("agent_")) {
				direction = model.getDirection();
				// ...nel, caso prosegue dal 6° carattere in poi.
				String agent_description[] = cellData.split("_");
				background = ImageIO.read(new File("img" + File.separator
						+ map_img.get(agent_description[1])));
				robot = ImageIO.read(new File("img" + File.separator
						+ map_img.get("agent_" + direction)));

				icon = overlapImages(robot, background);

				// Imposta il tooltip
				map[i][j].setToolTipText(null);
				map[i][j].setToolTipText("Agent (" + (i + 1) + ", " + (j + 1)
						+ ")" + "(F:" + agent_description[2] + ",D:"
						+ agent_description[3] + ",WF:" + agent_description[4]
						+ ",WD:" + agent_description[5] + ")");

				// ##### SE PERSONA #####
			} else if (cellData.length() >= 7
					&& cellData.substring(0, 7).equals("person_")) {
				// Nella forma person_<Background>_<ident>
				String map_contains = cellData;
				String[] person_info = map_contains.split("_"); // prendiamo
																// i tre
																// campi
				// path dell'immagine apposita (se esiste) per la persona
				String path_image = "img" + File.separator + person_info[2]
						+ "-"
						+ map_img.get(person_info[0] + "_" + person_info[1]);
				File f = new File(path_image);

				if (f.exists()) { // se esiste immagine apposita per
									// quell'id
					icon = new ImageIcon(path_image);
				} else { // Se il file non esiste si usa quello di default
							// (senza ident davanti)
					icon = new ImageIcon(
							"img"
									+ File.separator
									+ map_img.get(person_info[0] + "_"
											+ person_info[1]));
				}
				
				//Disegna numero tavolo in sovraimpressione
				if(person_info[2]!=null){
					map[i][j].setText(person_info[2]);
					
					map[i][j].setHorizontalTextPosition(SwingConstants.CENTER);
					
					//Font per disegno numero tavolo in sovraimpressione
					JLabel label = map[i][j];
					Font labelFont = label.getFont();
					String labelText = label.getText();

					int stringWidth = label.getFontMetrics(labelFont).stringWidth(labelText);
					int componentWidth = cellDimension;

					// Find out how much the font can grow in width.
					double widthRatio = (double)componentWidth / (double)stringWidth;

					int newFontSize = (int)(labelFont.getSize() * widthRatio);
					int componentHeight = cellDimension;

					// Pick a new font size so it will not be larger than the height of label.
					int fontSizeToUse = (int) (Math.min(newFontSize, componentHeight) * 0.5);

					// Set the label's font size to the newly determined size.
					Font font = new Font(labelFont.getName(), Font.PLAIN, fontSizeToUse);
					
					map[i][j].setFont(font);
				}
				
				// Imposta il tooltip
				map[i][j].setToolTipText("Client " + person_info[2] + " " + "("
						+ (i + 1) + ", " + (j + 1) + ")");

				// ##### SE TAVOLO ####
			} else if (cellData.length() >= 5
					&& cellData.substring(0, 5).equals("Table")) {
				// Nella forma Table_<status>_<table-id>
				String map_contains = cellData;
				String[] table_info = map_contains.split("_"); // prendiamo
																// i tre
																// campi

				String path_image = "img" + File.separator
						+ map_img.get(table_info[0] + "_" + table_info[1]);
				icon = new ImageIcon(path_image);

				// Imposta il tooltip
				map[i][j].setToolTipText(null);
				map[i][j].setToolTipText("Table " + table_info[2] + " " + "("
						+ (i + 1) + ", " + (j + 1) + ") - F:" + table_info[3]
						+ ", D:" + table_info[4]);

				// ##### ALTRIMENTI ####
				// Era una cella che non aveva bisogno di sovrapposizioni e
				// non è una persona
			} else {
				icon = new ImageIcon("img" + File.separator
						+ map_img.get(cellData));
				map[i][j].setToolTipText("(" + (i + 1) + ", " + (j + 1) + ")");
			}
			image = icon.getImage().getScaledInstance(cellDimension,
					cellDimension, Image.SCALE_SMOOTH);
			icon = new ImageIcon(image);
			map[i][j].setIcon(icon);
			map[i][j].repaint();
			// }
		}
		System.out.println("[MAP-DRAW-TIME]: "
				+ (System.currentTimeMillis() - start) + " ms.");
		DebugFrame.appendText("[SYSTEM] Step attuale: " + model.getStep());

	}

	/**
	 * Restituisce l'immagine che è la sovrapposizione fra object e background.
	 * La dimensione è quella dell'immagine più piccola
	 * 
	 * @param object
	 * @param background
	 * @return
	 */
	private ImageIcon overlapImages(BufferedImage object,
			BufferedImage background) {
		BufferedImage combined;
		Graphics g;
		// crea una nuova immagine, la dimensione è quella più grande tra le 2
		// img
		int w = Math.max(background.getWidth(), object.getWidth());
		int h = Math.max(background.getHeight(), object.getHeight());
		combined = new BufferedImage(w, h, BufferedImage.TYPE_INT_ARGB);

		// SOVRAPPONE le immagini, preservando i canali alpha per le trasparenze
		// (figo eh?)
		g = combined.getGraphics();
		g.drawImage(background, 0, 0, null);
		g.drawImage(object, 0, 0, null);

		return new ImageIcon(combined);
	}

	// @SuppressWarnings("ResultOfObjectAllocationIgnored")
	// public static void main(String[] args) {
	// new MonitorView();
	// }

	/*
	 * Metodo chiamato per resettare l'interfaccia grafica. Cancella il frame
	 * corrente Aggiorna il modello e reinizializza l'interfaccia
	 */
	@Override
	protected void reset() {
		outputFrame.dispose();
		view.dispose();

		model = new MonitorModel();
		model.addObserver((Observer) this);

		initializeInterface();
	}

	@Override
	protected void updateOutput() {
		// ########################### AGGIORNO LA FINESTRA DEI MESSAGGI DI
		// OUTPUT ############################
		outputFrame.resetDocument(); // Svuotiamo la finestra per ripopolarla
										// coi nuovi fatti
		String[] slots = { "time", "step", "source", "verbosity", "text",
				"param1", "param2", "param3", "param4", "param5", "param6",
				"param7", "param8" };
		try {
			/**
			 * Ogni fatto viene considerato nella forma: [source] testo (con
			 * parametri corretti).
			 * 
			 * È necessario compiere alcune operazioni di processing poiché: 1
			 * - le virgolette fanno parte della stringa. 2 - i parametri devono
			 * essere sostituiti.
			 */
			String[][] matriceFatti = model.findAllFacts("printGUI", "TRUE",
					slots);

			for (String[] fatto : matriceFatti) {
				int fact_verbosity = Integer.parseInt(fatto[3]); // Consideriamo
																	// la
																	// verbosità
				if (fact_verbosity <= this.verbose_mode) {
					String source = removeFistAndLastChar(fatto[2]);
					String line = fatto[1] + "\t" + source + "\t"
							+ removeFistAndLastChar(fatto[4]); // prendiamo il
																// testo così
																// com'è
					// E applichiamo le sostituzioni, appendendo il risultato
					// alla finestra
					String parameters[] = new String[fatto.length - 5];
					for (int i = 5, c = 0; i < fatto.length; i++, c++)
						parameters[c] = fatto[i];
					outputFrame.write(mapParameters(line, parameters), source);
				}
			}

		} catch (Exception ex) {
			// Logger.getLogger(MonitorView.class.getName()).log(Level.SEVERE,
			// null, ex);
		}

		// ################# AGGIORNO ANCHE L'AGENT STATUS WINDOW
		// #####################
		try {
			outputFrame.updateAgentStatusWindow(model.getStep(),
					model.getL_food(), model.getL_drink(),
					model.getL_f_waste(), model.getL_d_waste());
		} catch (NullPointerException e) {

		}

	}

	/**
	 * Sostiuisce i parametri nella forma %par<i> con param<i>.
	 * 
	 * @param text
	 * @param parameters
	 * @return
	 */
	protected String mapParameters(String text, String[] parameters) {
		for (int i = 1; i <= parameters.length; i++)
			text = text.replace("%p" + i, parameters[i - 1]);
		return text;
	}

	/**
	 * Rimuove il primo e l'ultimo carattere di una stringa. Nel nostro caso le
	 * virgolette di un text.
	 * 
	 * @return
	 */
	protected String removeFistAndLastChar(String text) {
		return text.substring(1).replace(text.substring(text.length() - 1), "");
	}

	/**
	 * Set verbosity_mode.
	 */
	public void setVerbosityMode(int mode) {
		this.verbose_mode = mode;
	}

	/**
	 * Get verbosity_mode.
	 */
	public int getVerbosityMode() {
		return verbose_mode;
	}
}
