import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

void main() {
  group('fim do Modo Rápido', () {
    test('acaba quando todos completam as rodadas; vence o maior patrimônio',
        () {
      final s = testState(
        players: [
          player(p1, turnsTaken: 11, position: 20), // vai completar a 12ª
          player(p2, turnsTaken: 12, money: 2000),
          player(p3, turnsTaken: 12, money: 1000),
        ],
        phase: TurnPhase.turnEnd,
      );
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.phase, TurnPhase.finished);
      expect(r.state.winnerId, p2);
      expect(r.events.whereType<GameFinished>().single.winnerId, p2);
    });

    test('não acaba enquanto alguém não completou as rodadas', () {
      final s = testState(
        players: [
          player(p1, turnsTaken: 11),
          player(p2, turnsTaken: 11),
          player(p3, turnsTaken: 12),
        ],
        phase: TurnPhase.turnEnd,
      );
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.phase, TurnPhase.preRoll);
      expect(r.state.currentPlayerId, p2);
      expect(r.state.playerById(p1).turnsTaken, 12);
    });

    test('empate de patrimônio: vence quem vem antes na ordem de turno', () {
      final s = testState(
        players: [
          player(p1, turnsTaken: 11),
          player(p2, turnsTaken: 12),
          player(p3, turnsTaken: 12),
        ],
        phase: TurnPhase.turnEnd,
      );
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.winnerId, p1);
    });

    test('penalidade de falência decide o desempate contra o falido', () {
      final s = testState(
        players: [
          player(p1, turnsTaken: 11, debtPenalty: 75),
          player(p2, turnsTaken: 12),
          player(p3, turnsTaken: 12, money: 100),
        ],
        phase: TurnPhase.turnEnd,
      );
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.winnerId, p2);
    });
  });

  group('passagem de turno', () {
    test('EndTurn avança para o próximo jogador vivo e zera duplas', () {
      final s = testState(
        rules: const RuleSet.classico(),
        players: [
          player(p1, doublesCount: 0),
          player(p2, eliminated: true),
          player(p3),
        ],
        phase: TurnPhase.turnEnd,
      );
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.currentPlayerId, p3, reason: 'pula o eliminado');
      expect(r.state.phase, TurnPhase.preRoll);
      expect(r.events.whereType<TurnEnded>().single.nextPlayerId, p3);
    });

    test('EndTurn fora da fase turnEnd é inválido', () {
      expect(() => engine().apply(testState(), const EndTurn(p1)),
          throwsA(isA<GameRuleException>()));
    });

    test('ações em jogo terminado são inválidas', () {
      final s = testState(phase: TurnPhase.finished);
      expect(() => engine().apply(s, const RollDice(p1)),
          throwsA(isA<GameRuleException>()));
      expect(() => engine().apply(s, const EndTurn(p1)),
          throwsA(isA<GameRuleException>()));
    });
  });

  group('gestão em preRoll e turnEnd', () {
    test('construir é permitido em preRoll e turnEnd, mas não em buying', () {
      final pre = testState(squareOverrides: {
        Rio.rosa1: const SquareState(ownerId: p1),
        Rio.rosa2: const SquareState(ownerId: p1),
      });
      expect(engine().apply(pre, const BuildHouse(p1, Rio.rosa1)).state
          .squares[Rio.rosa1].houses, 1);

      final end = testState(
        phase: TurnPhase.turnEnd,
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p1),
          Rio.rosa2: const SquareState(ownerId: p1),
        },
      );
      expect(engine().apply(end, const BuildHouse(p1, Rio.rosa1)).state
          .squares[Rio.rosa1].houses, 1);

      final buying = testState(
        phase: TurnPhase.buying,
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p1),
          Rio.rosa2: const SquareState(ownerId: p1),
        },
      );
      expect(() => engine().apply(buying, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
    });
  });
}
