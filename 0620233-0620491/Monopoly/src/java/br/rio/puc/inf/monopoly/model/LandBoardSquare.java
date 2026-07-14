package br.rio.puc.inf.monopoly.model;

import br.rio.puc.inf.monopoly.Constants.Type;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 21/11/2012
 */
public class LandBoardSquare
	extends AbstractBoardSquare
{

	/**
	 * <p>
	 * </p>
	 * 
	 * @param initialX
	 * @param initialY
	 * @param finalX
	 * @param finalY
	 * @param isHorizontalSquare
	 * @param type
	 * @param price
	 */
	public LandBoardSquare(
		final int initialX,
		final int initialY,
		final int finalX,
		final int finalY,
		final boolean isHorizontalSquare,
		final Type type,
		final int price )
	{
		super( initialX, initialY, finalX, finalY, isHorizontalSquare, type, price );
	}

}
