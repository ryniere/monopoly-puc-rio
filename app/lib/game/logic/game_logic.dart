/// Engine puro do jogo: `apply(state, action)` sem efeitos colaterais.
/// Toda regra vive aqui (plano §5.1); UI e transporte só orquestram.
library;

import 'dart:math';

import '../config/board_config.dart';
import '../config/card_config.dart';
import '../model/actions.dart';
import '../model/cards.dart';
import '../model/events.dart';
import '../model/game_state.dart';
import '../model/player_state.dart';
import '../model/rules.dart';
import '../model/square.dart';

class GameRuleException implements Exception {
  final String message;
  GameRuleException(this.message);
  @override
  String toString() => 'GameRuleException: $message';
}

class ApplyResult {
  final GameState state;
  final List<GameEvent> events;
  const ApplyResult(this.state, this.events);
}

class PlayerSetup {
  final String id;
  final String name;
  final bool isAI;
  const PlayerSetup({required this.id, required this.name, this.isAI = false});
}

/// Cria uma partida: ordem de turno sorteada, baralho embaralhado e, no
/// modo Rápido, propriedades sorteadas por jogador (plano §2.1/§2.3).
GameState createGame({
  required RuleSet rules,
  required List<PlayerSetup> players,
  required Random rng,
  List<SquareDef>? board,
  List<CardDef>? cards,
}) {
  final theBoard = board ?? rioBoard;
  final theCards = cards ?? rioCards;
  if (players.length < 2) {
    throw GameRuleException('mínimo de 2 jogadores');
  }

  final order = List<PlayerSetup>.of(players)..shuffle(rng);
  final playerStates = [
    for (final p in order)
      PlayerState(
        id: p.id,
        name: p.name,
        isAI: p.isAI,
        money: rules.initialMoney,
      ),
  ];

  final deck = theCards.map((c) => c.id).toList()..shuffle(rng);

  final squares =
      List<SquareState>.generate(theBoard.length, (_) => const SquareState());
  if (rules.startingProperties > 0) {
    final propIndexes = [
      for (final s in theBoard)
        if (s.type == SquareType.propriedade) s.index,
    ]..shuffle(rng);
    var k = 0;
    for (final p in playerStates) {
      for (var n = 0; n < rules.startingProperties; n++) {
        squares[propIndexes[k++]] = SquareState(ownerId: p.id);
      }
    }
  }

  return GameState(
    rules: rules,
    board: theBoard,
    cardDefs: theCards,
    players: playerStates,
    squares: squares,
    currentPlayerId: playerStates.first.id,
    phase: TurnPhase.preRoll,
    deck: deck,
  );
}

/// Patrimônio líquido: dinheiro + preço das propriedades (penhoradas valem
/// 50%) + casas × housePrice − penalidades de falência (plano §2.1).
int netWorth(GameState state, String playerId) {
  final p = state.playerById(playerId);
  var worth = p.money - p.debtPenalty;
  for (var i = 0; i < state.squares.length; i++) {
    final st = state.squares[i];
    if (st.ownerId != playerId) continue;
    final def = state.board[i];
    worth += st.mortgaged ? def.price ~/ 2 : def.price;
    worth += st.houses * def.housePrice;
  }
  return worth;
}

class GameEngine {
  final Random rng;
  GameEngine(this.rng);

  ApplyResult apply(GameState state, GameAction action) {
    if (state.phase == TurnPhase.finished) {
      throw GameRuleException('a partida já terminou');
    }
    final events = <GameEvent>[];
    var s = switch (action) {
      RollDice a => _rollDice(state, a, events),
      BuyProperty a => _buy(state, a, events),
      DeclineBuy a => _declineBuy(state, a, events),
      PlaceBid a => _placeBid(state, a, events),
      PassAuction a => _passAuction(state, a, events),
      BuildHouse a => _buildHouse(state, a, events),
      SellHouse a => _sellHouse(state, a, events),
      MortgageProperty a => _mortgage(state, a, events),
      UnmortgageProperty a => _unmortgage(state, a, events),
      ProposeTrade a => _proposeTrade(state, a, events),
      RespondTrade a => _respondTrade(state, a, events),
      PayJail a => _payJail(state, a, events),
      UseJailCard a => _useJailCard(state, a, events),
      EndTurn a => _endTurn(state, a, events),
      DeclareBankruptcy a => _declareBankruptcy(state, a, events),
      GuessDice a => _guessDice(state, a, events),
    };
    return ApplyResult(s.copyWith(seq: s.seq + 1), events);
  }

  // ── Helpers de validação ─────────────────────────────────────────────

  void _requireCurrent(GameState s, String actorId) {
    if (s.currentPlayerId != actorId) {
      throw GameRuleException('não é a vez de $actorId');
    }
  }

