package br.rio.puc.inf.monopoly.model;

import br.rio.puc.inf.monopoly.Constants.Type;

import java.util.ArrayList;
import java.util.LinkedList;
import java.util.List;

/**
 * <p>
 * </p>
 * 
 * @author ryniere
 * @version 1.0 Created on 25/10/2012
 */
public class Board
	extends AbstractGameItem
{

	/**
	 * <p>
	 * </p>
	 */
	@SuppressWarnings( {"unchecked",
						"rawtypes"} )
	public Board( final List<Pawn> pawnList )
	{
		setImagePath( "images/tabuleiro.png" );
		setBoardSquareList( new LinkedList() );
		final List list = getBoardSquareList();

		final List<AbstractBoardSquare> boardSquareVermelhaList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareVerdeList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareAzulList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareAmareloList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareVinhoList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareRoxoList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareLaranjaList = new ArrayList<AbstractBoardSquare>();
		final List<AbstractBoardSquare> boardSquareRosaList = new ArrayList<AbstractBoardSquare>();

		final AbstractBoardSquare initalBoardSquare = new AbstractBoardSquare( 695, 14, 789, 107, true, Type.NADA, 0 );
		initalBoardSquare.setName( "PARTIDA" );
		initalBoardSquare.getPawnList().addAll( pawnList );

		list.add( initalBoardSquare );

		final int rentLeblon[] = {	6,
									30,
									90,
									270,
									400,
									500};
		final AbstractBoardSquare leblonBoardSquare = new AbstractBoardSquare(
			700,
			110,
			789,
			170,
			true,
			Type.TERRENO_ROSA,
			100,
			rentLeblon,
			50,
			50,
			50,
			1 );
		leblonBoardSquare.setName( "LEBLON" );
		leblonBoardSquare.setSameColorBoardSquareList( boardSquareRosaList );
		boardSquareRosaList.add( leblonBoardSquare );
		list.add( leblonBoardSquare );

		final AbstractBoardSquare thirdBoardSquare = new AbstractBoardSquare(
			700,
			175,
			789,
			235,
			true,
			Type.SORTE_REVES,
			0 );
		thirdBoardSquare.setName( "SORTE-REVES" );
		list.add( thirdBoardSquare );

		final int rentPVargas[] = {	2,
									10,
									30,
									90,
									160,
									250};
		final AbstractBoardSquare fourthBoardSquare = new AbstractBoardSquare(
			700,
			240,
			789,
			300,
			true,
			Type.TERRENO_ROSA,
			60,
			rentPVargas,
			50,
			50,
			30,
			1 );
		fourthBoardSquare.setName( "AV. PRESIDENTE VARGAS" );
		list.add( fourthBoardSquare );
		fourthBoardSquare.setSameColorBoardSquareList( boardSquareRosaList );
		boardSquareRosaList.add( fourthBoardSquare );

		final int rentNSCopa[] = {	4,
									20,
									60,
									180,
									320,
									450};
		final AbstractBoardSquare fifthBoardSquare = new AbstractBoardSquare(
			700,
			305,
			789,
			365,
			true,
			Type.TERRENO_ROSA,
			60,
			rentNSCopa,
			50,
			50,
			30,
			1 );
		fifthBoardSquare.setName( "AV. NOSSA S. DE COPACABANA" );
		list.add( fifthBoardSquare );
		fifthBoardSquare.setSameColorBoardSquareList( boardSquareRosaList );
		boardSquareRosaList.add( fifthBoardSquare );

		final AbstractBoardSquare sixthBoardSquare = new AbstractBoardSquare(
			705,
			370,
			789,
			430,
			true,
			Type.COMPANHIA,
			200,
			50,
			100 );
		
		sixthBoardSquare.setName( "CIA FERROVIARIA" );
		list.add( sixthBoardSquare );

		final int rentAvBrigadeiro[] = {18,
										90,
										250,
										700,
										875,
										1050};
		final AbstractBoardSquare seventhBoardSquare = new AbstractBoardSquare(
			705,
			440,
			789,
			500,
			true,
			Type.TERRENO_AZUL,
			240,
			rentAvBrigadeiro,
			150,
			150,
			110,
			2 );
		
		seventhBoardSquare.setName( "AV. BRIGADEIRO" );
		list.add( seventhBoardSquare );
		seventhBoardSquare.setSameColorBoardSquareList( boardSquareAzulList );
		boardSquareAzulList.add( seventhBoardSquare );

		final AbstractBoardSquare eighthBoardSquare = new AbstractBoardSquare(
			705,
			505,
			789,
			565,
			true,
			Type.COMPANHIA,
			200,
			50,
			100 );
		
		eighthBoardSquare.setName( "CIA DE AVIACAO" );
		list.add( eighthBoardSquare );

		
		final int rentReboucas[] = {18,
				90,
				250,
				700,
				875,
				1050};
		
		final AbstractBoardSquare ninthBoardSquare = new AbstractBoardSquare(
			705,
			570,
			789,
			630,
			true,
			Type.TERRENO_AZUL,
			220,
			rentReboucas,
			150,
			150,
			110,
			2 );
		
		ninthBoardSquare.setName( "AV. REBOUCAS" );
		list.add( ninthBoardSquare );
		ninthBoardSquare.setSameColorBoardSquareList( boardSquareAzulList );
		boardSquareAzulList.add( ninthBoardSquare );

		
		final int rentNoveJulho[] = {18,
				90,
				250,
				700,
				875,
				1050};
		
		final AbstractBoardSquare tenthBoardSquare = new AbstractBoardSquare(
			705,
			640,
			789,
			700,
			true,
			Type.TERRENO_AZUL,
			220,
			rentNoveJulho,
			150,
			150,
			110,
			2 );
		
		tenthBoardSquare.setName( "AV. 9 DE JULHO" );
		list.add( tenthBoardSquare );
		tenthBoardSquare.setSameColorBoardSquareList( boardSquareAzulList );
		boardSquareAzulList.add( tenthBoardSquare );

		setPrisionBoardSquare( new PrisionBoardSquare( 712, 715, 755, 761, true, Type.PRISAO, 0 ) );
		getPrisionBoardSquare().setName( "PRISAO" );
		list.add( getPrisionBoardSquare() );
		
		
		final int rentEurope[] = {16,
				80,
				220,
				600,
				800,
				1000};

		final AbstractBoardSquare europeAvBoardSquare = new AbstractBoardSquare(
			635,
			705,
			702,
			798,
			false,
			Type.TERRENO_VINHO,
			200,
			rentEurope,
			100,
			100,
			100,
			3 );
		
		europeAvBoardSquare.setName( "AV. EUROPA" );
		list.add( europeAvBoardSquare );
		europeAvBoardSquare.setSameColorBoardSquareList( boardSquareVinhoList );
		boardSquareVinhoList.add( europeAvBoardSquare );

		final AbstractBoardSquare reverseLuckBoardSquare = new AbstractBoardSquare(
			568,
			705,
			634,
			798,
			false,
			Type.SORTE_REVES,
			0 );
		reverseLuckBoardSquare.setName( "SORTE-REVES" );
		list.add( reverseLuckBoardSquare );

		
		final int rentAugusta[] = {14,
				70,
				200,
				550,
				750,
				950};
		
		final AbstractBoardSquare augustaStreetBoardSquare = new AbstractBoardSquare(
			501,
			705,
			634,
			798,
			false,
			Type.TERRENO_VINHO,
			180 ,
			rentAugusta,
			100,
			100,
			100,
			3 );
		
		augustaStreetBoardSquare.setName( "R. AUGUSTA" );
		list.add( augustaStreetBoardSquare );
		augustaStreetBoardSquare.setSameColorBoardSquareList( boardSquareVinhoList );
		boardSquareVinhoList.add( augustaStreetBoardSquare );

		
		final int rentPacaembu[] = {14,
				70,
				200,
				550,
				750,
				950};
		
		final AbstractBoardSquare pacaembuAvBoardSquare = new AbstractBoardSquare(
			434,
			705,
			501,
			798,
			false,
			Type.TERRENO_VINHO,
			180 ,
			rentPacaembu,
			100,
			100,
			100,
			3 );
		
		pacaembuAvBoardSquare.setName( "AV. PACAEMBU" );
		list.add( pacaembuAvBoardSquare );
		pacaembuAvBoardSquare.setSameColorBoardSquareList( boardSquareVinhoList );
		boardSquareVinhoList.add( pacaembuAvBoardSquare );

		final AbstractBoardSquare taxiCompanyBoardSquare = new AbstractBoardSquare(
			367,
			705,
			434,
			798,
			false,
			Type.COMPANHIA,
			150,
			40,
			75);
		
		taxiCompanyBoardSquare.setName( "CIA DE TAXI" );
		list.add( taxiCompanyBoardSquare );

		final AbstractBoardSquare reverseLuck3BoardSquare = new AbstractBoardSquare(
			299,
			705,
			367,
			798,
			false,
			Type.SORTE_REVES,
			0 );
		reverseLuck3BoardSquare.setName( "SORTE-REVES" );
		list.add( reverseLuck3BoardSquare );
		
		
		final int rentInterlagos[] = {35,
				175,
				500,
				1100,
				1300,
				1500};

		final AbstractBoardSquare interlagosBoardSquare = new AbstractBoardSquare(
			231,
			705,
			299,
			798,
			false,
			Type.TERRENO_LARANJA,
			350 ,
			rentInterlagos,
			100,
			100,
			100,
			4 );
		
		interlagosBoardSquare.setName( "INTERLAGOS" );
		list.add( interlagosBoardSquare );
		interlagosBoardSquare.setSameColorBoardSquareList( boardSquareLaranjaList );
		boardSquareLaranjaList.add( interlagosBoardSquare );

		final AbstractBoardSquare profitOrShareBoardSquare = new AbstractBoardSquare(
			166,
			705,
			231,
			798,
			false,
			Type.LUCROS_OU_DIVIDENDOS,
			0 );
		profitOrShareBoardSquare.setName( "LUCROS OU DIVIDENDOS" );
		list.add( profitOrShareBoardSquare );
		
		
		final int rentMorumbi[] = {35,
				175,
				500,
				1100,
				1300,
				1500};

		final AbstractBoardSquare morumbiBoardSquare = new AbstractBoardSquare(
			98,
			705,
			166,
			798,
			false,
			Type.TERRENO_LARANJA,
			400,
			rentMorumbi,
			100,
			100,
			100,
			4 );
		
		morumbiBoardSquare.setName( "MORUMBI" );
		list.add( morumbiBoardSquare );
		morumbiBoardSquare.setSameColorBoardSquareList( boardSquareLaranjaList );
		boardSquareLaranjaList.add( morumbiBoardSquare );

		final AbstractBoardSquare stopBoardSquare = new AbstractBoardSquare( 1, 705, 98, 798, true, Type.NADA, 0 );
		stopBoardSquare.setName( "PARADA LIVRE" );
		list.add( stopBoardSquare );
		
		final int rentFlamengo[] = {8,
				40,
				100,
				300,
				450,
				600};

		final AbstractBoardSquare flamengoBoardSquare = new AbstractBoardSquare(
			1,
			638,
			98,
			705,
			true,
			Type.TERRENO_VERMELHO,
			120,
			rentFlamengo,
			50,
			50,
			60,
			5 );
		
		flamengoBoardSquare.setName( "FLAMENGO" );
		list.add( flamengoBoardSquare );
		flamengoBoardSquare.setSameColorBoardSquareList( boardSquareVermelhaList );
		boardSquareVermelhaList.add( flamengoBoardSquare );

		final AbstractBoardSquare reverseLuck4BoardSquare = new AbstractBoardSquare(
			1,
			571,
			98,
			638,
			true,
			Type.SORTE_REVES,
			0 );
		reverseLuck4BoardSquare.setName( "SORTE-REVES" );
		list.add( reverseLuck4BoardSquare );
		
		
		final int rentBotafogo[] = {6,
				30,
				90,
				270,
				400,
				500};

		final AbstractBoardSquare botafogoStreetBoardSquare = new AbstractBoardSquare(
			1,
			502,
			98,
			572,
			true,
			Type.TERRENO_VERMELHO,
			100,
			rentBotafogo,
			50,
			50,
			50,
			5 );
		
		botafogoStreetBoardSquare.setName( "BOTAFOGO" );
		list.add( botafogoStreetBoardSquare );
		botafogoStreetBoardSquare.setSameColorBoardSquareList( boardSquareVermelhaList );
		boardSquareVermelhaList.add( botafogoStreetBoardSquare );

		final AbstractBoardSquare taxBoardSquare = new AbstractBoardSquare(
			1,
			438,
			98,
			504,
			true,
			Type.IMPOSTO_DE_RENDA,
			100 );
		taxBoardSquare.setName( "IMPOSTO DE RENDA" );
		list.add( taxBoardSquare );

		final AbstractBoardSquare navigationCompanyBoardSquare = new AbstractBoardSquare(
			1,
			371,
			98,
			437,
			true,
			Type.COMPANHIA,
			150,
			40,
			75 );
		
		navigationCompanyBoardSquare.setName( "CIA DE NAVEGACAO" );
		list.add( navigationCompanyBoardSquare );
		
		
		final int rentAvBrasil[] = {12,
				60,
				180,
				500,
				700,
				900};

		final AbstractBoardSquare brasilAvBoardSquare = new AbstractBoardSquare(
			1,
			303,
			98,
			368,
			true,
			Type.TERRENO_AMARELO,
			160,
			rentAvBrasil,
			100,
			100,
			80,
			5 );
		
		brasilAvBoardSquare.setName( "AV. BRASIL" );
		list.add( brasilAvBoardSquare );
		brasilAvBoardSquare.setSameColorBoardSquareList( boardSquareAmareloList );
		boardSquareAmareloList.add( brasilAvBoardSquare );

		final AbstractBoardSquare reverseLuck5BoardSquare = new AbstractBoardSquare(
			1,
			237,
			98,
			301,
			true,
			Type.SORTE_REVES,
			0 );
		reverseLuck5BoardSquare.setName( "SORTE-REVES" );
		list.add( reverseLuck5BoardSquare );
		
		
		final int rentAvPaulista[] = {10,
				50,
				150,
				450,
				625,
				750};

		final AbstractBoardSquare paulistaAvBoardSquare = new AbstractBoardSquare(
			1,
			171,
			98,
			237,
			true,
			Type.TERRENO_AMARELO,
			140,
			rentAvPaulista,
			100,
			100,
			70,
			5 );
		
		paulistaAvBoardSquare.setName( "AV. PAULISTA" );
		list.add( paulistaAvBoardSquare );
		paulistaAvBoardSquare.setSameColorBoardSquareList( boardSquareAmareloList );
		boardSquareAmareloList.add( paulistaAvBoardSquare );

		
		final int rentJardEuropa[] = {10,
				50,
				150,
				450,
				625,
				750};
		
		final AbstractBoardSquare jardimEuropaBoardSquare = new AbstractBoardSquare(
			1,
			106,
			98,
			171,
			true,
			Type.TERRENO_AMARELO,
			140,
			rentJardEuropa,
			100,
			100,
			70,
			5 );
		
		jardimEuropaBoardSquare.setName( "JARDIM EUROPA" );
		list.add( jardimEuropaBoardSquare );
		jardimEuropaBoardSquare.setSameColorBoardSquareList( boardSquareAmareloList );
		boardSquareAmareloList.add( jardimEuropaBoardSquare );

		final AbstractBoardSquare goToPrisionBoardSquare = new AbstractBoardSquare(
			1,
			13,
			98,
			104,
			true,
			Type.VA_PARA_PRISAO,
			0 );
		goToPrisionBoardSquare.setName( "VÃ� PARA A PRISÃƒO" );
		list.add( goToPrisionBoardSquare );
		
		final int rentCopa[] = {22,
				110,
				330,
				800,
				975,
				1150};

		final AbstractBoardSquare copacabanaBoardSquare = new AbstractBoardSquare(
			106,
			13,
			169,
			104,
			false,
			Type.TERRENO_VERDE,
			240,
			rentCopa,
			150,
			150,
			130,
			6 );
		
		copacabanaBoardSquare.setName( "COPACABANA" );
		list.add( copacabanaBoardSquare );
		copacabanaBoardSquare.setSameColorBoardSquareList( boardSquareVerdeList );
		boardSquareVerdeList.add( copacabanaBoardSquare );

		final AbstractBoardSquare airCompanyBoardSquare = new AbstractBoardSquare(
			171,
			13,
			236,
			104,
			false,
			Type.COMPANHIA,
			200,
			50,
			100 );
		
		airCompanyBoardSquare.setName( "CIA DE AVIACAO" );
		list.add( airCompanyBoardSquare );
		
		
		final int rentVieiraSouto[] = {28,
				150,
				450,
				1000,
				1200,
				1400};

		final AbstractBoardSquare vieiraSoutoAvBoardSquare = new AbstractBoardSquare(
			237,
			13,
			301,
			104,
			false,
			Type.TERRENO_VERDE,
			320,
			rentVieiraSouto,
			200,
			200,
			160,
			6 );
		
		vieiraSoutoAvBoardSquare.setName( "AV. VIEIRA SOUTO" );
		list.add( vieiraSoutoAvBoardSquare );
		vieiraSoutoAvBoardSquare.setSameColorBoardSquareList( boardSquareVerdeList );
		boardSquareVerdeList.add( vieiraSoutoAvBoardSquare );

		
		final int rentAtlantica[] = {26,
				130,
				390,
				900,
				1100,
				1275};
		
		final AbstractBoardSquare atlanticaAvBoardSquare = new AbstractBoardSquare(
			303,
			13,
			366,
			104,
			false,
			Type.TERRENO_VERDE,
			300,
			rentAtlantica,
			200,
			200,
			150,
			6 );
		
		atlanticaAvBoardSquare.setName( "AV. ATLANTICA" );
		list.add( atlanticaAvBoardSquare );
		atlanticaAvBoardSquare.setSameColorBoardSquareList( boardSquareVerdeList );
		boardSquareVerdeList.add( atlanticaAvBoardSquare );

		final AbstractBoardSquare airTaxiCompanyBoardSquare = new AbstractBoardSquare(
			367,
			13,
			435,
			104,
			false,
			Type.COMPANHIA,
			200,
			50,
			100 );
		
		airTaxiCompanyBoardSquare.setName( "CIA TAXI AEREO" );
		list.add( airTaxiCompanyBoardSquare );

		final int rentIpanema[] = {26,
				130,
				390,
				900,
				1100,
				1275};
		
		final AbstractBoardSquare ipanemaBoardSquare = new AbstractBoardSquare(
			434,
			13,
			500,
			104,
			false,
			Type.TERRENO_VERDE,
			300,
			rentIpanema,
			200,
			200,
			150,
			6 );
		
		ipanemaBoardSquare.setName( "IPANEMA" );
		list.add( ipanemaBoardSquare );
		ipanemaBoardSquare.setSameColorBoardSquareList( boardSquareVerdeList );
		boardSquareVerdeList.add( ipanemaBoardSquare );

		final AbstractBoardSquare reverseLuck6BoardSquare = new AbstractBoardSquare(
			500,
			13,
			565,
			104,
			false,
			Type.SORTE_REVES,
			0 );
		reverseLuck6BoardSquare.setName( "SORTE-REVES" );
		list.add( reverseLuck6BoardSquare );
		
		
		final int rentJardPaulista[] = {24,
				120,
				360,
				850,
				1025,
				1200};

		final AbstractBoardSquare jardimPaulistaBoardSquare = new AbstractBoardSquare(
			564,
			13,
			630,
			104,
			false,
			Type.TERRENO_ROXO,
			290,
			rentJardPaulista,
			150,
			150,
			140,
			7 );
		
		jardimPaulistaBoardSquare.setName( "JARDIM PAULISTA" );
		list.add( jardimPaulistaBoardSquare );
		jardimPaulistaBoardSquare.setSameColorBoardSquareList( boardSquareRoxoList );
		boardSquareRoxoList.add( jardimPaulistaBoardSquare );

		
		final int rentBrooklin[] = {22,
				120,
				330,
				800,
				975,
				1150};
		
		final AbstractBoardSquare brooklinBoardSquare = new AbstractBoardSquare(
			627,
			13,
			697,
			104,
			false,
			Type.TERRENO_ROXO,
			280,
			rentBrooklin,
			150,
			150,
			130,
			7 );
		
		brooklinBoardSquare.setName( "BROOKLIN" );
		list.add( brooklinBoardSquare );
		brooklinBoardSquare.setSameColorBoardSquareList( boardSquareRoxoList );
		boardSquareRoxoList.add( brooklinBoardSquare );

	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @return
	 */
	public List<AbstractBoardSquare> getBoardSquareList()
	{
		return this.boardSquareList;
	}

	public PrisionBoardSquare getPrisionBoardSquare()
	{
		return this.prisionBoardSquare;
	}

	/**
	 * <p>
	 * </p>
	 * 
	 * @param boardSquareList
	 */
	public void setBoardSquareList( final List<AbstractBoardSquare> boardSquareList )
	{
		this.boardSquareList = boardSquareList;
	}

	public void setPrisionBoardSquare( final PrisionBoardSquare prisionBoardSquare )
	{
		this.prisionBoardSquare = prisionBoardSquare;
	}

	/**
	 * <p>
	 * Field <code>boardSquareList</code>
	 * </p>
	 */
	private List<AbstractBoardSquare> boardSquareList;

	/**
	 * <p>
	 * Field <code>prisionBoardSquare</code>
	 * </p>
	 */
	private PrisionBoardSquare prisionBoardSquare;

}
