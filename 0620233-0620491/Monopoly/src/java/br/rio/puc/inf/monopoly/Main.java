package br.rio.puc.inf.monopoly;

import br.rio.puc.inf.monopoly.facade.MonopolyFacade;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 11/12/2012
 */
public class Main
{

	/**
	 * <p>
	 * </p>
	 * 
	 * @param args
	 */
	public static void main( final String[] args )
	{
		final MonopolyFacade monopolyFacade = new MonopolyFacade();
		monopolyFacade.initializeGame();

	}

}
