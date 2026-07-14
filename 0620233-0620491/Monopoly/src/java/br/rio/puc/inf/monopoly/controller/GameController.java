package br.rio.puc.inf.monopoly.controller;

import br.rio.puc.inf.monopoly.model.AbstractBoardSquare;
import br.rio.puc.inf.monopoly.model.Board;
import br.rio.puc.inf.monopoly.model.LuckCard;
import br.rio.puc.inf.monopoly.model.LuckCard.CardType;
import br.rio.puc.inf.monopoly.model.Pawn;
import br.rio.puc.inf.monopoly.model.PrisionBoardSquare;
import br.rio.puc.inf.monopoly.observer.Observer;
import br.rio.puc.inf.monopoly.observer.Subject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 27/10/2012
 */
public class GameController
	implements Subject
{

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawnList
	 */
	public GameController( final List<Pawn> pawnList )
	{
		super();
		final List<LuckCard> luckCardList = new ArrayList<LuckCard>();

		luckCardList.add( new LuckCard( CardType.REVES_PRISAO, 0, "", "images/cartas-reves/reves-vaParaPrisao.jpg" ) );

		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			100,
			"",
			"images/cartas-reves/reves-pague-100-festaAniversario.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			100,
			"",
			"images/cartas-reves/reves-pague-100-maternidade.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			15,
			"",
			"images/cartas-reves/reves-pague-15-emprestimo.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			25,
			"",
			"images/cartas-reves/reves-pague-25-clubePiscina.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			25,
			"",
			"images/cartas-reves/reves-pague-25-novoApartamento.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			30,
			"",
			"images/cartas-reves/reves-pague-30-ballet.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			30,
			"",
			"images/cartas-reves/reves-pague-30-estacionamentoProibido.jpg" ) );
		luckCardList
			.add( new LuckCard( CardType.REVES_DINHEIRO, 30, "", "images/cartas-reves/reves-pague-30-ipva.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			40,
			"",
			"images/cartas-reves/reves-pague-40-livrosNovos.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			45,
			"",
			"images/cartas-reves/reves-pague-45-hotelMontanha.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			45,
			"",
			"images/cartas-reves/reves-pague-45-parentes.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			50,
			"",
			"images/cartas-reves/reves-pague-50-geadaCafe.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			50,
			"",
			"images/cartas-reves/reves-pague-50-impostoRenda.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.REVES_DINHEIRO,
			50,
			"",
			"images/cartas-reves/reves-pague-50-mensalidadeEscola.jpg" ) );

		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			100,
			"",
			"images/cartas-sorte/sorte-receba-100-heranca.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			100,
			"",
			"images/cartas-sorte/sorte-receba-100-premioCachorro.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			100,
			"",
			"images/cartas-sorte/sorte-receba-100-promovido.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			100,
			"",
			"images/cartas-sorte/sorte-receba-100-torneioTenis.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			150,
			"",
			"images/cartas-sorte/sorte-receba-150-assaltoSeguro.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			20,
			"",
			"images/cartas-sorte/sorte-receba-20-bolaoLoteria.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			200,
			"",
			"images/cartas-sorte/sorte-receba-200-acoesBolsa.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			200,
			"",
			"images/cartas-sorte/sorte-receba-200-avancePontoPartida.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			25,
			"",
			"images/cartas-sorte/sorte-receba-25-terrenoValorizou.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			45,
			"",
			"images/cartas-sorte/sorte-receba-45-economizouHotel.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			50,
			"",
			"images/cartas-sorte/sorte-receba-50-13Salario.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			50,
			"",
			"images/cartas-sorte/sorte-receba-50-trocaCarro.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			50,
			"",
			"images/cartas-sorte/sorte-receba-50cada-apostaJogadores.jpg" ) );
		luckCardList.add( new LuckCard(
			CardType.SORTE_DINHEIRO,
			80,
			"",
			"images/cartas-sorte/sorte-receba-80-pagamentoEmprestimo.jpg" ) );
		luckCardList.add( new LuckCard( CardType.SORTE_PRISAO, 0, "", "images/cartas-sorte/sorte-freePrision.jpg" ) );

		Collections.shuffle( luckCardList );

		setLuckCardList( luckCardList );

		setBoard( new Board( pawnList ) );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param o
	 * @see br.rio.puc.inf.monopoly.observer.Subject#add(br.rio.puc.inf.monopoly.observer.Observer)
	 */
	@Override
	public void add( final Observer o )
	{
		this.observerList.add( o );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param owner
	 * @param property
	 * @return
	 */
	public String buildHouse( final Pawn owner, final AbstractBoardSquare property )
	{
		if ( !owner.equals( property.getOwner() ) )
		{
			final String msg = String.format(
				"Jogador %s nao pode construir casas na propriedade do jogador %s.",
				owner.getName(),
				property.getOwner().getName() );

			return msg;
		}

		if ( !hasAllPropertiesFromSameColor( owner, property ) )
		{
			final String msg = String
				.format(
					"Jogador %s so podera construir casas na propiedade %s quando tiver todas as propriedades de mesma cor",
					owner.getName(),
					property.getName() );

			return msg;
		}

		if ( owner.getMoney() < property.getHousePrice() )
		{
			final String msg = String.format(
				"Jogador %s nao possui dinheiro suficiente para a construcao de casas ou hotel.",
				owner.getName() );

			return msg;
		}

		final AbstractBoardSquare propertyToBuildHouse = property;
		for ( final AbstractBoardSquare propertyCandidate : property.getSameColorBoardSquareList() )
		{
			if ( propertyCandidate.getHouses() < propertyToBuildHouse.getHouses() )
			{
				final String msg = String.format(
					"Jogador %s nao pode construir casa na propriedade %s porque a propriedade %s possui menos casas.",
					owner.getName(),
					propertyToBuildHouse.getName(),
					propertyCandidate.getName() );

				return msg;
			}
		}

		if ( propertyToBuildHouse.getHouses() < 4 )
		{
			owner.updateMoney( -property.getHousePrice() );
			propertyToBuildHouse.buildHouse();

			final String msg = String.format(
				"Jogador %s construiu casa na propriedade %s por $%s.",
				owner.getName(),
				propertyToBuildHouse.getName(),
				propertyToBuildHouse.getHousePrice() );

			return msg;
		}

		if ( propertyToBuildHouse.getHouses() == 4 )
		{
			// em todas as cartas, a construcao de hotel eh o mesmo preco da construcao de casa
			owner.updateMoney( -property.getHousePrice() );
			propertyToBuildHouse.buildHouse();

			final String msg = String.format(
				"Jogador %s construiu hotel na propriedade %s por $%s.",
				owner.getName(),
				propertyToBuildHouse.getName(),
				propertyToBuildHouse.getHousePrice() );

			return msg;
		}

		final String msg = String.format(
			"Jogador %s ja possui o maximo de construcoes na propriedade %s.",
			owner.getName(),
			propertyToBuildHouse.getName() );

		return msg;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param seller
	 * @param buyer
	 * @param propertySeller
	 * @param propertyBuyer
	 * @return
	 */
	public String exchangeProperties(
		final Pawn seller,
		final Pawn buyer,
		final AbstractBoardSquare propertySeller,
		final AbstractBoardSquare propertyBuyer )
	{
		if ( seller.equals( propertySeller.getOwner() ) )
		{
			if ( ( propertySeller.getHouses() > 0 ) || ( propertyBuyer.getHouses() > 0 ) )
			{
				final String msg = String.format(
					"A Propriedade na %s possui casas, venda-as para o banco antes de vender a propriedade",
					propertySeller.getName() );
				return msg;
			}
			sellProperty( seller, buyer, propertySeller, 0 );
			sellProperty( buyer, seller, propertyBuyer, 0 );

			final String msg = String.format(
				"A propriedade %s de %s foi trocada com %s pela propriedade %s.",
				propertySeller.getName(),
				seller.getName(),
				buyer.getName(),
				propertyBuyer.getName() );

			return msg;

		}

		return null;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param i
	 * @see br.rio.puc.inf.monopoly.observer.Subject#get(int)
	 */
	@Override
	public void get( final int i )
	{
		this.observerList.get( i );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public Board getBoard()
	{
		return this.board;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public List<LuckCard> getLuckCardList()
	{
		return this.luckCardList;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param name
	 * @return
	 */
	public AbstractBoardSquare getSquareWithName( final String name )
	{
		final List<AbstractBoardSquare> boardSquareList = this.board.getBoardSquareList();

		for ( final AbstractBoardSquare square : boardSquareList )
		{
			if ( name.equals( square.getName() ) )
			{
				return square;
			}
		}

		return null;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawn
	 * @return
	 */
	public AbstractBoardSquare goToPrison( final Pawn pawn )
	{
		final Board board = getBoard();
		final List<AbstractBoardSquare> boardSquareList = board.getBoardSquareList();
		final int pawnPosition = pawn.getBoardSquarePosition();
		final AbstractBoardSquare boardSquare = boardSquareList.get( pawnPosition );
		final List<Pawn> pawnList = boardSquare.getPawnList();
		pawnList.remove( pawn );

		final PrisionBoardSquare prisionBoardSquare = board.getPrisionBoardSquare();

		prisionBoardSquare.getPawnListOnPrision().add( pawn );
		pawn.setBoardSquarePosition( 10 );
		pawn.setArrested( 4 );
		return prisionBoardSquare;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param owner
	 * @param property
	 * @return
	 */
	public boolean hasAllPropertiesFromSameColor( final Pawn owner, final AbstractBoardSquare property )
	{
		return owner.getPropertyList().containsAll( property.getSameColorBoardSquareList() );
	}
	
	public void removePawnFromBoard( Pawn pawn )
	{
		final Board board = getBoard();
		final List<AbstractBoardSquare> boardSquareList = board.getBoardSquareList();
		final int pawnPosition = pawn.getBoardSquarePosition();
		final AbstractBoardSquare boardSquare = boardSquareList.get( pawnPosition );
		final List<Pawn> pawnList = boardSquare.getPawnList();
		pawnList.remove( pawn );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param numberOfSquaresToJump
	 * @param pawn
	 * @return
	 */
	public AbstractBoardSquare jumpBoardSquares( final int numberOfSquaresToJump, final Pawn pawn )
	{
		final Board board = getBoard();
		final List<AbstractBoardSquare> boardSquareList = board.getBoardSquareList();
		final int pawnPosition = pawn.getBoardSquarePosition();
		final AbstractBoardSquare boardSquare = boardSquareList.get( pawnPosition );
		final List<Pawn> pawnList = boardSquare.getPawnList();
		pawnList.remove( pawn );

		final int boardSquareListSize = boardSquareList.size();

		final AbstractBoardSquare newBoardSquare;
		final int currentPositionPlusPositionsToJump = pawnPosition + numberOfSquaresToJump;
		if ( currentPositionPlusPositionsToJump < boardSquareListSize )
		{
			newBoardSquare = boardSquareList.get( currentPositionPlusPositionsToJump );
			pawn.setBoardSquarePosition( currentPositionPlusPositionsToJump );
		}
		else
		{
			// jogador recebe 200 por passar pelo inicio
			pawn.updateMoney( 200 );
			final int squaresToJumpAtEnd = boardSquareListSize - pawnPosition;
			final int squaresToJumpAtBegin = numberOfSquaresToJump - squaresToJumpAtEnd;
			newBoardSquare = boardSquareList.get( squaresToJumpAtBegin );
			pawn.setBoardSquarePosition( squaresToJumpAtBegin );
		}

		newBoardSquare.getPawnList().add( pawn );
		return newBoardSquare;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @see br.rio.puc.inf.monopoly.observer.Subject#notifyObservers()
	 */
	@Override
	public void notifyObservers()
	{
		for ( final Observer o : this.observerList )
		{
			o.update();
		}

	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawn
	 * @return
	 */
	public AbstractBoardSquare outOfPrision( final Pawn pawn )
	{
		final Board board = getBoard();
		final List<AbstractBoardSquare> boardSquareList = board.getBoardSquareList();
		final int pawnPosition = pawn.getBoardSquarePosition();
		final AbstractBoardSquare boardSquare = boardSquareList.get( pawnPosition );
		final List<Pawn> pawnList = boardSquare.getPawnList();
		pawnList.add( pawn );

		final PrisionBoardSquare prisionBoardSquare = board.getPrisionBoardSquare();

		prisionBoardSquare.getPawnListOnPrision().remove( pawn );

		pawn.setArrested( 0 );
		return prisionBoardSquare;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param o
	 * @see br.rio.puc.inf.monopoly.observer.Subject#remove(br.rio.puc.inf.monopoly.observer.Observer)
	 */
	@Override
	public void remove( final Observer o )
	{
		this.observerList.remove( o );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param seller
	 * @param property
	 * @return
	 */
	public String sellHouse( final Pawn seller, final AbstractBoardSquare property )
	{
		String msg = "";
		if ( seller.equals( property.getOwner() ) )
		{
			if ( property.getHouses() > 0 )
			{
				final int value = ( property.getHousePrice() / 2 );

				seller.updateMoney( value );
				property.sellHouse();

				String construcao = "uma casa";
				if ( ( property.getHouses() + 1 ) == 5 )
				{
					construcao = "um hotel";
				}

				msg = String.format(
					"Jogador %s vendeu %s em %s por $%s.",
					seller.getName(),
					construcao,
					property.getName(),
					value );
			}
		}
		return msg;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param seller
	 * @param buyer
	 * @param property
	 * @param value
	 * @return
	 */
	public String sellProperty( final Pawn seller, final Pawn buyer, final AbstractBoardSquare property, final int value )
	{
		if ( seller.equals( property.getOwner() ) )
		{
			if ( property.getHouses() > 0 )
			{
				final String msg = String.format(
					"A Propriedade na %s possui casas, venda-as para o banco antes de vender a propriedade",
					property.getName() );
				return msg;
			}
			property.setOwner( buyer );
			buyer.addProperty( property );
			seller.getPropertyList().remove( property );
			buyer.updateMoney( -value );
			seller.updateMoney( value );

			final String msg = String.format(
				"A propriedade %s de %s foi vendida para %s por $%s",
				property.getName(),
				seller.getName(),
				buyer.getName(),
				value );
			return msg;

		}

		return null;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param seller
	 * @param property
	 * @return
	 */
	public String sellPropertyToBank( final Pawn seller, final AbstractBoardSquare property )
	{
		final int value = property.getPrice();

		if ( seller.equals( property.getOwner() ) )
		{
			if ( property.getHouses() > 0 )
			{
				final String msg = String.format(
					"A Propriedade na %s possui casas, venda-as para o banco antes de vender a propriedade",
					property.getName() );
				return msg;
			}
			property.setOwner( null );
			seller.getPropertyList().remove( property );
			seller.updateMoney( value );

			final String msg = String.format(
				"A propriedade %s de %s foi vendida para o banco por $%s",
				property.getName(),
				seller.getName(),
				value );
			return msg;

		}

		return null;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param board
	 */
	public void setBoard( final Board board )
	{
		this.board = board;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param luckCardList
	 */
	public void setLuckCardList( final List<LuckCard> luckCardList )
	{
		this.luckCardList = luckCardList;
	}

	/**
	 * <p>
	 * Field <code>board</code>
	 * </p>
	 */
	private Board board;

	/**
	 * <p>
	 * Field <code>luckCardList</code>
	 * </p>
	 */
	private List<LuckCard> luckCardList;

	/**
	 * <p>
	 * Field <code>observerList</code>
	 * </p>
	 */
	private List<Observer> observerList = new ArrayList<Observer>();

}
