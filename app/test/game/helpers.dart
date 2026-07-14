import 'dart:math';

import 'package:quarteirao/game/game.dart';

/// Jogadores padrão dos testes.
const p1 = 'p1';
const p2 = 'p2';
const p3 = 'p3';

GameEngine engine({int seed = 42}) => GameEngine(Random(seed));

PlayerState player(
  String id, {
  int money = 1500,
  int position = 0,
  int jailTurns = 0,
  int jailCards = 0,
  bool eliminated = false,
  int debtPenalty = 0,
  int doublesCount = 0,
  int turnsTaken = 0,
}) {
  return PlayerState(
    id: id,
    name: id.toUpperCase(),
    money: money,
    position: position,
    jailTurns: jailTurns,
    getOutOfJailCards: jailCards,
    eliminated: eliminated,
    debtPenalty: debtPenalty,
    doublesCount: doublesCount,
    turnsTaken: turnsTaken,
  );
}

/// Estado controlado para testes de regra (bypassa createGame).
GameState testState({
  RuleSet rules = const RuleSet.rapido(),
  List<PlayerState>? players,
  String current = p1,
  TurnPhase phase = TurnPhase.preRoll,
  Map<int, SquareState>? squareOverrides,
  List<int>? deck,
  int deckPointer = 0,
  DiceRoll? lastRoll,
  List<TradeOffer> openTrades = const [],
  AuctionState? auction,
  Map<String, int> guesses = const {},
  String? debtCreditorId,
  List<CardDef>? cards,
}) {
  final ps = players ?? [player(p1), player(p2), player(p3)];
  final theCards = cards ?? rioCards;
  final squares = List<SquareState>.generate(
    rioBoard.length,
    (i) => squareOverrides?[i] ?? const SquareState(),
  );
  return GameState(
    rules: rules,
    board: rioBoard,
    cardDefs: theCards,
    players: ps,
    squares: squares,
    currentPlayerId: current,
    phase: phase,
    deck: deck ?? theCards.map((c) => c.id).toList(),
    deckPointer: deckPointer,
    lastRoll: lastRoll,
    openTrades: openTrades,
    auction: auction,
    guesses: guesses,
    debtCreditorId: debtCreditorId,
  );
}

/// Id da primeira carta do tipo [kind] no config.
int cardIdOf(CardKind kind) => rioCards.firstWhere((c) => c.kind == kind).id;

/// Índices úteis do tabuleiro do Rio (ver board_config.dart).
class Rio {
  static const inicio = 0;
  static const rosa1 = 1; // Bangu, $60
  static const sorte1 = 2;
  static const rosa2 = 3; // Campo Grande, $60
  static const imposto = 4;
  static const companhia1 = 5; // Metrô, $200, fee 25
  static const azul1 = 6;
  static const azul2 = 8;
  static const azul3 = 9;
  static const prisao = 10;
  static const estacionamento = 20;
  static const vaParaPrisao = 30;
  static const roxo1 = 37; // Ipanema, $350
  static const lucros = 38;
  static const roxo2 = 39; // Leblon, $400, aluguel base 50
}
