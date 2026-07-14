import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

void main() {
  group('prisão', () {
    test('cair em "vá para a prisão" prende com 3 tentativas', () {
      final s = testState(players: [
        player(p1, position: 27),
        player(p2),
        player(p3),
      ]);
      // 27 + 3 = 30
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 2)));
      final me = r.state.playerById(p1);
      expect(me.position, Rio.prisao);
      expect(me.jailTurns, 3);
      expect(r.state.phase, TurnPhase.turnEnd);
      expect(r.events.whereType<WentToPrison>(), isNotEmpty);
    });

    test('pagar fiança liberta e permite rolar normalmente', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 2),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const PayJail(p1));
      expect(r.state.playerById(p1).inJail, isFalse);
      expect(r.state.playerById(p1).money, 1450);
      expect(r.state.phase, TurnPhase.preRoll);
      expect(r.events.whereType<LeftPrison>(), isNotEmpty);
    });

    test('pagar fiança sem dinheiro é inválido', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 2, money: 20),
        player(p2),
        player(p3),
      ]);
      expect(() => engine().apply(s, const PayJail(p1)),
          throwsA(isA<GameRuleException>()));
    });

    test('usar carta de saída devolve a carta ao fundo do baralho', () {
      final freeJailId = cardIdOf(CardKind.freeJail);
      final deck =
          rioCards.map((c) => c.id).where((id) => id != freeJailId).toList();
      final s = testState(
        players: [
          player(p1, position: 10, jailTurns: 3, jailCards: 1),
          player(p2),
          player(p3),
        ],
        deck: deck,
      );
      final r = engine().apply(s, const UseJailCard(p1));
      final me = r.state.playerById(p1);
      expect(me.inJail, isFalse);
      expect(me.getOutOfJailCards, 0);
      expect(r.state.deck.last, freeJailId);
      expect(r.state.phase, TurnPhase.preRoll);
    });

    test('usar carta sem tê-la é inválido', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 3),
        player(p2),
        player(p3),
      ]);
      expect(() => engine().apply(s, const UseJailCard(p1)),
          throwsA(isA<GameRuleException>()));
    });

    test('dupla liberta e move, mas sem lançamento extra', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 3),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(5, 5)));
      final me = r.state.playerById(p1);
      expect(me.inJail, isFalse);
      expect(me.position, Rio.estacionamento);
      final r2 = engine().apply(r.state, const EndTurn(p1));
      expect(r2.state.currentPlayerId, isNot(p1),
          reason: 'dupla da prisão não dá lançamento extra');
    });

    test('sem dupla, perde a tentativa e o turno', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 3),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(2, 5)));
      final me = r.state.playerById(p1);
      expect(me.inJail, isTrue);
      expect(me.jailTurns, 2);
      expect(me.position, Rio.prisao, reason: 'não se move sem dupla');
      expect(r.state.phase, TurnPhase.turnEnd);
    });

    test('na última tentativa sem dupla, paga fiança à força e move', () {
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 1),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 2)));
      final me = r.state.playerById(p1);
      expect(me.inJail, isFalse);
      expect(me.money, 1450);
      expect(me.position, 13);
    });

    test('preso não pode simplesmente rolar e sair andando', () {
      // Garantia estrutural: enquanto preso, rolar sem dupla não move.
      final s = testState(players: [
        player(p1, position: 10, jailTurns: 2),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 6)));
      expect(r.state.playerById(p1).position, Rio.prisao);
    });
  });
}
