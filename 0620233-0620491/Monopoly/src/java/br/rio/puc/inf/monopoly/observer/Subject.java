package br.rio.puc.inf.monopoly.observer;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on Sep 25, 2012
 */
public interface Subject
{

	/**
	 * <p>
	 * </p>
	 * 
	 * @param o
	 */
	public void add( Observer o );

	/**
	 * <p>
	 * </p>
	 * 
	 * @param i
	 */
	public void get( int i );

	/**
	 * <p>
	 * </p>
	 */
	public void notifyObservers();

	/**
	 * <p>
	 * </p>
	 * 
	 * @param o
	 */
	public void remove( Observer o );

}
