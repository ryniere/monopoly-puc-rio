package br.rio.puc.inf.monopoly.model;

import br.rio.puc.inf.monopoly.Constants.Type;

import java.util.ArrayList;
import java.util.List;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 14/11/2012
 */
public class PrisionBoardSquare
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
	public PrisionBoardSquare(
		final int initialX,
		final int initialY,
		final int finalX,
		final int finalY,
		final boolean isHorizontalSquare,
		final Type type,
		final int price )
	{
		super( 758, 710, 789, 790, isHorizontalSquare, type, price );
		setPawnListOnPrision( new ArrayList<Pawn>() );
		setInitialXPositionJail( initialX );
		setFinalXPositionJail( finalX );
		setInitialYPositionJail( initialY );
		setFinalYPositionJail( finalY );

	}

	public int getFinalXPositionJail()
	{
		return this.finalXPositionJail;
	}

	public int getFinalYPositionJail()
	{
		return this.finalYPositionJail;
	}

	public int getInitialXPositionJail()
	{
		return this.initialXPositionJail;
	}

	public int getInitialYPositionJail()
	{
		return this.initialYPositionJail;
	}

	public List<Pawn> getPawnListOnPrision()
	{
		return this.pawnListOnPrision;
	}

	public void setFinalXPositionJail( final int finalXPositionJail )
	{
		this.finalXPositionJail = finalXPositionJail;
	}

	public void setFinalYPositionJail( final int finalYPositionJail )
	{
		this.finalYPositionJail = finalYPositionJail;
	}

	public void setInitialXPositionJail( final int initialXPositionJail )
	{
		this.initialXPositionJail = initialXPositionJail;
	}

	public void setInitialYPositionJail( final int initialYPositionJail )
	{
		this.initialYPositionJail = initialYPositionJail;
	}

	public void setPawnListOnPrision( final List<Pawn> pawnListOnPrision )
	{
		this.pawnListOnPrision = pawnListOnPrision;
	}

	/**
	 * <p>
	 * Field <code>finalXPosition</code>
	 * </p>
	 */
	private int finalXPositionJail;

	/**
	 * <p>
	 * Field <code>finalYPosition</code>
	 * </p>
	 */
	private int finalYPositionJail;

	/**
	 * <p>
	 * Field <code>initialXPosition</code>
	 * </p>
	 */
	private int initialXPositionJail;

	/**
	 * <p>
	 * Field <code>initialYPosition</code>
	 * </p>
	 */
	private int initialYPositionJail;

	private List<Pawn> pawnListOnPrision;

}