  void _requirePhase(GameState s, List<TurnPhase> phases, String what) {
    if (!phases.contains(s.phase)) {
      throw GameRuleException('$what não é permitido na fase ${s.phase.name}');
    }
  }

  GameState _updatePlayer(
      GameState s, String id, PlayerState Function(PlayerState) fn) {
    return s.copyWith(players: [
      for (final p in s.players)
        if (p.id == id) fn(p) else p,
    ]);
  }

  GameState _updateSquare(
      GameState s, int index, SquareState Function(SquareState) fn) {
    final squares = List<SquareState>.of(s.squares);
    squares[index] = fn(squares[index]);
    return s.copyWith(squares: squares);
  }

  List<int> _groupIndexes(GameState s, ColorGroup group) => [
        for (final def in s.board)
          if (def.colorGroup == group) def.index,
      ];

  bool _ownsFullGroup(GameState s, String playerId, ColorGroup group) =>
      _groupIndexes(s, group)
          .every((i) => s.squares[i].ownerId == playerId);

  String _nextAliveAfter(GameState s, String id) {
    final idx = s.players.indexWhere((p) => p.id == id);
    for (var step = 1; step <= s.players.length; step++) {
      final candidate = s.players[(idx + step) % s.players.length];
      if (!candidate.eliminated) return candidate.id;
    }
    throw GameRuleException('nenhum jogador vivo');
  }

  /// Entra na fase de dívida se o jogador da vez terminou negativo.
  GameState _settleDebt(GameState s, List<GameEvent> events) {
    if (s.phase != TurnPhase.turnEnd) return s;
    final me = s.currentPlayer;
    if (me.money >= 0) return s;
    events.add(DebtEntered(me.id, s.debtCreditorId, -me.money));
    return s.copyWith(phase: TurnPhase.debt);
  }

  /// Sai da fase de dívida quando o jogador volta ao azul.
  GameState _maybeExitDebt(GameState s) {
    if (s.phase == TurnPhase.debt && s.currentPlayer.money >= 0) {
      return s.copyWith(phase: TurnPhase.turnEnd, debtCreditorId: null);
    }
    return s;
  }

  // ── Dados, movimento e resolução de casa ─────────────────────────────

