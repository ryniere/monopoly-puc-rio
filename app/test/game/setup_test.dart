import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

List<PlayerSetup> setups() => const [
      PlayerSetup(id: p1, name: 'P1'),
      PlayerSetup(id: p2, name: 'P2'),
      PlayerSetup(id: p3, name: 'P3', isAI: true),
    ];

void main() {
  group('createGame — Rápido', () {
    GameState make({int seed = 7}) => createGame(
        rules: const RuleSet.rapido(), players: setups(), rng: Random(seed));

    test('dinheiro inicial 1500, posição 0, fase preRoll', () {
      final s = make();
      expect(s.phase, TurnPhase.preRoll);
      for (final p in s.players) {
        expect(p.money, 1500);
        expect(p.position, 0);
        expect(p.eliminated, isFalse);
      }
      expect(s.players.map((p) => p.id).toSet(), {p1, p2, p3});
      expect(s.players.any((p) => p.id == s.currentPlayerId), isTrue);
    });

    test('cada jogador recebe 2 propriedades sorteadas (regra Speed)', () {
      final s = make();
      for (final p in s.players) {
        final owned = <int>[];
        for (var i = 0; i < s.squares.length; i++) {
          if (s.squares[i].ownerId == p.id) owned.add(i);
        }
        expect(owned, hasLength(2), reason: 'jogador ${p.id}');
        for (final i in owned) {
          expect(s.board[i].type, SquareType.propriedade);
          expect(s.squares[i].houses, 0);
          expect(s.squares[i].mortgaged, isFalse);
        }
      }
    });

    test('baralho é permutação dos ids das cartas', () {
      final s = make();
      expect(s.deck.toSet(), rioCards.map((c) => c.id).toSet());
      expect(s.deckPointer, 0);
    });

    test('mesma seed gera o mesmo jogo; ordem de turno é sorteada', () {
      final a = createGame(
          rules: const RuleSet.rapido(), players: setups(), rng: Random(3));
      final b = createGame(
          rules: const RuleSet.rapido(), players: setups(), rng: Random(3));
      expect(a.players.map((p) => p.id).toList(),
          b.players.map((p) => p.id).toList());
      expect(a.deck, b.deck);
      expect(a.currentPlayerId, b.currentPlayerId);

      // Com seeds variadas a ordem muda em pelo menos uma (sorteio real).
      final orders = <String>{};
      for (var seed = 0; seed < 20; seed++) {
        final g = createGame(
            rules: const RuleSet.rapido(), players: setups(), rng: Random(seed));
        orders.add(g.players.map((p) => p.id).join(','));
      }
      expect(orders.length, greaterThan(1));
    });
  });

  group('createGame — Clássico', () {
    test('dinheiro 2458 e nenhuma propriedade inicial', () {
      final s = createGame(
          rules: const RuleSet.classico(), players: setups(), rng: Random(1));
      for (final p in s.players) {
        expect(p.money, 2458);
      }
      expect(s.squares.every((sq) => sq.ownerId == null), isTrue);
    });
  });
}
