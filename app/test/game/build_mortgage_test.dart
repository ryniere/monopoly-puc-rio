import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

GameState rosaOwner({int houses1 = 0, bool mortgaged3 = false, int money = 1500}) {
  return testState(
    players: [player(p1, money: money), player(p2), player(p3)],
    squareOverrides: {
      Rio.rosa1: SquareState(ownerId: p1, houses: houses1),
      Rio.rosa2: SquareState(ownerId: p1, mortgaged: mortgaged3),
    },
  );
}

void main() {
  group('construção', () {
    test('construir exige grupo de cor completo', () {
      final s = testState(
        squareOverrides: {Rio.rosa1: const SquareState(ownerId: p1)},
      );
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });

    test('construir debita o preço da casa', () {
      final r = engine().apply(rosaOwner(), const BuildHouse(p1, Rio.rosa1));
      expect(r.state.squares[Rio.rosa1].houses, 1);
      expect(r.state.playerById(p1).money,
          1500 - rioBoard[Rio.rosa1].housePrice);
      expect(r.events.whereType<HouseBuilt>(), isNotEmpty);
    });

    test('não constrói com penhora no grupo', () {
      final s = rosaOwner(mortgaged3: true);
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });

    test('máximo 5 (hotel); sexta casa é inválida', () {
      final s = rosaOwner(houses1: 5);
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });

    test('não constrói sem dinheiro', () {
      final s = rosaOwner(money: 10);
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });

    test('não constrói em companhia', () {
      final s = testState(
        squareOverrides: {Rio.companhia1: const SquareState(ownerId: p1)},
      );
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.companhia1)),
          throwsA(isA<GameRuleException>()));
    });

    test('vender casa devolve metade do preço', () {
      final s = rosaOwner(houses1: 2);
      final r = engine().apply(s, const SellHouse(p1, Rio.rosa1));
      expect(r.state.squares[Rio.rosa1].houses, 1);
      expect(r.state.playerById(p1).money,
          1500 + rioBoard[Rio.rosa1].housePrice ~/ 2);
    });

    test('vender sem casas é inválido', () {
      expect(() => engine().apply(rosaOwner(), const SellHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });
  });

  group('penhora', () {
    test('penhorar credita 50% do preço', () {
      final s = testState(
        squareOverrides: {Rio.roxo2: const SquareState(ownerId: p1)},
      );
      final r = engine().apply(s, const MortgageProperty(p1, Rio.roxo2));
      expect(r.state.squares[Rio.roxo2].mortgaged, isTrue);
      expect(r.state.playerById(p1).money,
          1500 + rioBoard[Rio.roxo2].price ~/ 2);
    });

    test('resgatar custa 60% do preço', () {
      final s = testState(
        squareOverrides: {
          Rio.roxo2: const SquareState(ownerId: p1, mortgaged: true)
        },
      );
      final r = engine().apply(s, const UnmortgageProperty(p1, Rio.roxo2));
      expect(r.state.squares[Rio.roxo2].mortgaged, isFalse);
      expect(r.state.playerById(p1).money,
          1500 - (rioBoard[Rio.roxo2].price * 6) ~/ 10);
    });

    test('não penhora com casas no grupo', () {
      final s = testState(
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p1, houses: 1),
          Rio.rosa2: const SquareState(ownerId: p1),
        },
      );
      expect(() => engine().apply(s, const MortgageProperty(p1, Rio.rosa2)),
          throwsA(isA<GameRuleException>()));
    });

    test('não penhora o que não é seu, nem duas vezes', () {
      final s = testState(
        squareOverrides: {
          Rio.roxo2: const SquareState(ownerId: p2, mortgaged: false),
          Rio.roxo1: const SquareState(ownerId: p1, mortgaged: true),
        },
      );
      expect(() => engine().apply(s, const MortgageProperty(p1, Rio.roxo2)),
          throwsA(isA<GameRuleException>()));
      expect(() => engine().apply(s, const MortgageProperty(p1, Rio.roxo1)),
          throwsA(isA<GameRuleException>()));
    });

    test('não resgata sem dinheiro', () {
      final s = testState(
        players: [player(p1, money: 10), player(p2), player(p3)],
        squareOverrides: {
          Rio.roxo2: const SquareState(ownerId: p1, mortgaged: true)
        },
      );
      expect(() => engine().apply(s, const UnmortgageProperty(p1, Rio.roxo2)),
          throwsA(isA<GameRuleException>()));
    });
  });
}
