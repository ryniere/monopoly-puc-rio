import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

const offer = TradeOffer(
  id: 't1',
  fromId: p2,
  toId: p3,
  giveSquares: [Rio.rosa1],
  receiveSquares: [Rio.roxo2],
  money: 100,
);

GameState tradeState() => testState(
      squareOverrides: {
        Rio.rosa1: const SquareState(ownerId: p2),
        Rio.roxo2: const SquareState(ownerId: p3),
      },
    );

void main() {
  group('trocas', () {
    test('proposta pode vir de jogador fora da vez, a qualquer momento', () {
      final r = engine().apply(tradeState(), const ProposeTrade(p2, offer));
      expect(r.state.openTrades, hasLength(1));
      expect(r.events.whereType<TradeProposed>(), isNotEmpty);
    });

    test('aceitar troca move propriedades e dinheiro atomicamente', () {
      var s = engine().apply(tradeState(), const ProposeTrade(p2, offer)).state;
      final r =
          engine().apply(s, const RespondTrade(p3, 't1', accept: true));
      expect(r.state.squares[Rio.rosa1].ownerId, p3);
      expect(r.state.squares[Rio.roxo2].ownerId, p2);
      expect(r.state.playerById(p2).money, 1500 - 100);
      expect(r.state.playerById(p3).money, 1500 + 100);
      expect(r.state.openTrades, isEmpty);
      expect(r.events.whereType<TradeAccepted>(), isNotEmpty);
    });

    test('dinheiro negativo: quem recebe a proposta paga', () {
      const o = TradeOffer(
        id: 't2',
        fromId: p2,
        toId: p3,
        giveSquares: [Rio.rosa1],
        money: -300,
      );
      var s = engine().apply(tradeState(), const ProposeTrade(p2, o)).state;
      final r = engine().apply(s, const RespondTrade(p3, 't2', accept: true));
      expect(r.state.playerById(p2).money, 1500 + 300);
      expect(r.state.playerById(p3).money, 1500 - 300);
      expect(r.state.squares[Rio.rosa1].ownerId, p3);
    });

    test('propriedade com casas não pode ser trocada', () {
      final s = testState(squareOverrides: {
        Rio.rosa1: const SquareState(ownerId: p2, houses: 1),
        Rio.roxo2: const SquareState(ownerId: p3),
      });
      expect(() => engine().apply(s, const ProposeTrade(p2, offer)),
          throwsA(isA<GameRuleException>()));
    });

    test('propriedade penhorada pode ser trocada e continua penhorada', () {
      final s = testState(squareOverrides: {
        Rio.rosa1: const SquareState(ownerId: p2, mortgaged: true),
        Rio.roxo2: const SquareState(ownerId: p3),
      });
      var st = engine().apply(s, const ProposeTrade(p2, offer)).state;
      final r = engine().apply(st, const RespondTrade(p3, 't1', accept: true));
      expect(r.state.squares[Rio.rosa1].ownerId, p3);
      expect(r.state.squares[Rio.rosa1].mortgaged, isTrue);
    });

    test('posse errada invalida a proposta', () {
      final s = testState(squareOverrides: {
        Rio.rosa1: const SquareState(ownerId: p1), // não é do p2
        Rio.roxo2: const SquareState(ownerId: p3),
      });
      expect(() => engine().apply(s, const ProposeTrade(p2, offer)),
          throwsA(isA<GameRuleException>()));
    });

    test('aceitar sem fundos é inválido', () {
      final s = testState(
        players: [player(p1), player(p2, money: 50), player(p3)],
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p2),
          Rio.roxo2: const SquareState(ownerId: p3),
        },
      );
      var st = engine().apply(s, const ProposeTrade(p2, offer)).state;
      // p2 paga 100 mas tem 50.
      expect(() => engine().apply(st, const RespondTrade(p3, 't1', accept: true)),
          throwsA(isA<GameRuleException>()));
    });

    test('só o destinatário aceita; o proponente pode cancelar', () {
      var s = engine().apply(tradeState(), const ProposeTrade(p2, offer)).state;
      expect(() => engine().apply(s, const RespondTrade(p1, 't1', accept: true)),
          throwsA(isA<GameRuleException>()));
      final r = engine().apply(s, const RespondTrade(p2, 't1', accept: false));
      expect(r.state.openTrades, isEmpty);
      expect(r.events.whereType<TradeRejected>(), isNotEmpty);
    });
  });
}
