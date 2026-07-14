import 'actions.dart';
import 'cards.dart';
import 'player_state.dart';
import 'rules.dart';
import 'square.dart';

enum TurnPhase { preRoll, buying, auction, debt, turnEnd, finished }

/// Estado dinâmico de uma casa do tabuleiro.
class SquareState {
  final String? ownerId;
  final int houses; // 0–5 (5 = hotel)
  final bool mortgaged;

  const SquareState({this.ownerId, this.houses = 0, this.mortgaged = false});

  SquareState copyWith({
    Object? ownerId = _sentinel,
    int? houses,
    bool? mortgaged,
  }) {
    return SquareState(
      ownerId: identical(ownerId, _sentinel) ? this.ownerId : ownerId as String?,
      houses: houses ?? this.houses,
      mortgaged: mortgaged ?? this.mortgaged,
    );
  }

  static const _sentinel = Object();
}

/// Leilão em andamento (recusa de compra ou fila de falência — plano §2.2).
class AuctionState {
  final int squareIndex;
  final String? highestBidderId;
  final int highestBid;
  final Set<String> passedIds;
  final List<String> participantIds;

  /// Fila de leilões pendentes (falência liquida várias propriedades).
  final List<int> queue;

  /// Falência: credor recebe o produto do leilão até [debtRemaining].
  final String? creditorId;
  final int debtRemaining;

  /// Leilão de falência: o turno já avançou ao falir; ao terminar a fila,
  /// a fase volta a preRoll do jogador atual.
  final bool resumePreRollWhenDone;

  const AuctionState({
    required this.squareIndex,
    this.highestBidderId,
    this.highestBid = 0,
    this.passedIds = const {},
    required this.participantIds,
    this.queue = const [],
    this.creditorId,
    this.debtRemaining = 0,
    this.resumePreRollWhenDone = false,
  });

  AuctionState copyWith({
    int? squareIndex,
    Object? highestBidderId = _sentinel,
    int? highestBid,
    Set<String>? passedIds,
    List<String>? participantIds,
    List<int>? queue,
    Object? creditorId = _sentinel,
    int? debtRemaining,
    bool? resumePreRollWhenDone,
  }) {
    return AuctionState(
      squareIndex: squareIndex ?? this.squareIndex,
      highestBidderId: identical(highestBidderId, _sentinel)
          ? this.highestBidderId
          : highestBidderId as String?,
      highestBid: highestBid ?? this.highestBid,
      passedIds: passedIds ?? this.passedIds,
      participantIds: participantIds ?? this.participantIds,
      queue: queue ?? this.queue,
      creditorId: identical(creditorId, _sentinel)
          ? this.creditorId
          : creditorId as String?,
      debtRemaining: debtRemaining ?? this.debtRemaining,
      resumePreRollWhenDone: resumePreRollWhenDone ?? this.resumePreRollWhenDone,
    );
  }

  static const _sentinel = Object();
}

class GameState {
  final RuleSet rules;
  final List<SquareDef> board;
  final List<CardDef> cardDefs;
  final List<PlayerState> players;
  final List<SquareState> squares;
  final String currentPlayerId;
  final TurnPhase phase;

  /// Baralho: ids de carta na ordem embaralhada + ponteiro de compra.
  final List<int> deck;
  final int deckPointer;

  final DiceRoll? lastRoll;
  final int? lastCardId;

  final List<TradeOffer> openTrades;
  final AuctionState? auction;

  /// Palpites do dado para o próximo lançamento: playerId -> palpite (2–12).
  final Map<String, int> guesses;

  /// Credor da dívida corrente (fase debt); null = banco.
  final String? debtCreditorId;

  final String? winnerId;

  /// Contador de ações aplicadas (seq do game_actions).
  final int seq;

  const GameState({
    required this.rules,
    required this.board,
    required this.cardDefs,
    required this.players,
    required this.squares,
    required this.currentPlayerId,
    required this.phase,
    required this.deck,
    this.deckPointer = 0,
    this.lastRoll,
    this.lastCardId,
    this.openTrades = const [],
    this.auction,
    this.guesses = const {},
    this.debtCreditorId,
    this.winnerId,
    this.seq = 0,
  });

  PlayerState playerById(String id) => players.firstWhere((p) => p.id == id);

  PlayerState get currentPlayer => playerById(currentPlayerId);

  List<PlayerState> get activePlayers =>
      players.where((p) => !p.eliminated).toList();

  GameState copyWith({
    List<PlayerState>? players,
    List<SquareState>? squares,
    String? currentPlayerId,
    TurnPhase? phase,
    List<int>? deck,
    int? deckPointer,
    Object? lastRoll = _sentinel,
    Object? lastCardId = _sentinel,
    List<TradeOffer>? openTrades,
    Object? auction = _sentinel,
    Map<String, int>? guesses,
    Object? debtCreditorId = _sentinel,
    Object? winnerId = _sentinel,
    int? seq,
  }) {
    return GameState(
      rules: rules,
      board: board,
      cardDefs: cardDefs,
      players: players ?? this.players,
      squares: squares ?? this.squares,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      phase: phase ?? this.phase,
      deck: deck ?? this.deck,
      deckPointer: deckPointer ?? this.deckPointer,
      lastRoll:
          identical(lastRoll, _sentinel) ? this.lastRoll : lastRoll as DiceRoll?,
      lastCardId: identical(lastCardId, _sentinel)
          ? this.lastCardId
          : lastCardId as int?,
      openTrades: openTrades ?? this.openTrades,
      auction:
          identical(auction, _sentinel) ? this.auction : auction as AuctionState?,
      guesses: guesses ?? this.guesses,
      debtCreditorId: identical(debtCreditorId, _sentinel)
          ? this.debtCreditorId
          : debtCreditorId as String?,
      winnerId:
          identical(winnerId, _sentinel) ? this.winnerId : winnerId as String?,
      seq: seq ?? this.seq,
    );
  }

  static const _sentinel = Object();
}
