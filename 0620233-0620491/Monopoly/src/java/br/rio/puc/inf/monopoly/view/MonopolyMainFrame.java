package br.rio.puc.inf.monopoly.view;

import br.rio.puc.inf.monopoly.Constants;
import br.rio.puc.inf.monopoly.controller.GameController;
import br.rio.puc.inf.monopoly.model.AbstractBoardSquare;
import br.rio.puc.inf.monopoly.model.Board;
import br.rio.puc.inf.monopoly.model.LuckCard;
import br.rio.puc.inf.monopoly.model.Pawn;
import br.rio.puc.inf.monopoly.observer.Observer;

import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.util.List;
import java.util.ListIterator;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 09/12/2012
 */
public class MonopolyMainFrame
	extends JFrame
	implements ActionListener, Observer
{

	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawnList
	 */
	public MonopolyMainFrame( final List<Pawn> pawnList )
	{
		super( "Monopoly" );

		setDefaultCloseOperation( JFrame.EXIT_ON_CLOSE );
		setExtendedState( JFrame.MAXIMIZED_BOTH );

		this.mPawnList = pawnList;
		init();

		setVisible( true );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param arg0
	 * @see java.awt.event.ActionListener#actionPerformed(java.awt.event.ActionEvent)
	 */
	@Override
	public void actionPerformed( final ActionEvent arg0 )
	{
		boolean repaintRightPanelToNextPlayer = false;
		
		String actionCommand = arg0.getActionCommand();

		if ( "JOGAR_DADOS".equals( actionCommand ) || "JOGAR_NUMERO".equals( actionCommand ) )
		{

			int numero1;
			int numero2;

			if ( "JOGAR_NUMERO".equals( actionCommand ) )
			{
				final String text = this.mTextField.getText();
				final String[] numbers = text.split( " " );

				if ( numbers.length != 2 )
				{
					jogarDadosErroMessage();
					return;
				}

				try
				{
					numero1 = Integer.parseInt( numbers[0] );
					numero2 = Integer.parseInt( numbers[1] );
				}
				catch ( final Exception e )
				{
					jogarDadosErroMessage();
					return;
				}

				this.mTextField.setText( "" );
			}
			else
			{
				numero1 = ( int ) ( Math.random() * 6 ) + 1;
				numero2 = ( int ) ( Math.random() * 6 ) + 1;
			}

			this.mCurrentPawn++;
			if ( this.mCurrentPawn == this.mPawnList.size() )
			{
				this.mCurrentPawn = 0;
			}

			final Pawn pawn = this.mPawnList.get( this.mCurrentPawn );

			this.mTextArea.append( "\nJogador " + pawn.getName() + " tirou " + numero1 + " e " + numero2 + "." );

			boolean walkWithPawn = true;
			if ( pawn.isArrested() > 0 )
			{
				if ( pawn.isArrested() == 1 )
				{
					this.mGameController.outOfPrision( pawn );
					this.mTextArea.append( "\nJogador "
						+ pawn.getName()
						+ " saiu da prisao e pagou $"
						+ Constants.PRISON_MONEY
						+ "." );
					pawn.updateMoney( pawn.getMoney() - Constants.PRISON_MONEY );
					paintLeftPanel();

				}
				else if ( numero1 == numero2 )
				{
					this.mGameController.outOfPrision( pawn );
					this.mTextArea.append( "\nJogador "
						+ pawn.getName()
						+ " tirou dois numeros iguais entao saiu da prisao!" );
				}
				else
				{
					walkWithPawn = false;
					this.mTextArea.append( "\nFaltam "
						+ ( pawn.isArrested() - 1 )
						+ " rodadas para "
						+ pawn.getName()
						+ " sair da prisao, se nao tirar dois numeros iguais... " );
					pawn.setArrested( ( pawn.isArrested() - 1 ) );
					repaintRightPanelToNextPlayer = true;
				}
			}
			else
			{
				if ( numero1 == numero2 )
				{
					this.mRepeatedDices++;

					if ( this.mRepeatedDices == 3 )
					{
						this.mTextArea.append( "\nJogador "
							+ pawn.getName()
							+ " foi PRESO porque tirou 2 numeros iguais 3 vezes." );
						
						goToPrison( pawn );
						
						this.mRepeatedDices = 0;
						walkWithPawn = false;

						repaintRightPanelToNextPlayer = true;
					}
					else
					{
						this.mTextArea.append( "\nJogador "
							+ pawn.getName()
							+ " joga novamente porque tirou 2 numeros iguais." );

						this.mCurrentPawn--;
						if ( this.mCurrentPawn == -1 )
						{
							this.mCurrentPawn = ( this.mPawnList.size() - 1 );
						}
					}

				}
				else
				{
					this.mRepeatedDices = 0;
				}
			}

			if ( walkWithPawn )
			{
				this.mCurrentPawnSquare = this.mGameController.jumpBoardSquares( numero1 + numero2, pawn );
				this.mCurrentPawnPlayer = pawn;

				pawnOnBoardSquare( this.mCurrentPawnPlayer, this.mCurrentPawnSquare, numero1 + numero2 );
				paintLeftPanel();
				
			}
			repaint();

		}
		else if ( "COMPRAR".equals( actionCommand ) )
		{

			final Pawn pawn = this.mCurrentPawnPlayer;
			String msg = "";
			if ( pawn.getMoney() >= this.mCurrentPawnSquare.getPrice() )
			{
				pawn.setMoney( pawn.getMoney() - this.mCurrentPawnSquare.getPrice() );
				this.mCurrentPawnSquare.setOwner( pawn );
				pawn.addProperty( this.mCurrentPawnSquare );
				msg = "\n"
					+ pawn.getName()
					+ " comprou "
					+ this.mCurrentPawnSquare.getName()
					+ " por $"
					+ this.mCurrentPawnSquare.getPrice()
					+ ".";

				paintLeftPanel();
			}
			else
			{
				msg = "\n"
					+ pawn.getName()
					+ " nao possui dinheiro para comprar "
					+ this.mCurrentPawnSquare.getName()
					+ ".";
			}

			this.mTextArea.append( msg );
			repaintRightPanelToNextPlayer = true;
		}
		else if ( "NAO_COMPRAR".equals( actionCommand ) )
		{

			final Pawn pawn = this.mCurrentPawnPlayer;
			this.mTextArea.append( "\n " + pawn.getName() + " nao comprou " + this.mCurrentPawnSquare.getName() + "." );
			repaintRightPanelToNextPlayer = true;

		}
		else if ( "CONSTRUIR_CASA".equals( actionCommand ) )
		{

			final Pawn pawn = getNextPlayer();

			final String[] terrainNames = pawn.getTerrainNames();

			if ( terrainNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhum terreno.",
					"Sem Terreno",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				final int response = JOptionPane.showOptionDialog(
					null,
					"Em qual terreno deseja construir?",
					"Escolha o terreno",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					terrainNames,
					null );

				final AbstractBoardSquare square = this.mGameController.getSquareWithName( terrainNames[response] );
				final String msg = this.mGameController.buildHouse( pawn, square );
				this.mTextArea.append( "\n" + msg );
				paintLeftPanel();
			}

		}
		else if ( "VENDER_CASA".equals( actionCommand ) )
		{

			final Pawn pawn = getNextPlayer();

			final String[] terrainNames = pawn.getTerrainNamesWithHouse();

			if ( terrainNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhum terreno com casas ou hotel.",
					"Sem Casas",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				final int response = JOptionPane.showOptionDialog(
					null,
					"De qual terreno deseja vender a casa? (o jogador recebera metado do valor da construcao) ",
					"Escolha o terreno",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					terrainNames,
					null );

				if ( response == -1 )
				{
					return;
				}

				final AbstractBoardSquare square = this.mGameController.getSquareWithName( terrainNames[response] );
				final String msg = this.mGameController.sellHouse( pawn, square );
				this.mTextArea.append( "\n" + msg );
				paintLeftPanel();
			}

		}
		else if ( "TROCAR_PROPRIEDADE".equals( actionCommand ) )
		{
			final Pawn pawn = getNextPlayer();

			String[] propertiesNames = pawn.getPropertyNames();

			if ( propertiesNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhuma propriedade.",
					"Sem Propriedade",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				int response = JOptionPane.showOptionDialog(
					null,
					"Qual propriedade deseja trocar?",
					"Escolha a propriedade",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					propertiesNames,
					null );

				final AbstractBoardSquare propertySeller = this.mGameController
					.getSquareWithName( propertiesNames[response] );

				final String[] playersName = getOthersPlayersName( pawn.getName() );

				response = JOptionPane.showOptionDialog(
					null,
					"Qual jogador ir� trocar com voce?",
					"Escolha um jogador",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					playersName,
					null );

				final Pawn buyer = getPlayerWithName( playersName[response] );
				propertiesNames = buyer.getPropertyNames();

				response = JOptionPane.showOptionDialog(
					null,
					"Qual propriedade deseja trocar?",
					"Escolha a propriedade",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					propertiesNames,
					null );

				final AbstractBoardSquare propertyBuyer = this.mGameController
					.getSquareWithName( propertiesNames[response] );

				final String msg = this.mGameController
					.exchangeProperties( pawn, buyer, propertySeller, propertyBuyer );

				this.mTextArea.append( "\n" + msg );
				paintLeftPanel();
			}
		}
		else if ( "VENDER_PROPRIEDADE".equals( actionCommand ) )
		{
			final Pawn pawnSeller = getNextPlayer();

			final String[] propertiesNames = pawnSeller.getPropertyNames();

			if ( propertiesNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhuma propriedade.",
					"Sem Propriedade",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				int response = JOptionPane.showOptionDialog(
					null,
					"Qual propriedade deseja vender?",
					"Escolha a propriedade",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					propertiesNames,
					null );

				final AbstractBoardSquare propertyToSell = this.mGameController
					.getSquareWithName( propertiesNames[response] );

				final String[] playersName = getOthersPlayersNameWithBank( pawnSeller.getName() );

				response = JOptionPane.showOptionDialog(
					null,
					"Qual jogador ira comprar a sua propriedade? (O banco pode compra-la pelo preco da compra)",
					"Escolha um jogador",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					playersName,
					null );

				String msg = "";

				if ( response == ( playersName.length - 1 ) ) // venda para o banco (eh o ultimo do
																// vetor) pelo preco da compra
				{
					msg = this.mGameController.sellPropertyToBank( pawnSeller, propertyToSell );
				}
				else
				{
					String priceStr = "";
					int price = -1;

					while ( price == -1 )
					{
						priceStr = JOptionPane.showInputDialog( null, "Entre com o valor da venda:" );

						try
						{
							price = Integer.valueOf( priceStr );
						}
						catch ( final Exception e )
						{
							price = -1;
						}
					}

					final Pawn pawnBuyer = getPlayerWithName( playersName[response] );

					msg = this.mGameController.sellProperty( pawnSeller, pawnBuyer, propertyToSell, price );
				}

				this.mTextArea.append( "\n" + msg );
				paintLeftPanel();
			}
		}
		else if ( "OK".equals( actionCommand ) )
		{
			repaintRightPanelToNextPlayer = true;
		}
		else
		{
			System.out.println( "Erro - MonopolyMainFrame::actionPerformed - Acao nao tratada" );
		}

		if ( repaintRightPanelToNextPlayer )
		{
			paintRightPanelToNextPlayer();
			repaint();
		}

	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	private Pawn getNextPlayer()
	{
		int currentPawn = this.mCurrentPawn + 1;
		if ( currentPawn == this.mPawnList.size() )
		{
			currentPawn = 0;
		}

		return this.mPawnList.get( currentPawn );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param myName
	 * @return
	 */
	private String[] getOthersPlayersName( final String myName )
	{
		final String[] names = new String[this.mPawnList.size() - 1];

		int i = 0;
		for ( final Pawn pawn : this.mPawnList )
		{
			if ( ( pawn != null ) && !pawn.getName().equals( myName ) )
			{
				names[i] = pawn.getName();
				i++;
			}
		}

		return names;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param myName
	 * @return
	 */
	private String[] getOthersPlayersNameWithBank( final String myName )
	{
		final String[] names = new String[this.mPawnList.size()];

		int i = 0;
		for ( final Pawn pawn : this.mPawnList )
		{
			if ( ( pawn != null ) && !pawn.getName().equals( myName ) )
			{
				names[i] = pawn.getName();
				i++;
			}
		}
		names[i] = "Banco";

		return names;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param name
	 * @return
	 */
	private Pawn getPlayerWithName( final String name )
	{

		for ( final Pawn pawn : this.mPawnList )
		{
			if ( name.equals( pawn.getName() ) )
			{
				return pawn;
			}
		}

		return null;
	}

	/**
	 * <p>
	 * </p>
	 */
	public void init()
	{

		this.mGameController = new GameController( this.mPawnList );
		this.mGameController.add( this );
		final Board board = this.mGameController.getBoard();
		this.mBoardView = new BoardView( board );

		// Inicializa Painel Principal
		this.mMainPanel = new JPanel();
		this.mMainPanel.setLayout( new BorderLayout( 30, 0 ) );
		this.mMainPanel.add( this.mBoardView, BorderLayout.CENTER );

		// Inicializa Painel da Esqueda
		this.mLeftPanel = new JPanel();
		this.mLeftPanel.setLayout( new GridLayout( 0, 1 ) );
		paintLeftPanel();

		this.mMainPanel.add( this.mLeftPanel, BorderLayout.WEST );

		// Inicializa Barra de Notificacoes
		this.mTextArea = new JTextArea();
		this.mTextArea.setRows( 2 );
		this.mTextArea.setEditable( false );
		this.mTextArea.setAutoscrolls( true );
		final JScrollPane scrollPane = new JScrollPane( this.mTextArea );
		this.mMainPanel.add( scrollPane, BorderLayout.SOUTH );

		// Inicializa Painel da Direita
		this.mDadosBtn = new JButton( "Jogar Dados" );
		this.mDadosBtn.setActionCommand( "JOGAR_DADOS" );
		this.mDadosBtn.addActionListener( this );

		this.mTextField = new JTextField();
		this.mBtnPlay = new JButton( "Jogar Numeros" );
		this.mBtnPlay.setActionCommand( "JOGAR_NUMERO" );
		this.mBtnPlay.addActionListener( this );

		this.mRightPanel = new JPanel();
		this.mMainPanel.add( this.mRightPanel, BorderLayout.EAST );

		paintRightPanelToNextPlayer();

		getContentPane().add( this.mMainPanel );
	}

	private void jogarDadosErroMessage()
	{
		JOptionPane.showMessageDialog(
			null,
			"Digite dois numeros inteiros separados por um espaco no campo de texto.",
			"Jogar Numeros",
			JOptionPane.WARNING_MESSAGE );
	}

	/**
	 * <p>
	 * </p>
	 */
	private void paintLeftPanel()
	{
		this.mLeftPanel.removeAll();
		this.mLeftPanel.add( new JLabel( "" ) );
		this.mLeftPanel.add( new JLabel( "  Jogadores:  " ) );
		this.mLeftPanel.add( new JLabel( "" ) );

		for ( int i = 0; i < this.mPawnList.size(); i++ )
		{
			final Pawn pawn = this.mPawnList.get( i );
			final JLabel playerName = new JLabel( pawn.getName() + " - $" + String.valueOf( pawn.getMoney() ) );
			playerName.setForeground( pawn.getColor() );
			this.mLeftPanel.add( playerName );

			for ( final AbstractBoardSquare property : pawn.getPropertyList() )
			{
				String propertyText = "  - " + property.getName();

				if ( property.getType() != Constants.Type.COMPANHIA )
				{
					if ( property.getHouses() < 5 )
					{
						propertyText += " : " + property.getHouses() + " casa(s)";
					}
					else
					{
						propertyText += " : " + " Hotel";
					}
				}

				final JLabel propLabel = new JLabel( propertyText );
				this.mLeftPanel.add( propLabel );
			}
			this.mLeftPanel.add( new JLabel( "" ) );
		}

		for ( int i = 0; i < 5; i++ )
		{
			this.mLeftPanel.add( new JLabel( "" ) );
		}

		this.mLeftPanel.revalidate();
	}

	/**
	 * <p>
	 * </p>
	 */
	private void paintRightPanelToNextPlayer()
	{
		final Pawn pawn = getNextPlayer();

		final JLabel labelName = new JLabel( pawn.getName() + "," );
		final JLabel label = new JLabel( "Eh a sua vez de jogar, o que deseja fazer?   " );

		final JButton btnBuildHH = new JButton( "Construir Casa/Hotel" );
		btnBuildHH.setActionCommand( "CONSTRUIR_CASA" );
		btnBuildHH.addActionListener( this );

		final JButton btnSellHH = new JButton( "Vender Casa/Hotel" );
		btnSellHH.setActionCommand( "VENDER_CASA" );
		btnSellHH.addActionListener( this );

		final JButton btnExchangeProp = new JButton( "Trocar Propriedade" );
		btnExchangeProp.setActionCommand( "TROCAR_PROPRIEDADE" );
		btnExchangeProp.addActionListener( this );

		final JButton btnSellProperty = new JButton( "Vender Propriedade" );
		btnSellProperty.setActionCommand( "VENDER_PROPRIEDADE" );
		btnSellProperty.addActionListener( this );

		this.mRightPanel.removeAll();
		this.mRightPanel.setLayout( new GridLayout( 0, 1 ) );

		this.mRightPanel.add( new JLabel( "" ) );

		this.mRightPanel.add( labelName );
		this.mRightPanel.add( label );
		this.mRightPanel.add( new JLabel( "" ) );

		this.mRightPanel.add( btnBuildHH );
		this.mRightPanel.add( btnSellHH );
		this.mRightPanel.add( new JLabel( "" ) );

		this.mRightPanel.add( btnExchangeProp );
		this.mRightPanel.add( btnSellProperty );
		this.mRightPanel.add( new JLabel( "" ) );
		this.mRightPanel.add( new JLabel( "" ) );

		this.mRightPanel.add( this.mDadosBtn );
		this.mRightPanel.add( new JLabel( "" ) );

		this.mRightPanel.add( this.mTextField );
		this.mRightPanel.add( this.mBtnPlay );

		for ( int i = 0; i < 10; i++ )
		{
			this.mRightPanel.add( new JLabel( "" ) );
		}

		this.mRightPanel.revalidate();
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawn
	 */
	private void pawnEliminated( final Pawn pawn )
	{

		this.mPawnList.remove( pawn );
		this.mGameController.removePawnFromBoard(pawn);
		
		this.mCurrentPawn--;
		if ( this.mCurrentPawn == -1 )
		{
			this.mCurrentPawn = this.mPawnList.size();
		}

		if ( this.mPawnList.size() == 1 )
		{
			Pawn winner = this.mPawnList.get( 0 );
			
			String msgWin = String.format( "%s, PARABENS! Voce eh o vencedor do jogo com %s propriedades e com $%s!",
											winner.getName(),
											winner.getPropertyLenth(),
											winner.getMoney() );  
			
			JOptionPane.showMessageDialog(
					null,
					msgWin,
					"Vencedor!",
					JOptionPane.INFORMATION_MESSAGE );
			
			try 
			{
				this.finalize();
			} 
			catch (Throwable e) 
			{
				System.out.println( "Erro ao finalizar o jogo." );
			}
			this.dispose();
		}

		this.mTextArea.append( "\n" + pawn.getName() + " nao teve como pagar suas dividas e esta fora!" );
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param pawn
	 * @param square
	 * @param dicesSum
	 */
	private void pawnOnBoardSquare( final Pawn pawn, final AbstractBoardSquare square, final int dicesSum )
	{
		this.mRightPanel.removeAll();
		boolean paintRightPanelToNextPlayer = false;

		switch ( square.getType() )
		{

			case TERRENO_AMARELO :
			case TERRENO_AZUL :
			case TERRENO_VERDE :
			case TERRENO_VERMELHO :
			case TERRENO_ROXO :
			case TERRENO_VINHO :
			case TERRENO_ROSA :
			case TERRENO_LARANJA :
				if ( square.getOwner() == null )
				{
					final JLabel labelName = new JLabel( pawn.getName() + "," );
					final JLabel label = new JLabel( "Deseja comprar a propriedade "
						+ square.getName()
						+ " por $"
						+ square.getPrice()
						+ "?       " );

					final JButton btnSim = new JButton( "Sim" );
					btnSim.setActionCommand( "COMPRAR" );
					btnSim.addActionListener( this );

					final JButton btnNao = new JButton( "Nao" );
					btnNao.setActionCommand( "NAO_COMPRAR" );
					btnNao.addActionListener( this );

					this.mRightPanel.setLayout( new GridLayout( 0, 1 ) );
					this.mRightPanel.add( labelName );
					this.mRightPanel.add( label );
					this.mRightPanel.add( btnSim );
					this.mRightPanel.add( btnNao );

					for ( int i = 0; i < 20; i++ )
					{
						this.mRightPanel.add( new JLabel( " " ) );
					}

					this.mRightPanel.revalidate();

				}
				else
				{
					final Pawn squareOwner = square.getOwner();

					if ( squareOwner.equals( pawn ) )
					{
						this.mTextArea.append( "\n"
							+ pawn.getName()
							+ " caiu em sua propria proriedade: "
							+ square.getName()
							+ "." );

						paintRightPanelToNextPlayer = true;

					}
					else
					{
						this.mTextArea.append( "\n"
							+ pawn.getName()
							+ " pagou $"
							+ square.rent()
							+ " para "
							+ squareOwner.getName()
							+ " por ter caido em sua propria proriedade: "
							+ square.getName()
							+ "." );

						pawn.setMoney( pawn.getMoney() - square.rent() );
						squareOwner.setMoney( squareOwner.getMoney() + square.rent() );

						paintLeftPanel();
						paintRightPanelToNextPlayer = true;
					}

				}
				break;

			case COMPANHIA :
				if ( square.getOwner() == null )
				{
					final JLabel labelName = new JLabel( pawn.getName() + "," );
					final JLabel label = new JLabel( "Deseja comprar a companhia "
						+ square.getName()
						+ " por $"
						+ square.getPrice()
						+ "?       " );

					final JButton btnSim = new JButton( "Sim" );
					btnSim.setActionCommand( "COMPRAR" );
					btnSim.addActionListener( this );

					final JButton btnNao = new JButton( "Nao" );
					btnNao.setActionCommand( "NAO_COMPRAR" );
					btnNao.addActionListener( this );

					this.mRightPanel.setLayout( new GridLayout( 0, 1 ) );
					this.mRightPanel.add( labelName );
					this.mRightPanel.add( label );
					this.mRightPanel.add( btnSim );
					this.mRightPanel.add( btnNao );

					for ( int i = 0; i < 20; i++ )
					{
						this.mRightPanel.add( new JLabel( " " ) );
					}

					this.mRightPanel.revalidate();

				}
				else
				{
					final int rent = square.rent() * dicesSum;
					final Pawn squareOwner = square.getOwner();

					if ( squareOwner.equals( pawn ) )
					{
						this.mTextArea.append( "\n"
							+ pawn.getName()
							+ " caiu em sua propria proriedade: "
							+ square.getName()
							+ "." );

						paintRightPanelToNextPlayer = true;

					}
					else
					{
						this.mTextArea.append( "\n"
							+ pawn.getName()
							+ " pagou $"
							+ rent
							+ " para "
							+ squareOwner.getName()
							+ " por ter caido na casa "
							+ square.getName() );

						pawn.setMoney( pawn.getMoney() - rent );
						squareOwner.setMoney( squareOwner.getMoney() + rent );

						paintLeftPanel();
						paintRightPanelToNextPlayer = true;
					}


				}
				break;

			case SORTE_REVES :
			{

				this.mRightPanel.setLayout( new GridLayout( 4, 1 ) );

				final JPanel labelPanel = new JPanel( new GridLayout( 2, 1 ) );
				labelPanel.add( new JLabel( "                Carta Sorte-Reves:                      " ) );
				labelPanel.add( new JLabel( pawn.getName() + ", voce tirou a carta: " ) );
				this.mRightPanel.add( labelPanel );

				final List<LuckCard> luckCardList = this.mGameController.getLuckCardList();

				final ListIterator<LuckCard> listIterator = luckCardList.listIterator();
				final LuckCard luckCard = listIterator.next();

				final LuckCardView luckCardView = new LuckCardView( luckCard );

				this.mRightPanel.add( luckCardView );

				final JPanel okPanel = new JPanel( new GridLayout( 6, 1 ) );
				final JButton btnOk = new JButton( "OK" );
				btnOk.addActionListener( this );

				okPanel.add( btnOk );
				this.mRightPanel.add( okPanel );

				luckCardView.repaint();
				this.mRightPanel.repaint();
				this.mRightPanel.revalidate();

				this.mTextArea.append( "\n" + pawn.getName() + " caiu no SORTE-REVES !" );

				switch ( luckCard.getCardType() )
				{
					case REVES_DINHEIRO :
					{

						pawn.setMoney( pawn.getMoney() - ( int ) luckCard.getValue() );
						
						this.mTextArea.append( "\n"
							+ pawn.getName()
							+ " teve que pagar $"
							+ ( int ) luckCard.getValue() );

						break;
					}
					case SORTE_DINHEIRO :
					{
						pawn.setMoney( pawn.getMoney() + ( int ) luckCard.getValue() );
						this.mTextArea.append( "\n" + pawn.getName() + " ganhou $" + ( int ) luckCard.getValue() );
						break;
					}
					case REVES_PRISAO :
					{
						this.mTextArea.append( "\n" + pawn.getName() + " foi PRESO!" );
						goToPrison( pawn );
						break;

					}
					case SORTE_PRISAO :
					{
						pawn.setCardsGetOutPrison( (pawn.getCardsGetOutPrison() + 1) );
						this.mTextArea.append( "\n" + pawn.getName() + " tirou uma carta de saida da prisao." );
						break;
					}

				}

				this.mGameController.notifyObservers();
				paintLeftPanel();

				break;
			}
			case LUCROS_OU_DIVIDENDOS :
			{
				final String msg = String
					.format( "\n%s recebeu $200 por parar em LUCROS OU DIVIDENDOS", pawn.getName() );
				this.mTextArea.append( msg );

				pawn.updateMoney( 200 );

				paintRightPanelToNextPlayer = true;
				break;
			}

			case IMPOSTO_DE_RENDA :
			{
				final String msg = String.format( "\n%s pagou $200 por parar em IMPOSTO DE RENDA", pawn.getName() );
				this.mTextArea.append( msg );

				pawn.updateMoney( -200 );

				paintRightPanelToNextPlayer = true;
				break;
			}

			case VA_PARA_PRISAO :
			{
				this.mTextArea.append( "\n" + pawn.getName() + " foi PRESO!" );
				goToPrison( pawn );

				paintRightPanelToNextPlayer = true;
				break;
			}

			case PRISAO :
			{
				this.mTextArea.append( "\n" + pawn.getName() + " esta visitando a prisao." );

				paintRightPanelToNextPlayer = true;
				break;
			}

			case NADA :
			{
				this.mTextArea.append( "\n" + pawn.getName() + " esta na " + square.getName() + ". Nao faz nada. " );

				paintRightPanelToNextPlayer = true;
				break;
			}

			default :
			{
				System.out.println( "Erro - MonopolyMainFrame::pawnOnBoardSquare - Tipo nao identificado." );
				break;
			}
		}// switch
		
		
		while( pawn.getMoney() < 0 )
		{
			if( pawn.getPropertyLenth() == 0 )
			{
				JOptionPane.showMessageDialog(
						null,
						pawn.getName() + ", voce nao tem como pagar sua divida... esta FORA do jogo!",
						"Sem Propriedades...",
						JOptionPane.WARNING_MESSAGE );
				
				pawnEliminated(pawn);
				break;
			}
			
			pawnOweMoney(pawn);
		}

		if ( paintRightPanelToNextPlayer )
		{
			paintRightPanelToNextPlayer();
		}
	}
	
	void pawnOweMoney( Pawn pawn )
	{
		
		String message = String.format("%s, voce esta devendo $%s. Venda casas/hoteis ou propriedades para quitar a sua divida.",
									pawn.getName(),
									Math.abs( pawn.getMoney() ) );

		String[] options = { "Vender casas ou hoteis", "Vender propriedades" };
		
		final int resp = JOptionPane.showOptionDialog(
				null,
				message,
				"Jogador Devendo!",
				JOptionPane.DEFAULT_OPTION,
				JOptionPane.PLAIN_MESSAGE,
				null,
				options,
				null );
		
		if ( resp == 0 )//VENDER CASAS OU HOTEIS
		{
			final String[] terrainNames = pawn.getTerrainNamesWithHouse();

			if ( terrainNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhum terreno com casas ou hotel.",
					"Sem Casas",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				final int response = JOptionPane.showOptionDialog(
					null,
					"De qual terreno deseja vender a casa? (o jogador recebera metado do valor da construcao) ",
					"Escolha o terreno",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					terrainNames,
					null );

				if ( response == -1 )
				{
					return;
				}

				final AbstractBoardSquare square = this.mGameController.getSquareWithName( terrainNames[response] );
				final String msg = this.mGameController.sellHouse( pawn, square );
				this.mTextArea.append( "\n" + msg );
			}

		}
		if ( resp == 1 )//VENDER_PROPRIEDADE
		{
			final Pawn pawnSeller = pawn;

			final String[] propertiesNames = pawnSeller.getPropertyNames();

			if ( propertiesNames.length == 0 )
			{
				JOptionPane.showMessageDialog(
					null,
					"Voce nao possui nenhuma propriedade.",
					"Sem Propriedade",
					JOptionPane.WARNING_MESSAGE );

			}
			else
			{
				int response = JOptionPane.showOptionDialog(
					null,
					"Qual propriedade deseja vender?",
					"Escolha a propriedade",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					propertiesNames,
					null );
				
				if ( response == -1 )
				{
					return;
				}

				final AbstractBoardSquare propertyToSell = this.mGameController
					.getSquareWithName( propertiesNames[response] );

				final String[] playersName = getOthersPlayersNameWithBank( pawnSeller.getName() );

				response = JOptionPane.showOptionDialog(
					null,
					"Qual jogador ira comprar a sua propriedade? (O banco pode compra-la pelo preco da compra)",
					"Escolha um jogador",
					JOptionPane.DEFAULT_OPTION,
					JOptionPane.PLAIN_MESSAGE,
					null,
					playersName,
					null );

				String msg = "";

				if ( response == ( playersName.length - 1 ) ) // venda para o banco (eh o ultimo do
																// vetor) pelo preco da compra
				{
					msg = this.mGameController.sellPropertyToBank( pawnSeller, propertyToSell );
				}
				else
				{
					String priceStr = "";
					int price = -1;

					while ( price == -1 )
					{
						priceStr = JOptionPane.showInputDialog( null, "Entre com o valor da venda:" );

						try
						{
							price = Integer.valueOf( priceStr );
						}
						catch ( final Exception e )
						{
							price = -1;
						}
					}

					final Pawn pawnBuyer = getPlayerWithName( playersName[response] );

					msg = this.mGameController.sellProperty( pawnSeller, pawnBuyer, propertyToSell, price );
				}

				this.mTextArea.append( "\n" + msg );
			}
		}
		
		paintLeftPanel();
	}
	
	private void goToPrison( Pawn pawn )
	{
		if( pawn.getCardsGetOutPrison() > 0 )
		{
			pawn.setCardsGetOutPrison( (pawn.getCardsGetOutPrison() - 1) );
			
			String msg = String.format( "Jogador %s nao foi preso porque tirou carta de saida de prisao anteriormente.", pawn.getName() );
			this.mTextArea.append( "\n" + msg );

		}
		else
		{
			this.mGameController.goToPrison(pawn);
		}

	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @see br.rio.puc.inf.monopoly.observer.Observer#update()
	 */
	@Override
	public void update()
	{
		final List<LuckCard> luckCardList = this.mGameController.getLuckCardList();
		final LuckCard luckCard = luckCardList.get( 0 );
		luckCardList.remove( luckCard );
		luckCardList.add( luckCard );

	}

	/**
	 * <p>
	 * Field <code>mBoardController</code>
	 * </p>
	 */
	GameController mGameController = null;

	/**
	 * <p>
	 * Field <code>mBoardView</code>
	 * </p>
	 */
	BoardView mBoardView = null;

	/**
	 * <p>
	 * Field <code>mBtnPlay</code>
	 * </p>
	 */
	JButton mBtnPlay;

	/**
	 * <p>
	 * Field <code>mCurrentPawn</code>
	 * </p>
	 */
	int mCurrentPawn = -1;

	/**
	 * <p>
	 * Field <code>mCurrentPawnPlayer</code>
	 * </p>
	 */
	Pawn mCurrentPawnPlayer = null;

	/**
	 * <p>
	 * Field <code>mCurrentPawnSquare</code>
	 * </p>
	 */
	AbstractBoardSquare mCurrentPawnSquare = null;

	/**
	 * <p>
	 * Field <code>mDadosBtn</code>
	 * </p>
	 */
	JButton mDadosBtn;

	/**
	 * <p>
	 * Field <code>mLeftPanel</code>
	 * </p>
	 */
	JPanel mLeftPanel;

	/**
	 * <p>
	 * Field <code>mMainPanel</code>
	 * </p>
	 */
	JPanel mMainPanel;

	/**
	 * <p>
	 * Field <code>mPawnList</code>
	 * </p>
	 */
	List<Pawn> mPawnList;

	/**
	 * <p>
	 * Field <code>mRepeatedDices</code>
	 * </p>
	 */
	int mRepeatedDices = 0;

	/**
	 * <p>
	 * Field <code>mRightPanel</code>
	 * </p>
	 */
	JPanel mRightPanel;

	/**
	 * <p>
	 * Field <code>mTextArea</code>
	 * </p>
	 */
	JTextArea mTextArea;

	/**
	 * <p>
	 * Field <code>mTextField</code>
	 * </p>
	 */
	JTextField mTextField;

}
