/// Eventos emitidos por apply() — fonte de animações e do log (game_actions).
/// Clientes reagem a eventos, não a diffs de estado (plano §5.4).
library;

import 'actions.dart';

sealed class GameEvent {
  const GameEvent();
}

class DiceRolled extends GameEvent {
  final String playerId;
  final DiceRoll roll;
  const DiceRolled(this.playerId, this.roll);
}

class GuessResolved extends GameEvent {
  final List<String> correctPlayerIds;
  final int rolledSum;
  const GuessResolved(this.correctPlayerIds, this.rolledSum);
}

class Moved extends GameEvent {
  final String playerId;
  final int from;
  final int to;
  const Moved(this.playerId, this.from, this.to);
}

class SalaryPaid extends GameEvent {
  final String playerId;
  final int amount;
  const SalaryPaid(this.playerId, this.amount);
}

class RentPaid extends GameEvent {
  final String payerId;
  final String ownerId;
  final int amount;
  final int squareIndex;
  const RentPaid(this.payerId, this.ownerId, this.amount, this.squareIndex);
}

class TaxPaid extends GameEvent {
  final String playerId;
  final int amount;
  const TaxPaid(this.playerId, this.amount);
}

class DividendsReceived extends GameEvent {
  final String playerId;
  final int amount;
  const DividendsReceived(this.playerId, this.amount);
}

class CardDrawn extends GameEvent {
  final String playerId;
  final int cardId;
  const CardDrawn(this.playerId, this.cardId);
}

class CardMoneyApplied extends GameEvent {
  final String playerId;
  final int delta;
  const CardMoneyApplied(this.playerId, this.delta);
}

class WentToPrison extends GameEvent {
  final String playerId;
  const WentToPrison(this.playerId);
}

class LeftPrison extends GameEvent {
  final String playerId;
  const LeftPrison(this.playerId);
}

class PropertyBought extends GameEvent {
  final String playerId;
  final int squareIndex;
  final int price;
  const PropertyBought(this.playerId, this.squareIndex, this.price);
}

class AuctionStarted extends GameEvent {
  final int squareIndex;
  const AuctionStarted(this.squareIndex);
}

class BidPlaced extends GameEvent {
  final String playerId;
  final int amount;
  const BidPlaced(this.playerId, this.amount);
}

class AuctionEnded extends GameEvent {
  final int squareIndex;
  final String? winnerId; // null = ninguém arrematou
  final int amount;
  const AuctionEnded(this.squareIndex, this.winnerId, this.amount);
}

class HouseBuilt extends GameEvent {
  final String playerId;
  final int squareIndex;
  final int houses;
  const HouseBuilt(this.playerId, this.squareIndex, this.houses);
}

class HouseSold extends GameEvent {
  final String playerId;
  final int squareIndex;
  final int houses;
  const HouseSold(this.playerId, this.squareIndex, this.houses);
}

class PropertyMortgaged extends GameEvent {
  final String playerId;
  final int squareIndex;
  final int amount;
  const PropertyMortgaged(this.playerId, this.squareIndex, this.amount);
}

class PropertyUnmortgaged extends GameEvent {
  final String playerId;
  final int squareIndex;
  final int amount;
  const PropertyUnmortgaged(this.playerId, this.squareIndex, this.amount);
}

class TradeProposed extends GameEvent {
  final TradeOffer offer;
  const TradeProposed(this.offer);
}

class TradeAccepted extends GameEvent {
  final TradeOffer offer;
  const TradeAccepted(this.offer);
}

class TradeRejected extends GameEvent {
  final String tradeId;
  const TradeRejected(this.tradeId);
}

class DebtEntered extends GameEvent {
  final String playerId;
  final String? creditorId;
  final int shortfall;
  const DebtEntered(this.playerId, this.creditorId, this.shortfall);
}

class WentBankrupt extends GameEvent {
  final String playerId;
  final String? creditorId;
  final int uncoveredDebt;
  const WentBankrupt(this.playerId, this.creditorId, this.uncoveredDebt);
}

class PlayerEliminated extends GameEvent {
  final String playerId;
  const PlayerEliminated(this.playerId);
}

class TurnEnded extends GameEvent {
  final String playerId;
  final String nextPlayerId;
  const TurnEnded(this.playerId, this.nextPlayerId);
}

class ExtraRollGranted extends GameEvent {
  final String playerId;
  const ExtraRollGranted(this.playerId);
}

class GameFinished extends GameEvent {
  final String winnerId;
  const GameFinished(this.winnerId);
}
