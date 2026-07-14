package br.rio.puc.inf.monopoly.model;

import br.rio.puc.inf.monopoly.Constants.Type;

import java.util.ArrayList;
import java.util.List;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 25/10/2012
 */
public class AbstractBoardSquare
	implements Comparable
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
	 */
	public AbstractBoardSquare(
		final int initialX,
		final int initialY,
		final int finalX,
		final int finalY,
		final boolean isHorizontalSquare,
		final Type type,
		final int price )
	{
		setInitialXPosition( initialX );
		setInitialYPosition( initialY );
		setFinalXPosition( finalX );
		setFinalYPosition( finalY );
		setHorizontalSquare( isHorizontalSquare );
		setPawnList( new ArrayList<Pawn>() );
		setPrice( price );
		setType( type );
		setSameColorBoardSquareList( new ArrayList<AbstractBoardSquare>() );
		this.owner = null;
	}

	public AbstractBoardSquare(
		final int initialX,
		final int initialY,
		final int finalX,
		final int finalY,
		final boolean isHorizontalSquare,
		final Type type,
		final int price,
		final int tax,
		final int hypothec )
	{
		setInitialXPosition( initialX );
		setInitialYPosition( initialY );
		setFinalXPosition( finalX );
		setFinalYPosition( finalY );
		setHorizontalSquare( isHorizontalSquare );
		setPawnList( new ArrayList<Pawn>() );
		setPrice( price );
		setType( type );
		setSameColorBoardSquareList( new ArrayList<AbstractBoardSquare>() );
		this.owner = null;

		this.rentPrice = new int[1];
		this.rentPrice[0] = tax;

		this.hypothec = hypothec;
	}

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
	 * @param rentPrice
	 * @param housePrice
	 * @param hotelPrice
	 * @param hypothec
	 * @param group
	 */
	public AbstractBoardSquare(
		final int initialX,
		final int initialY,
		final int finalX,
		final int finalY,
		final boolean isHorizontalSquare,
		final Type type,
		final int price,
		final int[] rentPrice,
		final int housePrice,
		final int hotelPrice,
		final int hypothec,
		final int group )
	{
		setInitialXPosition( initialX );
		setInitialYPosition( initialY );
		setFinalXPosition( finalX );
		setFinalYPosition( finalY );
		setHorizontalSquare( isHorizontalSquare );
		setPawnList( new ArrayList<Pawn>() );
		setPrice( price );
		setType( type );
		this.owner = null;

		this.rentPrice = rentPrice;
		setHousePrice( housePrice );
		this.hotelPrice = hotelPrice;
		this.hypothec = hypothec;
		this.group = group;
	}

	/**
	 * <p>
	 * </p>
	 */
	public void buildHouse()
	{
		if ( this.currentRent < ( this.rentPrice.length - 1 ) )
		{
			this.currentRent++;
		}
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param arg0
	 * @return
	 * @see java.lang.Comparable#compareTo(java.lang.Object)
	 */
	@Override
	public int compareTo( final Object arg0 )
	{
		final AbstractBoardSquare other = ( AbstractBoardSquare ) arg0;

		return this.name.compareTo( other.getName() );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public int getFinalXPosition()
	{
		return this.finalXPosition;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public int getFinalYPosition()
	{
		return this.finalYPosition;
	}

	public int getHousePrice()
	{
		return this.housePrice;
	}

	public int getHouses()
	{
		return this.currentRent;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public int getInitialXPosition()
	{
		return this.initialXPosition;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public int getInitialYPosition()
	{
		return this.initialYPosition;
	}

	public String getName()
	{
		return this.name;
	}

	public Pawn getOwner()
	{
		return this.owner;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public List<Pawn> getPawnList()
	{
		return this.pawnList;
	}

	public int getPrice()
	{
		return this.price;
	}

	public List<AbstractBoardSquare> getSameColorBoardSquareList()
	{
		return this.sameColorBoardSquareList;
	}

	public Type getType()
	{
		return this.type;
	}

	public boolean hasOwner()
	{
		return ( this.owner != null );
	}

	public boolean isHorizontalSquare()
	{
		return this.horizontalSquare;
	}

	public int rent()
	{
		if ( this.rentPrice == null )
		{
			return 0;
		}

		if ( this.type == Type.COMPANHIA )
		{
			return this.rentPrice[0];
		}

		return this.rentPrice[this.currentRent];
	}

	public void sellHouse()
	{
		this.currentRent--;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param finalXPosition
	 */
	public void setFinalXPosition( final int finalXPosition )
	{
		this.finalXPosition = finalXPosition;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param finalYPosition
	 */
	public void setFinalYPosition( final int finalYPosition )
	{
		this.finalYPosition = finalYPosition;
	}

	public void setHorizontalSquare( final boolean horizontalSquare )
	{
		this.horizontalSquare = horizontalSquare;
	}

	public void setHousePrice( final int housePrice )
	{
		this.housePrice = housePrice;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param initialXPosition
	 */
	public void setInitialXPosition( final int initialXPosition )
	{
		this.initialXPosition = initialXPosition;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param initialYPosition
	 */
	public void setInitialYPosition( final int initialYPosition )
	{
		this.initialYPosition = initialYPosition;
	}

	public void setName( final String name )
	{
		this.name = name;
	}

	public void setOwner( final Pawn owner )
	{
		this.owner = owner;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawnList
	 */
	public void setPawnList( final List<Pawn> pawnList )
	{
		this.pawnList = pawnList;
	}

	public void setPrice( final int price )
	{
		this.price = price;
	}

	public void setSameColorBoardSquareList( final List<AbstractBoardSquare> sameColorBoardSquareList )
	{
		this.sameColorBoardSquareList = sameColorBoardSquareList;
	}

	public void setType( final Type type )
	{
		this.type = type;
	}

	/**
	 * <p>
	 * Field <code>currentRent</code>
	 * </p>
	 */
	private int currentRent;

	/**
	 * <p>
	 * Field <code>finalXPosition</code>
	 * </p>
	 */
	private int finalXPosition;

	/**
	 * <p>
	 * Field <code>finalYPosition</code>
	 * </p>
	 */
	private int finalYPosition;

	private int group;

	private boolean horizontalSquare;

	private int hotelPrice;

	private int housePrice;

	private int hypothec;

	/**
	 * <p>
	 * Field <code>initialXPosition</code>
	 * </p>
	 */
	private int initialXPosition;

	/**
	 * <p>
	 * Field <code>initialYPosition</code>
	 * </p>
	 */
	private int initialYPosition;

	private String name;

	private Pawn owner;

	/**
	 * <p>
	 * Field <code>pawnList</code>
	 * </p>
	 */
	private List<Pawn> pawnList;

	private int price;

	private int rentPrice[];

	private List<AbstractBoardSquare> sameColorBoardSquareList;

	private Type type;

}
