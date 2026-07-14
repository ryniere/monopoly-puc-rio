package br.rio.puc.inf.monopoly.model;

import br.rio.puc.inf.monopoly.Constants.Type;

import java.awt.Color;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 25/10/2012
 */
public class Pawn
	extends AbstractGameItem
{

	public Pawn()
	{
		setBoardSquarePosition( 0 );
		setArrested( 0 );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param color
	 */
	public Pawn( final Color color )
	{
		setColor( color );
	}

	public Pawn( final String name, final int money )
	{
		setBoardSquarePosition( 0 );
		this.name = name;
		this.money = money;
		setPropertyList( new ArrayList<AbstractBoardSquare>() );
		setArrested( 0 );
	}

	public Pawn( final String name, final int money, final Color color )
	{
		setBoardSquarePosition( 0 );
		this.name = name;
		this.money = money;
		this.color = color;
	}

	public void addProperty( final AbstractBoardSquare property )
	{
		this.propertyList.add( property );
		Collections.sort( this.propertyList );
	}

	public int getBoardSquarePosition()
	{
		return this.boardSquarePosition;
	}

	public int getCardsGetOutPrison()
	{
		return this.cardsGetOutPrison;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public Color getColor()
	{
		return this.color;
	}

	public int getMoney()
	{
		return this.money;
	}

	public String getName()
	{
		return this.name;
	}

	public int getPropertyLenth()
	{
		return this.propertyList.size();
	}

	public List<AbstractBoardSquare> getPropertyList()
	{
		return this.propertyList;
	}

	public String[] getPropertyNames()
	{
		final String[] names = new String[this.propertyList.size()];

		int i = 0;
		for ( final AbstractBoardSquare square : this.propertyList )
		{
			names[i] = square.getName();
			i++;
		}

		return names;
	}

	public String[] getTerrainNames()
	{
		final List<String> listName = new ArrayList<String>();

		for ( final AbstractBoardSquare square : this.propertyList )
		{
			if ( square.getType() != Type.COMPANHIA )
			{
				listName.add( square.getName() );
			}
		}

		return listName.toArray( new String[listName.size()] );
	}

	public String[] getTerrainNamesWithHouse()
	{
		final List<String> listName = new ArrayList<String>();

		for ( final AbstractBoardSquare square : this.propertyList )
		{
			if ( ( square.getType() != Type.COMPANHIA ) && ( square.getHouses() > 0 ) )
			{
				listName.add( square.getName() );
			}
		}

		return listName.toArray( new String[listName.size()] );
	}

	public int isArrested()
	{
		return this.arrested;
	}

	public void setArrested( final int arrested )
	{
		this.arrested = arrested;
	}

	public void setBoardSquarePosition( final int boardSquarePosition )
	{
		this.boardSquarePosition = boardSquarePosition;
	}

	public void setCardsGetOutPrison( final int cardsGetOutPrison )
	{
		this.cardsGetOutPrison = cardsGetOutPrison;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param color
	 */
	public void setColor( final Color color )
	{
		this.color = color;
	}

	public void setMoney( final int money )
	{
		this.money = money;
	}

	public void setName( final String name )
	{
		this.name = name;
	}

	public void setPropertyList( final List<AbstractBoardSquare> propertyList )
	{
		this.propertyList = propertyList;
	}

	public void updateMoney( final int value )
	{
		this.money += value;
	}

	/**
	 * <p>
	 * Field <code>arrested</code>
	 * </p>
	 */
	private int arrested;

	private int boardSquarePosition;

	private int cardsGetOutPrison = 0;

	/**
	 * <p>
	 * Field <code>color</code>
	 * </p>
	 */
	private Color color;

	private int money;

	private String name;

	private List<AbstractBoardSquare> propertyList;

}