  GameState _rollDice(GameState s, RollDice a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll], 'rolar os dados');

    final roll =
        a.roll ?? DiceRoll(1 + rng.nextInt(6), 1 + rng.nextInt(6));
    events.add(DiceRolled(a.actorId, roll));
    s = s.copyWith(lastRoll: roll);

    // Palpites do dado (plano §2.5).
    if (s.guesses.isNotEmpty) {
      final correct = [
        for (final e in s.guesses.entries)
          if (e.value == roll.sum) e.key,
      ];
      events.add(GuessResolved(correct, roll.sum));
      s = s.copyWith(guesses: const {});
    }

    final me = s.currentPlayer;
    if (me.inJail) return _rollInJail(s, roll, events);

    if (roll.isDouble && me.doublesCount >= 2) {
      // Terceira dupla seguida: prisão, sem mover (plano §2.3).
      return _sendToPrison(s, me.id, events);
    }
    if (roll.isDouble) {
      s = _updatePlayer(
          s, me.id, (p) => p.copyWith(doublesCount: p.doublesCount + 1));
    }
    s = _move(s, me.id, roll.sum, events);
    s = _resolveSquare(s, me.id, roll, events);
    return _settleDebt(s, events);
  }

  GameState _rollInJail(GameState s, DiceRoll roll, List<GameEvent> events) {
    final me = s.currentPlayer;
    if (roll.isDouble) {
      // Dupla liberta e move, sem lançamento extra (plano §2.3).
      s = _updatePlayer(s, me.id, (p) => p.copyWith(jailTurns: 0));
      events.add(LeftPrison(me.id));
      s = _move(s, me.id, roll.sum, events);
      s = _resolveSquare(s, me.id, roll, events);
      return _settleDebt(s, events);
    }
    final remaining = me.jailTurns - 1;
    if (remaining > 0) {
      s = _updatePlayer(s, me.id, (p) => p.copyWith(jailTurns: remaining));
      return s.copyWith(phase: TurnPhase.turnEnd);
    }
    // Última tentativa: paga a fiança à força e move.
    s = _updatePlayer(
        s,
        me.id,
        (p) => p.copyWith(
            jailTurns: 0, money: p.money - s.rules.prisonFee));
    events.add(LeftPrison(me.id));
    s = _move(s, me.id, roll.sum, events);
    s = _resolveSquare(s, me.id, roll, events);
    return _settleDebt(s, events);
  }

  GameState _sendToPrison(
      GameState s, String playerId, List<GameEvent> events) {
    final prisonIndex =
        s.board.firstWhere((d) => d.type == SquareType.prisao).index;
    s = _updatePlayer(
        s,
        playerId,
        (p) => p.copyWith(
            position: prisonIndex, jailTurns: 3, doublesCount: 0));
    events.add(WentToPrison(playerId));
    return s.copyWith(phase: TurnPhase.turnEnd);
  }

  GameState _move(
      GameState s, String playerId, int steps, List<GameEvent> events) {
    final me = s.playerById(playerId);
    final from = me.position;
    final raw = from + steps;
    final to = raw % s.board.length;
    var money = me.money;
    if (raw >= s.board.length) {
      money += s.rules.salary;
      events.add(SalaryPaid(playerId, s.rules.salary));
    }
    events.add(Moved(playerId, from, to));
    return _updatePlayer(
        s, playerId, (p) => p.copyWith(position: to, money: money));
  }

  GameState _resolveSquare(
      GameState s, String playerId, DiceRoll roll, List<GameEvent> events) {
    final me = s.playerById(playerId);
    final def = s.board[me.position];

    switch (def.type) {
      case SquareType.inicio:
      case SquareType.prisao:
      case SquareType.estacionamento:
        return s.copyWith(phase: TurnPhase.turnEnd);

      case SquareType.vaParaPrisao:
        return _sendToPrison(s, playerId, events);

      case SquareType.impostoDeRenda:
        final tax = (netWorth(s, playerId) ~/ 10).clamp(100, 400);
        s = _updatePlayer(s, playerId, (p) => p.copyWith(money: p.money - tax));
        events.add(TaxPaid(playerId, tax));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case SquareType.lucrosDividendos:
        s = _updatePlayer(s, playerId, (p) => p.copyWith(money: p.money + 200));
        events.add(DividendsReceived(playerId, 200));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case SquareType.sorteAzar:
        return _drawCard(s, playerId, events);

      case SquareType.propriedade:
      case SquareType.companhia:
        final st = s.squares[me.position];
        if (st.ownerId == null) {
          return s.copyWith(phase: TurnPhase.buying);
        }
        if (st.ownerId == playerId ||
            st.mortgaged ||
            s.playerById(st.ownerId!).eliminated) {
          return s.copyWith(phase: TurnPhase.turnEnd);
        }
        final rent = _rentFor(s, me.position, roll);
        final ownerId = st.ownerId!;
        s = _updatePlayer(
            s, playerId, (p) => p.copyWith(money: p.money - rent));
        s = _updatePlayer(s, ownerId, (p) => p.copyWith(money: p.money + rent));
        events.add(RentPaid(playerId, ownerId, rent, me.position));
        s = s.copyWith(phase: TurnPhase.turnEnd);
        if (s.playerById(playerId).money < 0) {
          s = s.copyWith(debtCreditorId: ownerId);
        }
        return s;
    }
  }

  int _rentFor(GameState s, int squareIndex, DiceRoll roll) {
    final def = s.board[squareIndex];
    final st = s.squares[squareIndex];
    if (def.type == SquareType.companhia) {
      return def.companyFee * roll.sum;
    }
    if (st.houses > 0) return def.rentTable[st.houses];
    final base = def.rentTable[0];
    final full = _ownsFullGroup(s, st.ownerId!, def.colorGroup!);
    return full ? base * 2 : base;
  }

  // ── Cartas ────────────────────────────────────────────────────────────

  GameState _drawCard(GameState s, String playerId, List<GameEvent> events) {
    final cardId = s.deck[s.deckPointer];
    final card = s.cardDefs.firstWhere((c) => c.id == cardId);
    events.add(CardDrawn(playerId, cardId));
    s = s.copyWith(lastCardId: cardId);

    if (card.kind == CardKind.freeJail) {
      // Sai do baralho enquanto estiver com o jogador; o ponteiro fica no
      // lugar porque a remoção puxa a próxima carta para a posição atual.
      final deck = List<int>.of(s.deck)..remove(cardId);
      var pointer = s.deckPointer;
      if (pointer >= deck.length && deck.isNotEmpty) pointer = 0;
      s = s.copyWith(deck: deck, deckPointer: pointer);
      s = _updatePlayer(s, playerId,
          (p) => p.copyWith(getOutOfJailCards: p.getOutOfJailCards + 1));
      return s.copyWith(phase: TurnPhase.turnEnd);
    }

    var pointer = s.deckPointer + 1;
    var deck = s.deck;
    if (pointer >= deck.length) {
      deck = List<int>.of(deck)..shuffle(rng);
      pointer = 0;
    }
    s = s.copyWith(deck: deck, deckPointer: pointer);

    switch (card.kind) {
      case CardKind.receive:
        s = _updatePlayer(
            s, playerId, (p) => p.copyWith(money: p.money + card.amount));
        events.add(CardMoneyApplied(playerId, card.amount));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case CardKind.pay:
        s = _updatePlayer(
            s, playerId, (p) => p.copyWith(money: p.money - card.amount));
        events.add(CardMoneyApplied(playerId, -card.amount));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case CardKind.goToPrison:
        return _sendToPrison(s, playerId, events);

      case CardKind.receivePerHouse:
        var houses = 0;
        for (var i = 0; i < s.squares.length; i++) {
          if (s.squares[i].ownerId == playerId) houses += s.squares[i].houses;
        }
        final gain = card.amount * houses;
        s = _updatePlayer(
            s, playerId, (p) => p.copyWith(money: p.money + gain));
        events.add(CardMoneyApplied(playerId, gain));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case CardKind.collectFromEach:
        var total = 0;
        for (final other in s.players) {
          if (other.id == playerId || other.eliminated) continue;
          final pays = card.amount.clamp(0, other.money < 0 ? 0 : other.money);
          total += pays;
          s = _updatePlayer(
              s, other.id, (p) => p.copyWith(money: p.money - pays));
        }
        s = _updatePlayer(
            s, playerId, (p) => p.copyWith(money: p.money + total));
        events.add(CardMoneyApplied(playerId, total));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case CardKind.advanceToStart:
        s = _updatePlayer(s, playerId,
            (p) => p.copyWith(position: 0, money: p.money + s.rules.salary));
        events.add(SalaryPaid(playerId, s.rules.salary));
        return s.copyWith(phase: TurnPhase.turnEnd);

      case CardKind.freeJail:
        throw StateError('tratada acima');
    }
  }

  // ── Compra e leilão ───────────────────────────────────────────────────

  GameState _buy(GameState s, BuyProperty a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.buying], 'comprar');
    final me = s.currentPlayer;
    final def = s.board[me.position];
    if (me.money < def.price) {
      throw GameRuleException('dinheiro insuficiente para comprar');
    }
    s = _updatePlayer(
        s, me.id, (p) => p.copyWith(money: p.money - def.price));
    s = _updateSquare(s, me.position, (sq) => sq.copyWith(ownerId: me.id));
    events.add(PropertyBought(me.id, me.position, def.price));
    return s.copyWith(phase: TurnPhase.turnEnd);
  }

  GameState _declineBuy(GameState s, DeclineBuy a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.buying], 'recusar compra');
    final auction = AuctionState(
      squareIndex: s.currentPlayer.position,
      participantIds: [for (final p in s.activePlayers) p.id],
    );
    events.add(AuctionStarted(auction.squareIndex));
    return s.copyWith(phase: TurnPhase.auction, auction: auction);
  }

  GameState _placeBid(GameState s, PlaceBid a, List<GameEvent> events) {
    _requirePhase(s, [TurnPhase.auction], 'dar lance');
    final auction = s.auction!;
    if (!auction.participantIds.contains(a.actorId)) {
      throw GameRuleException('não participa deste leilão');
    }
    if (auction.passedIds.contains(a.actorId)) {
      throw GameRuleException('já passou neste leilão');
    }
    final minBid = auction.highestBid == 0 ? 10 : auction.highestBid + 1;
    if (a.amount < minBid) {
      throw GameRuleException('lance mínimo é $minBid');
    }
    if (a.amount > s.playerById(a.actorId).money) {
      throw GameRuleException('lance acima do seu dinheiro');
    }
    s = s.copyWith(
      auction: auction.copyWith(
        highestBidderId: a.actorId,
        highestBid: a.amount,
      ),
    );
    events.add(BidPlaced(a.actorId, a.amount));
    return _maybeFinishAuction(s, events);
  }

  GameState _passAuction(GameState s, PassAuction a, List<GameEvent> events) {
    _requirePhase(s, [TurnPhase.auction], 'passar no leilão');
    final auction = s.auction!;
    if (!auction.participantIds.contains(a.actorId)) {
      throw GameRuleException('não participa deste leilão');
    }
    if (auction.passedIds.contains(a.actorId)) {
      throw GameRuleException('já passou neste leilão');
    }
    if (auction.highestBidderId == a.actorId) {
      throw GameRuleException('o maior lance não pode passar');
    }
    s = s.copyWith(
      auction: auction.copyWith(passedIds: {...auction.passedIds, a.actorId}),
    );
    return _maybeFinishAuction(s, events);
  }

  GameState _maybeFinishAuction(GameState s, List<GameEvent> events) {
    final auction = s.auction!;
    final others = auction.participantIds
        .where((id) => id != auction.highestBidderId)
        .toSet();
    final everyoneElsePassed = auction.passedIds.containsAll(others);
    if (!everyoneElsePassed) return s;

    var debtRemaining = auction.debtRemaining;
    if (auction.highestBidderId != null) {
      final winnerId = auction.highestBidderId!;
      final bid = auction.highestBid;
      s = _updatePlayer(s, winnerId, (p) => p.copyWith(money: p.money - bid));
      // Falência: credor recebe o produto até o valor da dívida (plano §2.3).
      if (auction.creditorId != null && debtRemaining > 0) {
        final toCreditor = bid < debtRemaining ? bid : debtRemaining;
        s = _updatePlayer(s, auction.creditorId!,
            (p) => p.copyWith(money: p.money + toCreditor));
        debtRemaining -= toCreditor;
      }
      s = _updateSquare(
          s,
          auction.squareIndex,
          (sq) => sq.copyWith(ownerId: winnerId, mortgaged: false));
      events.add(AuctionEnded(auction.squareIndex, winnerId, bid));
    } else {
      events.add(AuctionEnded(auction.squareIndex, null, 0));
    }

    if (auction.queue.isNotEmpty) {
      final next = auction.copyWith(
        squareIndex: auction.queue.first,
        queue: auction.queue.sublist(1),
        highestBidderId: null,
        highestBid: 0,
        passedIds: const {},
        debtRemaining: debtRemaining,
      );
      events.add(AuctionStarted(next.squareIndex));
      return s.copyWith(auction: next);
    }

    s = s.copyWith(auction: null, phase: TurnPhase.turnEnd);
    if (auction.resumePreRollWhenDone) {
      // Leilão de falência: o turno já avançou; o jogador atual joga agora.
      // Se a falência aconteceu na última vez da última rodada, o fim de
      // partida foi adiado até aqui (placar já reflete a liquidação).
      s = s.copyWith(phase: TurnPhase.preRoll);
      final rules = s.rules;
      if (rules.maxRounds > 0 &&
          s.activePlayers.every((p) => p.turnsTaken >= rules.maxRounds)) {
        return _finish(s, events);
      }
      return s;
    }
    return _settleDebt(s, events);
  }

  // ── Construção e penhora ─────────────────────────────────────────────

  GameState _buildHouse(GameState s, BuildHouse a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll, TurnPhase.turnEnd], 'construir');
    final def = s.board[a.squareIndex];
    final st = s.squares[a.squareIndex];
    if (def.type != SquareType.propriedade) {
      throw GameRuleException('só se constrói em propriedades');
    }
    if (st.ownerId != a.actorId) {
      throw GameRuleException('a propriedade não é sua');
    }
    if (!_ownsFullGroup(s, a.actorId, def.colorGroup!)) {
      throw GameRuleException('é preciso ter o grupo de cor completo');
    }
    final group = _groupIndexes(s, def.colorGroup!);
    if (group.any((i) => s.squares[i].mortgaged)) {
      throw GameRuleException('não se constrói com penhora no grupo');
    }
    if (st.houses >= 5) {
      throw GameRuleException('já tem um hotel');
    }
    // Construção uniforme (como o original de 2012): constrói-se sempre na
    // propriedade menos desenvolvida do grupo.
    final minHouses =
        group.map((i) => s.squares[i].houses).reduce((a, b) => a < b ? a : b);
    if (st.houses > minHouses) {
      throw GameRuleException('construa por igual no grupo de cor');
    }
    final me = s.playerById(a.actorId);
    if (me.money < def.housePrice) {
      throw GameRuleException('dinheiro insuficiente para construir');
    }
    s = _updatePlayer(
        s, a.actorId, (p) => p.copyWith(money: p.money - def.housePrice));
    s = _updateSquare(
        s, a.squareIndex, (sq) => sq.copyWith(houses: sq.houses + 1));
    events.add(HouseBuilt(a.actorId, a.squareIndex,
        s.squares[a.squareIndex].houses));
    return s;
  }

  GameState _sellHouse(GameState s, SellHouse a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll, TurnPhase.turnEnd, TurnPhase.debt],
        'vender casa');
    final def = s.board[a.squareIndex];
    final st = s.squares[a.squareIndex];
    if (st.ownerId != a.actorId) {
      throw GameRuleException('a propriedade não é sua');
    }
    if (st.houses == 0) {
      throw GameRuleException('não há casas para vender');
    }
    // Venda uniforme: vende-se sempre da propriedade mais desenvolvida.
    final group = def.colorGroup == null
        ? [a.squareIndex]
        : _groupIndexes(s, def.colorGroup!);
    final maxHouses =
        group.map((i) => s.squares[i].houses).reduce((a, b) => a > b ? a : b);
    if (st.houses < maxHouses) {
      throw GameRuleException('venda por igual no grupo de cor');
    }
    s = _updatePlayer(s, a.actorId,
        (p) => p.copyWith(money: p.money + def.housePrice ~/ 2));
    s = _updateSquare(
        s, a.squareIndex, (sq) => sq.copyWith(houses: sq.houses - 1));
    events.add(
        HouseSold(a.actorId, a.squareIndex, s.squares[a.squareIndex].houses));
    return _maybeExitDebt(s);
  }

  GameState _mortgage(
      GameState s, MortgageProperty a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll, TurnPhase.turnEnd, TurnPhase.debt],
        'penhorar');
    final def = s.board[a.squareIndex];
    final st = s.squares[a.squareIndex];
    if (st.ownerId != a.actorId) {
      throw GameRuleException('a propriedade não é sua');
    }
    if (st.mortgaged) {
      throw GameRuleException('já está penhorada');
    }
    if (def.colorGroup != null) {
      final group = _groupIndexes(s, def.colorGroup!);
      if (group.any((i) => s.squares[i].houses > 0)) {
        throw GameRuleException('venda as casas do grupo antes de penhorar');
      }
    }
    final amount = def.price ~/ 2;
    s = _updatePlayer(
        s, a.actorId, (p) => p.copyWith(money: p.money + amount));
    s = _updateSquare(s, a.squareIndex, (sq) => sq.copyWith(mortgaged: true));
    events.add(PropertyMortgaged(a.actorId, a.squareIndex, amount));
    return _maybeExitDebt(s);
  }

  GameState _unmortgage(
      GameState s, UnmortgageProperty a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll, TurnPhase.turnEnd], 'resgatar');
    final def = s.board[a.squareIndex];
    final st = s.squares[a.squareIndex];
    if (st.ownerId != a.actorId) {
      throw GameRuleException('a propriedade não é sua');
    }
    if (!st.mortgaged) {
      throw GameRuleException('não está penhorada');
    }
    final cost = (def.price * 6) ~/ 10;
    final me = s.playerById(a.actorId);
    if (me.money < cost) {
      throw GameRuleException('dinheiro insuficiente para resgatar');
    }
    s = _updatePlayer(
        s, a.actorId, (p) => p.copyWith(money: p.money - cost));
    s = _updateSquare(s, a.squareIndex, (sq) => sq.copyWith(mortgaged: false));
    events.add(PropertyUnmortgaged(a.actorId, a.squareIndex, cost));
    return s;
  }

  // ── Trocas ────────────────────────────────────────────────────────────

  GameState _proposeTrade(
      GameState s, ProposeTrade a, List<GameEvent> events) {
    final offer = a.offer;
    if (a.actorId != offer.fromId) {
      throw GameRuleException('só o proponente propõe a própria troca');
    }
    if (offer.fromId == offer.toId) {
      throw GameRuleException('não se troca consigo mesmo');
    }
    final from = s.playerById(offer.fromId);
    final to = s.playerById(offer.toId);
    if (from.eliminated || to.eliminated) {
      throw GameRuleException('jogador eliminado não troca');
    }
    if (s.openTrades.any((t) => t.id == offer.id)) {
      throw GameRuleException('já existe troca com esse id');
    }
    if (offer.giveSquares.isEmpty &&
        offer.receiveSquares.isEmpty &&
        offer.money == 0) {
      throw GameRuleException('troca vazia');
    }
    _validateTradeSquares(s, offer);
    _validateDebtorShield(s, offer);
    events.add(TradeProposed(offer));
    return s.copyWith(openTrades: [...s.openTrades, offer]);
  }

  /// Blindagem do credor: na fase de dívida, o devedor só pode estar do lado
  /// que RECEBE valor — nunca doando propriedades ou pagando dinheiro que
  /// deveriam liquidar a dívida.
  void _validateDebtorShield(GameState s, TradeOffer offer) {
    if (s.phase != TurnPhase.debt) return;
    final debtor = s.currentPlayerId;
    if (offer.fromId == debtor &&
        (offer.giveSquares.isNotEmpty || offer.money > 0)) {
      throw GameRuleException('em dívida você só pode receber em trocas');
    }
    if (offer.toId == debtor &&
        (offer.receiveSquares.isNotEmpty || offer.money < 0)) {
      throw GameRuleException('em dívida você só pode receber em trocas');
    }
  }

  void _validateTradeSquares(GameState s, TradeOffer offer) {
    for (final i in offer.giveSquares) {
      if (s.squares[i].ownerId != offer.fromId) {
        throw GameRuleException('${s.board[i].name} não é do proponente');
      }
    }
    for (final i in offer.receiveSquares) {
      if (s.squares[i].ownerId != offer.toId) {
        throw GameRuleException('${s.board[i].name} não é do destinatário');
      }
    }
    for (final i in [...offer.giveSquares, ...offer.receiveSquares]) {
      if (s.squares[i].houses > 0) {
        throw GameRuleException(
            'venda as casas antes de trocar ${s.board[i].name}');
      }
    }
  }

  GameState _respondTrade(
      GameState s, RespondTrade a, List<GameEvent> events) {
    final offer = s.openTrades.firstWhere(
      (t) => t.id == a.tradeId,
      orElse: () => throw GameRuleException('troca não encontrada'),
    );
    final remaining =
        s.openTrades.where((t) => t.id != a.tradeId).toList();

    if (!a.accept) {
      if (a.actorId != offer.toId && a.actorId != offer.fromId) {
        throw GameRuleException('só as partes cancelam/recusam');
      }
      events.add(TradeRejected(offer.id));
      return s.copyWith(openTrades: remaining);
    }

    if (a.actorId != offer.toId) {
      throw GameRuleException('só o destinatário aceita');
    }
    if (s.playerById(offer.fromId).eliminated ||
        s.playerById(offer.toId).eliminated) {
      throw GameRuleException('jogador eliminado não troca');
    }
    _validateTradeSquares(s, offer);
    _validateDebtorShield(s, offer);
    if (offer.money > 0 &&
        s.playerById(offer.fromId).money < offer.money) {
      throw GameRuleException('proponente sem fundos para a troca');
    }
    if (offer.money < 0 && s.playerById(offer.toId).money < -offer.money) {
      throw GameRuleException('destinatário sem fundos para a troca');
    }
    // Quem lidera um leilão não pode ficar sem fundos para o próprio lance.
    final auction = s.auction;
    if (auction != null && auction.highestBidderId != null) {
      final bidder = auction.highestBidderId!;
      var delta = 0;
      if (bidder == offer.fromId) delta = -offer.money;
      if (bidder == offer.toId) delta = offer.money;
      if (delta < 0 &&
          s.playerById(bidder).money + delta < auction.highestBid) {
        throw GameRuleException(
            'troca deixaria o maior lance do leilão sem fundos');
      }
    }

    for (final i in offer.giveSquares) {
      s = _updateSquare(s, i, (sq) => sq.copyWith(ownerId: offer.toId));
    }
    for (final i in offer.receiveSquares) {
      s = _updateSquare(s, i, (sq) => sq.copyWith(ownerId: offer.fromId));
    }
    s = _updatePlayer(
        s, offer.fromId, (p) => p.copyWith(money: p.money - offer.money));
    s = _updatePlayer(
        s, offer.toId, (p) => p.copyWith(money: p.money + offer.money));
    events.add(TradeAccepted(offer));
    return _maybeExitDebt(s.copyWith(openTrades: remaining));
  }

  // ── Prisão ────────────────────────────────────────────────────────────

  GameState _payJail(GameState s, PayJail a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll], 'pagar fiança');
    final me = s.currentPlayer;
    if (!me.inJail) throw GameRuleException('você não está preso');
    if (me.money < s.rules.prisonFee) {
      throw GameRuleException('dinheiro insuficiente para a fiança');
    }
    s = _updatePlayer(
        s,
        me.id,
        (p) =>
            p.copyWith(jailTurns: 0, money: p.money - s.rules.prisonFee));
    events.add(LeftPrison(me.id));
    return s;
  }

  GameState _useJailCard(GameState s, UseJailCard a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.preRoll], 'usar carta de saída');
    final me = s.currentPlayer;
    if (!me.inJail) throw GameRuleException('você não está preso');
    if (me.getOutOfJailCards <= 0) {
      throw GameRuleException('você não tem carta de saída');
    }
    // A carta volta ao fundo do baralho (comportamento do original de 2012).
    // Devolve uma carta de saída que esteja FORA do baralho — nunca duplica.
    final freeJailIds = [
      for (final c in s.cardDefs)
        if (c.kind == CardKind.freeJail) c.id,
    ];
    final returnedId = freeJailIds.firstWhere(
      (id) => !s.deck.contains(id),
      orElse: () => freeJailIds.first,
    );
    s = _updatePlayer(
        s,
        me.id,
        (p) => p.copyWith(
            jailTurns: 0, getOutOfJailCards: p.getOutOfJailCards - 1));
    events.add(LeftPrison(me.id));
    return s.copyWith(deck: [...s.deck, returnedId]);
  }

  // ── Turno, fim de jogo e falência ────────────────────────────────────

  GameState _endTurn(GameState s, EndTurn a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.turnEnd], 'encerrar o turno');
    final me = s.currentPlayer;

    final extraRoll = (s.lastRoll?.isDouble ?? false) &&
        !me.inJail &&
        me.doublesCount > 0;
    if (extraRoll) {
      events.add(ExtraRollGranted(me.id));
      return s.copyWith(phase: TurnPhase.preRoll, lastRoll: null);
    }
    return _advanceTurn(s, events);
  }

  GameState _advanceTurn(GameState s, List<GameEvent> events,
      {bool deferFinish = false}) {
    final me = s.currentPlayer;
    s = _updatePlayer(
        s,
        me.id,
        (p) => p.copyWith(
            turnsTaken: p.turnsTaken + 1, doublesCount: 0));

    // Fim do Modo Rápido: todos completaram as rodadas (plano §2.1).
    // [deferFinish]: leilões de liquidação pendentes adiam o placar.
    final rules = s.rules;
    if (!deferFinish &&
        rules.maxRounds > 0 &&
        s.activePlayers.every((p) => p.turnsTaken >= rules.maxRounds)) {
      return _finish(s, events);
    }

    final next = _nextAliveAfter(s, me.id);
    events.add(TurnEnded(me.id, next));
    return s.copyWith(
      currentPlayerId: next,
      phase: TurnPhase.preRoll,
      lastRoll: null,
      debtCreditorId: null,
    );
  }

  GameState _finish(GameState s, List<GameEvent> events) {
    // Vence o maior patrimônio; empate favorece a ordem de turno.
    PlayerState? winner;
    var best = 0;
    for (final p in s.activePlayers) {
      final worth = netWorth(s, p.id);
      if (winner == null || worth > best) {
        winner = p;
        best = worth;
      }
    }
    events.add(GameFinished(winner!.id));
    return s.copyWith(phase: TurnPhase.finished, winnerId: winner.id);
  }

  GameState _declareBankruptcy(
      GameState s, DeclareBankruptcy a, List<GameEvent> events) {
    _requireCurrent(s, a.actorId);
    _requirePhase(s, [TurnPhase.debt], 'declarar falência');
    final creditorId = s.debtCreditorId;

    // Casas são vendidas ao banco automaticamente (50%) e o produto vai
    // direto ao credor, até o valor da dívida (excedente fica com o banco).
    final me = s.currentPlayer;
    final debt = -me.money;
    var houseProceeds = 0;
    final ownedIndexes = <int>[];
    for (var i = 0; i < s.squares.length; i++) {
      final st = s.squares[i];
      if (st.ownerId != me.id) continue;
      ownedIndexes.add(i);
      houseProceeds += st.houses * (s.board[i].housePrice ~/ 2);
    }
    var remainingDebt = debt;
    if (houseProceeds > 0) {
      final pay = houseProceeds < remainingDebt ? houseProceeds : remainingDebt;
      if (creditorId != null && pay > 0) {
        s = _updatePlayer(
            s, creditorId, (p) => p.copyWith(money: p.money + pay));
      }
      remainingDebt -= pay;
    }
    final uncovered = remainingDebt;

    // Propriedades voltam ao banco e vão a leilão entre os demais (§2.3).
    for (final i in ownedIndexes) {
      s = _updateSquare(
          s, i, (sq) => sq.copyWith(ownerId: null, houses: 0, mortgaged: false));
    }

    if (s.rules.eliminationEnabled) {
      s = _updatePlayer(
          s, me.id, (p) => p.copyWith(money: 0, eliminated: true));
      events.add(WentBankrupt(me.id, creditorId, uncovered));
      events.add(PlayerEliminated(me.id));
    } else {
      s = _updatePlayer(
          s,
          me.id,
          (p) => p.copyWith(
                money: s.rules.bankruptcyRestartMoney,
                debtPenalty: p.debtPenalty + uncovered,
              ));
      events.add(WentBankrupt(me.id, creditorId, uncovered));
    }
    s = s.copyWith(debtCreditorId: null, phase: TurnPhase.turnEnd);

    // Último solvente vence o Clássico.
    if (s.rules.eliminationEnabled && s.activePlayers.length == 1) {
      return _finish(s, events);
    }

    // O turno do falido termina aqui; a liquidação acontece já na vez do
    // próximo jogador (eliminado nunca é o jogador da vez). Se houver
    // leilões, o fim de partida do Rápido espera a fila terminar — o placar
    // final precisa refletir a liquidação e a compensação do credor.
    final bidders = [
      for (final p in s.activePlayers)
        if (p.id != me.id) p.id,
    ];
    final willAuction = ownedIndexes.isNotEmpty && bidders.isNotEmpty;
    s = _advanceTurn(s, events, deferFinish: willAuction);
    if (s.phase == TurnPhase.finished) return s;

    if (willAuction) {
      final auction = AuctionState(
        squareIndex: ownedIndexes.first,
        participantIds: bidders,
        queue: ownedIndexes.sublist(1),
        creditorId: creditorId,
        debtRemaining: uncovered,
        resumePreRollWhenDone: true,
      );
      events.add(AuctionStarted(auction.squareIndex));
      return s.copyWith(phase: TurnPhase.auction, auction: auction);
    }
    return s;
  }

  // ── Palpite do dado ───────────────────────────────────────────────────

  GameState _guessDice(GameState s, GuessDice a, List<GameEvent> events) {
    _requirePhase(s, [TurnPhase.preRoll], 'palpitar');
    if (a.actorId == s.currentPlayerId) {
      throw GameRuleException('o jogador da vez não palpita');
    }
    if (s.playerById(a.actorId).eliminated) {
      throw GameRuleException('jogador eliminado não palpita');
    }
    if (a.guess < 2 || a.guess > 12) {
      throw GameRuleException('palpite deve estar entre 2 e 12');
    }
    return s.copyWith(guesses: {...s.guesses, a.actorId: a.guess});
  }
}
