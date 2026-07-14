package br.rio.puc.inf.monopoly.facade;

import br.rio.puc.inf.monopoly.view.PlayersFrame;

import javax.swing.JFrame;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 11/12/2012
 */
public class MonopolyFacade
{

	/**
	 * <p>
	 * </p>
	 */
	public void initializeGame()
	{
		final PlayersFrame playersFrame = new PlayersFrame();
		playersFrame.setSize( 250, 500 );
		playersFrame.setResizable( false );
		playersFrame.setDefaultCloseOperation( JFrame.EXIT_ON_CLOSE );

		playersFrame.setVisible( true );
	}

}
