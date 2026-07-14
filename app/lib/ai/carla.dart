/// Carla, a Negociadora — persona de IA do V1 (plano §2.7).
/// Política legível: compra com folga, disputa leilões do que completa
/// grupo, constrói cedo e sai da prisão pagando.
library;

import 'dart:math';

import '../game/game.dart';

class CarlaAI {
  final Random rnd;
  CarlaAI(this.rnd);

  /// Reserva de caixa que a Carla tenta manter.
  static const _buffer = 200;

  /// Próxima ação da IA para [playerId], ou null se não é a vez dela agir.
  GameAction? nextAction(GameState s, String playerId) {
    switch (s.phase) {
      case TurnPhase.auction:
        final a = s.auction!;
        if (!a.participantIds.contains(playerId) ||
            a.passedIds.contains(playerId) ||
            a.highestBidderId == playerId) {
          return null;
        }
        return _auctionMove(s, playerId, a);

      case TurnPhase.preRoll:
        if (s.currentPlayerId != playerId) return null;
        final me = s.playerById(playerId);
        if (me.inJail) {
          if (me.getOutOfJailCards > 0) return UseJailCard(playerId);
          if (me.money >= s.rules.prisonFee + _buffer) {
            return PayJail(playerId);
          }
          return RollDice(playerId);
        }
        final build = _buildMove(s, playerId);
        if (build != null) return build;
        return RollDice(playerId);

      case TurnPhase.buying:
        if (s.currentPlayerId != playerId) return null;
        final me = s.playerById(playerId);
        final def = s.board[me.position];
        final completes = _wouldCompleteGroup(s, playerId, me.position);
        final threshold = completes ? 0 : _buffer;
        if (me.money - def.price >= threshold) return BuyProperty(playerId);
        return DeclineBuy(playerId);

      case TurnPhase.debt:
        if (s.currentPlayerId != playerId) return null;
        return _debtMove(s, playerId);

      case TurnPhase.turnEnd:
        if (s.currentPlayerId != playerId) return null;
        final build = _buildMove(s, playerId);
        if (build != null) return build;
        return EndTurn(playerId);

      case TurnPhase.finished:
        return null;
    }
  }

  GameAction _auctionMove(GameState s, String playerId, AuctionState a) {
    final def = s.board[a.squareIndex];
    final me = s.playerById(playerId);
    final completes = _wouldCompleteGroup(s, playerId, a.squareIndex);
    final blocks = _wouldBlockOpponent(s, playerId, a.squareIndex);
    var ceiling = (def.price * 0.6).round();
    if (completes) ceiling = (def.price * 1.3).round();
    if (blocks) ceiling = (def.price * 0.9).round();
    final next = a.highestBid == 0 ? 10 : a.highestBid + 10;
    if (next <= ceiling && me.money - next >= (completes ? 0 : _buffer)) {
      return PlaceBid(playerId, next);
    }
    return PassAuction(playerId);
  }

  GameAction? _buildMove(GameState s, String playerId) {
    final me = s.playerById(playerId);
    // Constrói na propriedade de maior aluguel possível, mantendo a reserva.
    int? best;
    var bestRent = -1;
    for (var i = 0; i < s.board.length; i++) {
      final def = s.board[i];
      final st = s.squares[i];
      if (def.type != SquareType.propriedade || st.ownerId != playerId) {
        continue;
      }
      if (st.houses >= 5 || st.mortgaged) continue;
      final group = _group(s, def.colorGroup!);
      if (!group.every((j) => s.squares[j].ownerId == playerId)) continue;
      if (group.any((j) => s.squares[j].mortgaged)) continue;
      final minHouses = group
          .map((j) => s.squares[j].houses)
          .reduce((a, b) => a < b ? a : b);
      if (st.houses > minHouses) continue; // construção uniforme
      if (me.money < def.housePrice + _buffer) continue;
      final rent = def.rentTable[st.houses + 1];
      if (rent > bestRent) {
        bestRent = rent;
        best = i;
      }
    }
    return best == null ? null : BuildHouse(playerId, best);
  }

  GameAction _debtMove(GameState s, String playerId) {
    for (var i = 0; i < s.board.length; i++) {
      if (s.squares[i].ownerId != playerId || s.squares[i].houses == 0) {
        continue;
      }
      final group = _group(s, s.board[i].colorGroup!);
      final maxHouses = group
          .map((j) => s.squares[j].houses)
          .reduce((a, b) => a > b ? a : b);
      if (s.squares[i].houses == maxHouses) {
        return SellHouse(playerId, i); // venda uniforme
      }
    }
    for (var i = 0; i < s.board.length; i++) {
      final st = s.squares[i];
      final def = s.board[i];
      if (st.ownerId != playerId || st.mortgaged) continue;
      if (def.colorGroup != null &&
          _group(s, def.colorGroup!).any((j) => s.squares[j].houses > 0)) {
        continue;
      }
      return MortgageProperty(playerId, i);
    }
    return DeclareBankruptcy(playerId);
  }

  List<int> _group(GameState s, ColorGroup g) => [
        for (final d in s.board)
          if (d.colorGroup == g) d.index,
      ];

  bool _wouldCompleteGroup(GameState s, String playerId, int squareIndex) {
    final def = s.board[squareIndex];
    if (def.colorGroup == null) return false;
    return _group(s, def.colorGroup!)
        .where((i) => i != squareIndex)
        .every((i) => s.squares[i].ownerId == playerId);
  }

  bool _wouldBlockOpponent(GameState s, String playerId, int squareIndex) {
    final def = s.board[squareIndex];
    if (def.colorGroup == null) return false;
    final others = _group(s, def.colorGroup!)
        .where((i) => i != squareIndex)
        .map((i) => s.squares[i].ownerId)
        .toSet();
    return others.length == 1 &&
        others.first != null &&
        others.first != playerId;
  }
}
