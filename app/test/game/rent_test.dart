import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

void main() {
  group('aluguel de propriedade', () {
    test('aluguel base é pago ao dono', () {
      final s = testState(
        players: [player(p1, position: 35), player(p2), player(p3)],
        squareOverrides: {Rio.roxo2: const SquareState(ownerId: p2)},
      );
      // 35 + 4 = 39 (Leblon, base 50)
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.state.playerById(p1).money, 1500 - 50);
      expect(r.state.playerById(p2).money, 1500 + 50);
      final rent = r.events.whereType<RentPaid>().single;
      expect(rent.amount, 50);
      expect(rent.ownerId, p2);
    });

    test('grupo completo sem casas dobra o aluguel base', () {
      final s = testState(
        players: [player(p1, position: 35), player(p2), player(p3)],
        squareOverrides: {
          Rio.roxo1: const SquareState(ownerId: p2),
          Rio.roxo2: const SquareState(ownerId: p2),
        },
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.events.whereType<RentPaid>().single.amount, 100);
    });

    test('aluguel com casas usa a tabela', () {
      final s = testState(
        players: [player(p1, position: 35), player(p2, money: 5000), player(p3)],
        squareOverrides: {
          Rio.roxo1: const SquareState(ownerId: p2),
          Rio.roxo2: const SquareState(ownerId: p2, houses: 3),
        },
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.events.whereType<RentPaid>().single.amount,
          rioBoard[Rio.roxo2].rentTable[3]);
    });

    test('propriedade penhorada não cobra aluguel', () {
      final s = testState(
        players: [player(p1, position: 35), player(p2), player(p3)],
        squareOverrides: {
          Rio.roxo2: const SquareState(ownerId: p2, mortgaged: true),
        },
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.events.whereType<RentPaid>(), isEmpty);
      expect(r.state.playerById(p1).money, 1500);
    });

    test('cair na própria propriedade não cobra nada', () {
      final s = testState(
        players: [player(p1, position: 35), player(p2), player(p3)],
        squareOverrides: {Rio.roxo2: const SquareState(ownerId: p1)},
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.events.whereType<RentPaid>(), isEmpty);
      expect(r.state.phase, TurnPhase.turnEnd);
    });

    test('companhia cobra taxa × soma dos dados', () {
      final s = testState(
        players: [player(p1, position: 0), player(p2), player(p3)],
        squareOverrides: {Rio.companhia1: const SquareState(ownerId: p2)},
      );
      // 0 + 5 = 5 (Metrô, fee 25) → 25 × 5 = 125
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(2, 3)));
      expect(r.events.whereType<RentPaid>().single.amount,
          rioBoard[Rio.companhia1].companyFee * 5);
    });

    test('aluguel maior que o dinheiro leva à fase de dívida com credor', () {
      final s = testState(
        players: [
          player(p1, position: 35, money: 30),
          player(p2),
          player(p3),
        ],
        squareOverrides: {Rio.roxo2: const SquareState(ownerId: p2)},
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.state.phase, TurnPhase.debt);
      expect(r.state.playerById(p1).money, 30 - 50);
      expect(r.state.debtCreditorId, p2);
      expect(r.events.whereType<DebtEntered>().single.creditorId, p2);
    });

    test('dono eliminado não recebe aluguel', () {
      final s = testState(
        rules: const RuleSet.classico(),
        players: [
          player(p1, position: 35),
          player(p2, eliminated: true),
          player(p3),
        ],
        squareOverrides: {Rio.roxo2: const SquareState(ownerId: p2)},
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3)));
      expect(r.events.whereType<RentPaid>(), isEmpty);
    });
  });

  group('imposto e dividendos', () {
    test('imposto de renda é 10% do patrimônio', () {
      final s = testState(players: [
        player(p1, position: 2, money: 2000),
        player(p2),
        player(p3),
      ]);
      // 2 + 2 = 4 (imposto). Patrimônio = 2000 → paga 200.
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.events.whereType<TaxPaid>().single.amount, 200);
      expect(r.state.playerById(p1).money, 1800);
    });

    test('imposto tem piso de 100 e teto de 400', () {
      final poor = testState(players: [
        player(p1, position: 2, money: 300),
        player(p2),
        player(p3),
      ]);
      final r1 = engine().apply(poor, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r1.events.whereType<TaxPaid>().single.amount, 100);

      final rich = testState(players: [
        player(p1, position: 2, money: 9000),
        player(p2),
        player(p3),
      ]);
      final r2 = engine().apply(rich, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r2.events.whereType<TaxPaid>().single.amount, 400);
    });

    test('lucros/dividendos paga 200', () {
      final s = testState(players: [
        player(p1, position: 36),
        player(p2),
        player(p3),
      ]);
      // 36 + 2 = 38 (lucros)
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.events.whereType<DividendsReceived>().single.amount, 200);
      expect(r.state.playerById(p1).money, 1700);
    });
  });
}
