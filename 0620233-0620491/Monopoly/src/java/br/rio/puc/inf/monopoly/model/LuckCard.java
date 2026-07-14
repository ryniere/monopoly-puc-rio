package br.rio.puc.inf.monopoly.model;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on Oct 22, 2012
 */
public class LuckCard
	extends AbstractGameItem
{

	/**
	 * <p>
	 * </p>
	 * 
	 * @author ryniere
	 * @version 1.0 Created on 10/11/2012
	 */
	public enum CardType
	{
		/**
		 * <p>
		 * Field <code>REVES_DINHEIRO</code>
		 * </p>
		 */
		REVES_DINHEIRO, /**
		 * <p>
		 * Field <code>REVES_PRISAO</code>
		 * </p>
		 */
		REVES_PRISAO, /**
		 * <p>
		 * Field <code>SORTE_DINHEIRO</code>
		 * </p>
		 */
		SORTE_DINHEIRO, /**
		 * <p>
		 * Field <code>SORTE_PRISAO</code>
		 * </p>
		 */
		SORTE_PRISAO
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param cardType
	 * @param value
	 * @param description
	 */
	public LuckCard( final CardType cardType, final double value, final String description, final String path )
	{
		super();
		setCardType( cardType );
		setValue( value );
		setDescription( description );
		setImagePath( path );

	}

	public CardType getCardType()
	{
		return this.cardType;
	}

	public String getDescription()
	{
		return this.description;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public double getValue()
	{
		return this.value;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param cardType
	 */
	public void setCardType( final CardType cardType )
	{
		this.cardType = cardType;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param description
	 */
	public void setDescription( final String description )
	{
		this.description = description;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param value
	 */
	public void setValue( final double value )
	{
		this.value = value;
	}

	/**
	 * <p>
	 * Field <code>cardType</code>
	 * </p>
	 */
	private CardType cardType;

	/**
	 * <p>
	 * Field <code>description</code>
	 * </p>
	 */
	private String description;

	/**
	 * <p>
	 * Field <code>value</code>
	 * </p>
	 */
	private double value;

}
