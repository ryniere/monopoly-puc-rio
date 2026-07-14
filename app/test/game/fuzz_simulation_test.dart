import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

/// Política simples de bot para fuzzing/simulação: sempre produz uma ação
/// válida para o estado atual.
GameAction pickAction(GameState s, Random rnd) {
  DiceRoll roll() => DiceRoll(1 + rnd.nextInt(6), 1 + rnd.nextInt(6));

  switch (s.phase) {
    case TurnPhase.preRoll:
      final me = s.currentPlayer;
      if (me.inJail) {
        if (me.getOutOfJailCards > 0) return UseJailCard(me.id);
        if (me.money >= 50 && rnd.nextBool()) return PayJail(me.id);
        return RollDice(me.id, roll: roll());
      }
      // De vez em quando constrói, se puder.
      if (rnd.nextInt(4) == 0) {
        for (var i = 0; i < s.board.length; i++) {
          final def = s.board[i];
          final st = s.squares[i];
          if (def.type != SquareType.propriedade || st.ownerId != me.id) {
            continue;
          }
          final group = [
            for (var j = 0; j < s.board.length; j++)
              if (s.board[j].colorGroup == def.colorGroup) j
          ];
          final ownsAll = group.every((j) => s.squares[j].ownerId == me.id);
          final noMortgage = group.every((j) => !s.squares[j].mortgaged);
          final minHouses = group
              .map((j) => s.squares[j].houses)
              .reduce((a, b) => a < b ? a : b);
          if (ownsAll &&
              noMortgage &&
              st.houses < 5 &&
              st.houses == minHouses && // construção uniforme
              me.money >= def.housePrice + 200) {
            return BuildHouse(me.id, i);
          }
        }
      }
      return RollDice(me.id, roll: roll());

    case TurnPhase.buying:
      final me = s.currentPlayer;
      final def = s.board[me.position];
      if (me.money - def.price >= 200) return BuyProperty(me.id);
      return DeclineBuy(me.id);

    case TurnPhase.auction:
      final a = s.auction!;
      final pending = a.participantIds
          .where((id) =>
              !a.passedIds.contains(id) && id != a.highestBidderId)
          .toList();
      final actor = pending[rnd.nextInt(pending.length)];
      final actorState = s.playerById(actor);
      final nextBid = a.highestBid == 0 ? 10 : a.highestBid + 10;
      final def = s.board[a.squareIndex];
      if (rnd.nextInt(3) == 0 &&
          actorState.money >= nextBid &&
          nextBid <= def.price ~/ 2) {
        return PlaceBid(actor, nextBid);
      }
      return PassAuction(actor);

    case TurnPhase.debt:
      final me = s.currentPlayer;
      for (var i = 0; i < s.board.length; i++) {
        if (s.squares[i].ownerId != me.id || s.squares[i].houses == 0) {
          continue;
        }
        final group = [
          for (var j = 0; j < s.board.length; j++)
            if (s.board[j].colorGroup == s.board[i].colorGroup) j
        ];
        final maxHouses = group
            .map((j) => s.squares[j].houses)
            .reduce((a, b) => a > b ? a : b);
        if (s.squares[i].houses == maxHouses) {
          return SellHouse(me.id, i); // venda uniforme
        }
      }
      for (var i = 0; i < s.board.length; i++) {
        final st = s.squares[i];
        if (st.ownerId != me.id || st.mortgaged) continue;
        final group = [
          for (var j = 0; j < s.board.length; j++)
            if (s.board[j].colorGroup != null &&
                s.board[j].colorGroup == s.board[i].colorGroup)
              j
        ];
        if (group.every((j) => s.squares[j].houses == 0)) {
          return MortgageProperty(me.id, i);
        }
      }
      return DeclareBankruptcy(me.id);

    case TurnPhase.turnEnd:
      return EndTurn(s.currentPlayerId);

    case TurnPhase.finished:
      throw StateError('não deve escolher ação em jogo terminado');
  }
}

void checkInvariants(GameState s) {
  for (final p in s.players) {
    expect(p.position, inInclusiveRange(0, 39), reason: 'posição ${p.id}');
    expect(p.jailTurns, inInclusiveRange(0, 3));
    expect(p.getOutOfJailCards, inInclusiveRange(0, 1));
    if (p.id != s.currentPlayerId && !p.eliminated) {
      expect(p.money, greaterThanOrEqualTo(0),
          reason: 'fora da vez, ${p.id} nunca fica negativo');
    }
    if (s.rules.mode == GameMode.rapido) {
      expect(p.eliminated, isFalse, reason: 'Rápido não elimina');
      if (s.rules.maxRounds > 0) {
        expect(p.turnsTaken, lessThanOrEqualTo(s.rules.maxRounds));
      }
    }
  }
  for (var i = 0; i < s.squares.length; i++) {
    final st = s.squares[i];
    expect(st.houses, inInclusiveRange(0, 5));
    if (st.houses > 0) {
      expect(s.board[i].type, SquareType.propriedade);
      expect(st.ownerId, isNotNull);
      expect(st.mortgaged, isFalse);
    }
    if (st.ownerId != null) {
      expect(s.board[i].isOwnable, isTrue);
    }
  }
  expect(s.deckPointer, inInclusiveRange(0, s.deck.length));
  if (s.phase == TurnPhase.auction) {
    expect(s.auction, isNotNull);
  } else {
    expect(s.auction, isNull);
  }
  if (s.phase == TurnPhase.finished) {
    expect(s.winnerId, isNotNull);
  } else if (s.players.isNotEmpty) {
    expect(s.currentPlayer.eliminated, isFalse,
        reason: 'eliminado nunca é o jogador da vez');
  }
}

void main() {
  test('fuzz: 60 partidas Rápidas terminam sem violar invariantes', () {
    var totalActions = 0;
    for (var seed = 0; seed < 60; seed++) {
      final rnd = Random(seed);
      final eng = GameEngine(Random(seed + 1000));
      var s = createGame(
        rules: const RuleSet.rapido(),
        players: const [
          PlayerSetup(id: p1, name: 'P1'),
          PlayerSetup(id: p2, name: 'P2'),
          PlayerSetup(id: p3, name: 'P3'),
        ],
        rng: rnd,
      );
      var guard = 0;
      while (s.phase != TurnPhase.finished) {
        expect(++guard, lessThan(3000),
            reason: 'seed $seed: partida não termina');
        final action = pickAction(s, rnd);
        s = eng.apply(s, action).state;
        checkInvariants(s);
      }
      totalActions += guard;
      expect(s.winnerId, isNotNull);
    }
    // Diagnóstico de balanceamento (gate fino vem depois, plano §5.6).
    // ignore: avoid_print
    print('fuzz rápido: média de ${totalActions ~/ 60} ações/partida');
  });

  test('fuzz: partidas Clássicas mantêm invariantes por 2000 ações', () {
    for (var seed = 0; seed < 20; seed++) {
      final rnd = Random(seed);
      final eng = GameEngine(Random(seed + 2000));
      var s = createGame(
        rules: const RuleSet.classico(),
        players: const [
          PlayerSetup(id: p1, name: 'P1'),
          PlayerSetup(id: p2, name: 'P2'),
          PlayerSetup(id: p3, name: 'P3'),
        ],
        rng: rnd,
      );
      for (var i = 0; i < 2000 && s.phase != TurnPhase.finished; i++) {
        s = eng.apply(s, pickAction(s, rnd)).state;
        checkInvariants(s);
      }
    }
  });
}
