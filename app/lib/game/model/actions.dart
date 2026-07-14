/// GameAction como sealed class — a espinha dorsal do engine (plano §5.1).
/// O mesmo tipo serializado alimenta game_actions, a validação server-side,
/// as animações e o retry idempotente.
library;

class DiceRoll {
  final int d1;
  final int d2;
  const DiceRoll(this.d1, this.d2)
      : assert(d1 >= 1 && d1 <= 6),
        assert(d2 >= 1 && d2 <= 6);
  int get sum => d1 + d2;
  bool get isDouble => d1 == d2;
}

sealed class GameAction {
  final String actorId;
  const GameAction(this.actorId);
}

/// Rola os dados. [roll] pré-definido vem do servidor (RNG server-side);
/// null = engine sorteia localmente (offline).
class RollDice extends GameAction {
  final DiceRoll? roll;
  const RollDice(super.actorId, {this.roll});
}

class BuyProperty extends GameAction {
  const BuyProperty(super.actorId);
}

class DeclineBuy extends GameAction {
  const DeclineBuy(super.actorId);
}

class PlaceBid extends GameAction {
  final int amount;
  const PlaceBid(super.actorId, this.amount);
}

class PassAuction extends GameAction {
  const PassAuction(super.actorId);
}

class BuildHouse extends GameAction {
  final int squareIndex;
  const BuildHouse(super.actorId, this.squareIndex);
}

class SellHouse extends GameAction {
  final int squareIndex;
  const SellHouse(super.actorId, this.squareIndex);
}

/// Penhora: vende ao banco por 50% do preço, recompra por 60% (plano §2.2).
class MortgageProperty extends GameAction {
  final int squareIndex;
  const MortgageProperty(super.actorId, this.squareIndex);
}

class UnmortgageProperty extends GameAction {
  final int squareIndex;
  const UnmortgageProperty(super.actorId, this.squareIndex);
}

class TradeOffer {
  final String id;
  final String fromId;
  final String toId;
  final List<int> giveSquares;
  final List<int> receiveSquares;

  /// > 0: [fromId] paga a [toId]; < 0: [toId] paga a [fromId].
  final int money;

  const TradeOffer({
    required this.id,
    required this.fromId,
    required this.toId,
    this.giveSquares = const [],
    this.receiveSquares = const [],
    this.money = 0,
  });
}

/// Trocas podem ser propostas e respondidas a qualquer momento (plano §2.2).
class ProposeTrade extends GameAction {
  final TradeOffer offer;
  const ProposeTrade(super.actorId, this.offer);
}

class RespondTrade extends GameAction {
  final String tradeId;
  final bool accept;
  const RespondTrade(super.actorId, this.tradeId, {required this.accept});
}

class PayJail extends GameAction {
  const PayJail(super.actorId);
}

class UseJailCard extends GameAction {
  const UseJailCard(super.actorId);
}

class EndTurn extends GameAction {
  const EndTurn(super.actorId);
}

class DeclareBankruptcy extends GameAction {
  const DeclareBankruptcy(super.actorId);
}

/// Palpite do dado (2–12) por jogador fora da vez (plano §2.5).
class GuessDice extends GameAction {
  final int guess;
  const GuessDice(super.actorId, this.guess);
}
