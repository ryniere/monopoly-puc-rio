import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

void main() {
  group('movimento e dados', () {
    test('mover pela soma dos dados', () {
      final s = testState();
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(2, 3)));
      expect(r.state.playerById(p1).position, 5);
      expect(r.events.whereType<DiceRolled>(), isNotEmpty);
      expect(r.events.whereType<Moved>(), isNotEmpty);
    });

    test('passar pelo Início paga salário', () {
      final s = testState(players: [
        player(p1, position: 38),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(3, 3)));
      expect(r.state.playerById(p1).position, 4);
      expect(r.state.playerById(p1).money, lessThan(1500 + 200 + 1));
      expect(r.events.whereType<SalaryPaid>().single.amount, 200);
    });

    test('cair exatamente no Início também paga salário', () {
      final s = testState(players: [
        player(p1, position: 38),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).position, 0);
      expect(r.events.whereType<SalaryPaid>().single.amount, 200);
    });

    test('estacionamento não tem efeito', () {
      final s = testState(players: [
        player(p1, position: 15),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(2, 3)));
      expect(r.state.playerById(p1).position, Rio.estacionamento);
      expect(r.state.playerById(p1).money, 1500);
      expect(r.state.phase, TurnPhase.turnEnd);
    });

    test('dupla concede novo lançamento ao encerrar o turno', () {
      final s = testState(players: [
        player(p1, position: 16), // 16 + 4 = 20 (estacionamento, neutro)
        player(p2),
        player(p3),
      ]);
      final r1 = engine().apply(s, const RollDice(p1, roll: DiceRoll(2, 2)));
      expect(r1.state.phase, TurnPhase.turnEnd);
      final r2 = engine().apply(r1.state, const EndTurn(p1));
      expect(r2.state.currentPlayerId, p1, reason: 'dupla mantém o jogador');
      expect(r2.state.phase, TurnPhase.preRoll);
      expect(r2.state.playerById(p1).doublesCount, 1);
      expect(r2.events.whereType<ExtraRollGranted>(), isNotEmpty);
    });

    test('terceira dupla seguida manda para a prisão sem mover', () {
      final s = testState(players: [
        player(p1, position: 16, doublesCount: 2),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(4, 4)));
      final me = r.state.playerById(p1);
      expect(me.position, Rio.prisao);
      expect(me.inJail, isTrue);
      expect(r.events.whereType<WentToPrison>(), isNotEmpty);
      // Prisão cancela o lançamento extra.
      final r2 = engine().apply(r.state, const EndTurn(p1));
      expect(r2.state.currentPlayerId, isNot(p1));
    });

    test('só o jogador da vez pode rolar, e só em preRoll', () {
      final s = testState();
      expect(() => engine().apply(s, const RollDice(p2, roll: DiceRoll(1, 2))),
          throwsA(isA<GameRuleException>()));
      final s2 = testState(phase: TurnPhase.turnEnd);
      expect(() => engine().apply(s2, const RollDice(p1, roll: DiceRoll(1, 2))),
          throwsA(isA<GameRuleException>()));
    });

    test('RollDice sem roll usa o RNG do engine (determinístico por seed)', () {
      final s = testState();
      final a = engine(seed: 9).apply(s, const RollDice(p1));
      final b = engine(seed: 9).apply(s, const RollDice(p1));
      expect(a.state.playerById(p1).position, b.state.playerById(p1).position);
      final roll = a.events.whereType<DiceRolled>().single.roll;
      expect(roll.d1, inInclusiveRange(1, 6));
      expect(roll.d2, inInclusiveRange(1, 6));
    });
  });

  group('palpite do dado', () {
    test('palpite correto de jogador fora da vez é resolvido no lançamento', () {
      var s = testState();
      s = engine().apply(s, const GuessDice(p2, 7)).state;
      s = engine().apply(s, const GuessDice(p3, 11)).state;
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(3, 4)));
      final resolved = r.events.whereType<GuessResolved>().single;
      expect(resolved.correctPlayerIds, [p2]);
      expect(resolved.rolledSum, 7);
      expect(r.state.guesses, isEmpty);
    });

    test('jogador da vez não pode palpitar; palpite fora de 2-12 é inválido', () {
      final s = testState();
      expect(() => engine().apply(s, const GuessDice(p1, 7)),
          throwsA(isA<GameRuleException>()));
      expect(() => engine().apply(s, const GuessDice(p2, 13)),
          throwsA(isA<GameRuleException>()));
    });
  });
}
