/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package xclipsjni;

import CLIPSJNI.Router;

/**
 *
 * @author piovel
 * Edited by: @author  Violanti Luca, Varesano Marco, Busso Marco, Cotrino Roberto
 */
class RouterDialog extends Router {

	//private String stdout;
	private StringBuffer stdoutBuff;
	private boolean rec;

	public RouterDialog(String name) {
		super(name, 100);
		//stdout = "";
		stdoutBuff=new StringBuffer();
		rec = false;
	}

	/**********/
	/* query: */
	/**********/
	@Override
	public synchronized boolean query(
			  String routerName) {
		if (routerName.equals("wdisplay")) {
			return true;
		}

		return false;
	}

	/**********/
	/* print: */
	/**********/
	@Override
	public synchronized void print(String routerName, String printString) {
		if (rec) {
			stdoutBuff.append(printString);
			//stdout = stdout + printString;
		}
	}

	public synchronized String getStdout() {
		return stdoutBuff.toString();
		//return stdout;
	}

	public synchronized void startRec() {
		//stdout = "";
		stdoutBuff=new StringBuffer();
		rec = true;
	}

	public synchronized void stopRec() {
		rec = false;
	}
}
