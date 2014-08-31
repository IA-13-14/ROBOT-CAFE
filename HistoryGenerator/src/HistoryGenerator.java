import java.util.Random;

/**
 * This class generates automatically an order history for the NG-Cafè, using
 * Gaussian distribution with given parameters.
 * 
 * @author BLN
 *
 */
public class HistoryGenerator {

	public int tablesNumber;

	/**
	 * 
	 * @param tablesNumber
	 *            the total number of tables available in the cafè.
	 */
	public HistoryGenerator(int tablesNumber) {
		this.tablesNumber = tablesNumber;
	}

	/**
	 * Generates an order and finish history with the given parameters. <br/>
	 * Tables are selected with uniform distribution.
	 * 
	 * @param initialStep
	 *            the initial step to start from.
	 * @param stepDuration
	 *            the maximum step to end to (last order may exceed this limit).
	 * @param orderSizeMean
	 *            the Gaussian distribution mean for the order size simulation.
	 * @param orderSizeDeviation
	 *            the Gaussian distribution standard deviation for the order
	 *            size simulation.
	 * @param orderIntervalMean
	 *            the Gaussian distribution mean for the order interval
	 *            simulation.
	 * @param orderIntervalDeviation
	 *            the Gaussian distribution standard deviation for the order
	 *            interval simulation.
	 * @param finishIntervalMean
	 *            the Gaussian distribution mean for the finish interval
	 *            simulation.
	 * @param finishIntervalDeviation
	 *            the Gaussian distribution standard deviation for the finish
	 *            interval simulation.
	 * @param finishProbability
	 *            the probability to have a finish after each order.
	 * @return the generated history.
	 */
	public String generate(int initialStep, int stepDuration,
			double orderSizeMean, double orderSizeDeviation,
			double orderIntervalMean, double orderIntervalDeviation,
			double finishIntervalMean, double finishIntervalDeviation,
			double finishProbability) {
		String history = "";
		boolean orderMustSendFinish[] = new boolean[tablesNumber + 1];
		Random rd = new Random();

		int currentStep = initialStep;
		while (currentStep < stepDuration) {
			int table = 0;
			int foodSize = 0;
			int drinkSize = 0;
			int orderInterval = 1;
			int finishInterval = 1;

			table = 1 + rd.nextInt(tablesNumber);

			do {
				foodSize = (int) Math.round(rd.nextGaussian()
						* orderSizeDeviation + orderSizeMean);
			} while (foodSize < 0 || foodSize > 4);

			do {
				drinkSize = (int) Math.round(rd.nextGaussian()
						* orderSizeDeviation + orderSizeMean);
			} while (drinkSize < 0 || drinkSize > 4);

			do {
				orderInterval = 1 + (int) Math.round(rd.nextGaussian()
						* orderIntervalDeviation + orderIntervalMean);
			} while (orderInterval < 1 || orderInterval > 20);

			currentStep += orderInterval;

			if (orderMustSendFinish[table]) {
				orderMustSendFinish[table] = false;
				history += "\n(event (step 1) (type finish) (source T" + table
						+ "))";
			}

			history += "\n(event (step " + currentStep
					+ ") (type request) (source T" + table + ") (food "
					+ foodSize + ") (drink " + drinkSize + "))";

			if (finishProbability * 100 >= rd.nextInt(101)) {
				do {
					finishInterval = 1 + (int) Math.round(rd.nextGaussian()
							* finishIntervalDeviation + finishIntervalMean);
				} while (finishInterval < 1 || finishInterval > 30);

				history += "\n(event (step " + finishInterval
						+ ") (type finish) (source T" + table + "))";

				orderMustSendFinish[table] = false;
			} else
				orderMustSendFinish[table] = true;
		}

		return history;
	}

	public static void main(String[] args) {
		HistoryGenerator hg = new HistoryGenerator(41);

		System.out.println(hg.generate(0, 100, // Step
				2, 1.2, // Consumazioni
				7, 7, // Ordini
				10, 2, 0.5// Finish
				));
	}
}
