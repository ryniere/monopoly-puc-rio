/// Testes derivados da revisão adversarial multi-agente (2026-07-14).
/// Cada grupo captura um bug confirmado antes da correção (TDD).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

void main() {
  group('construção uniforme (even-build, como o original de 2012)', () {
    GameState rosa({int h1 = 0, int h2 = 0}) => testState(squareOverrides: {
          Rio.rosa1: SquareState(ownerId: p1, houses: h1),
          Rio.rosa2: SquareState(ownerId: p1, houses: h2),
        });

    test('não constrói onde já há mais casas que no resto do grupo', () {
      final s = rosa(h1: 1, h2: 0);
      expect(() => engine().apply(s, const BuildHouse(p1, Rio.rosa1)),
          throwsA(isA<GameRuleException>()));
      final r = engine().apply(s, const BuildHouse(p1, Rio.rosa2));
      expect(r.state.squares[Rio.rosa2].houses, 1);
    });

    test('não vende de onde há menos casas que no resto do grupo', () {
      final s = rosa(h1: 2, h2: 1);
      expect(() => engine().apply(s, const SellHouse(p1, Rio.rosa2)),
          throwsA(isA<GameRuleException>()));
      final r = engine().apply(s, const SellHouse(p1, Rio.rosa1));
      expect(r.state.squares[Rio.rosa1].houses, 1);
    });
  });

  group('prisão: fiança paga preserva o lançamento extra por dupla', () {
    test('dupla após pagar fiança concede novo lançamento', () {
      var s = testState(players: [
        player(p1, position: 10, jailTurns: 2),
        player(p2),
        player(p3),
      ]);
      s = engine().apply(s, const PayJail(p1)).state;
      // 10 + 10 = 20 (estacionamento, neutro)
      s = engine().apply(s, const RollDice(p1, roll: DiceRoll(5, 5))).state;
      final r = engine().apply(s, const EndTurn(p1));
      expect(r.state.currentPlayerId, p1,
          reason: 'fora da prisão, a dupla vale lançamento extra');
    });
  });

  group('falência na última rodada do Rápido', () {
    GameState lastRound() => testState(
          players: [
            player(p1, money: -100, turnsTaken: 11),
            player(p2, turnsTaken: 12),
            player(p3, turnsTaken: 12),
          ],
          phase: TurnPhase.debt,
          debtCreditorId: p2,
          squareOverrides: {Rio.rosa2: const SquareState(ownerId: p1)},
        );

    test('leilões de liquidação rodam antes do placar final', () {
      final r = engine().apply(lastRound(), const DeclareBankruptcy(p1));
      expect(r.state.phase, TurnPhase.auction,
          reason: 'o fim de partida espera a fila de leilões');
      var s = engine().apply(r.state, const PlaceBid(p3, 60)).state;
      s = engine().apply(s, const PassAuction(p2)).state;
      expect(s.phase, TurnPhase.finished);
      // Credor compensado pelo leilão: p2 = 1500 + 60 = 1560 > p3 = 1500.
      expect(s.playerById(p2).money, 1560);
      expect(s.winnerId, p2);
    });
  });

  group('falência: liquidação compensa o credor', () {
    test('dinheiro da venda automática de casas vai ao credor', () {
      final s = testState(
        players: [player(p1, money: -100), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p1, houses: 2),
          Rio.rosa2: const SquareState(ownerId: p1),
        },
      );
      final r = engine().apply(s, const DeclareBankruptcy(p1));
      // Casas: 2 × (50/2) = 50 → direto ao credor; dívida restante 50.
      expect(r.state.playerById(p2).money, 1550);
      expect(r.state.playerById(p1).debtPenalty, 50);
      expect(r.state.auction!.debtRemaining, 50);
    });

    test('propriedade penhorada vai a leilão e é arrematada limpa', () {
      final s = testState(
        players: [player(p1, money: -50), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        squareOverrides: {
          Rio.rosa2: const SquareState(ownerId: p1, mortgaged: true),
        },
      );
      var r = engine().apply(s, const DeclareBankruptcy(p1)).state;
      r = engine().apply(r, const PlaceBid(p3, 20)).state;
      r = engine().apply(r, const PassAuction(p2)).state;
      expect(r.squares[Rio.rosa2].ownerId, p3);
      expect(r.squares[Rio.rosa2].mortgaged, isFalse);
    });

    test('leilão de falência no Clássico compensa o credor jogador', () {
      final s = testState(
        rules: const RuleSet.classico(),
        players: [player(p1, money: -100), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        squareOverrides: {Rio.rosa2: const SquareState(ownerId: p1)},
      );
      var r = engine().apply(s, const DeclareBankruptcy(p1)).state;
      expect(r.playerById(p1).eliminated, isTrue);
      expect(r.phase, TurnPhase.auction);
      r = engine().apply(r, const PlaceBid(p3, 50)).state;
      r = engine().apply(r, const PassAuction(p2)).state;
      expect(r.playerById(p2).money, 1550);
      expect(r.phase, TurnPhase.preRoll);
      expect(r.currentPlayer.eliminated, isFalse);
    });
  });

  group('blindagem do credor na fase de dívida', () {
    test('devedor não pode dar propriedades em troca durante a dívida', () {
      final s = testState(
        players: [player(p1, money: -100), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        squareOverrides: {Rio.rosa2: const SquareState(ownerId: p1)},
      );
      const gift = TradeOffer(
          id: 'g1', fromId: p1, toId: p3, giveSquares: [Rio.rosa2]);
      expect(() => engine().apply(s, const ProposeTrade(p1, gift)),
          throwsA(isA<GameRuleException>()));
    });

    test('troca pendente que esvazia o devedor não pode ser aceita na dívida',
        () {
      const gift = TradeOffer(
          id: 'g2', fromId: p1, toId: p3, giveSquares: [Rio.rosa2]);
      final s = testState(
        players: [player(p1, money: -100), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        openTrades: const [gift],
        squareOverrides: {Rio.rosa2: const SquareState(ownerId: p1)},
      );
      expect(
          () => engine().apply(s, const RespondTrade(p3, 'g2', accept: true)),
          throwsA(isA<GameRuleException>()));
    });

    test('devedor pode receber doações (só entrada de valor)', () {
      const rescue = TradeOffer(
          id: 'r1', fromId: p2, toId: p1, giveSquares: [], money: 300);
      final s = testState(
        players: [player(p1, money: -100), player(p2), player(p3)],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
        openTrades: const [rescue],
      );
      final r = engine().apply(s, const RespondTrade(p1, 'r1', accept: true));
      expect(r.state.playerById(p1).money, 200);
      expect(r.state.phase, TurnPhase.turnEnd, reason: 'dívida quitada');
    });
  });

  group('trocas × leilão e eliminados', () {
    test('aceitar troca que deixa o maior lance sem fundos é inválido', () {
      var s = testState(players: [
        player(p1, position: 35),
        player(p2),
        player(p3),
      ]);
      s = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3))).state;
      s = engine().apply(s, const DeclineBuy(p1)).state;
      s = engine().apply(s, const PlaceBid(p2, 200)).state;
      const drain = TradeOffer(id: 'd1', fromId: p2, toId: p3, money: 1400);
      s = engine().apply(s, const ProposeTrade(p2, drain)).state;
      expect(
          () => engine().apply(s, const RespondTrade(p3, 'd1', accept: true)),
          throwsA(isA<GameRuleException>()));
    });

    test('troca com eliminado não pode ser aceita', () {
      const t = TradeOffer(id: 'e1', fromId: p2, toId: p3, money: 100);
      final s = testState(
        rules: const RuleSet.classico(),
        players: [player(p1), player(p2, eliminated: true), player(p3)],
        openTrades: const [t],
      );
      expect(
          () => engine().apply(s, const RespondTrade(p3, 'e1', accept: true)),
          throwsA(isA<GameRuleException>()));
    });

    test('troca só de dinheiro é válida', () {
      const t = TradeOffer(id: 'm1', fromId: p2, toId: p3, money: 200);
      var s = engine().apply(testState(), const ProposeTrade(p2, t)).state;
      final r = engine().apply(s, const RespondTrade(p3, 'm1', accept: true));
      expect(r.state.playerById(p2).money, 1300);
      expect(r.state.playerById(p3).money, 1700);
    });
  });

  group('carta de saída com baralhos de múltiplas saídas', () {
    test('devolve ao baralho uma carta que não está nele', () {
      const cards = [
        CardDef(id: 100, kind: CardKind.freeJail, title: 'Saída A'),
        CardDef(id: 101, kind: CardKind.freeJail, title: 'Saída B'),
        CardDef(id: 1, kind: CardKind.receive, amount: 50, title: 'Bônus'),
      ];
      // p1 segura a carta 100; a 101 continua no baralho.
      final s = testState(
        players: [
          player(p1, position: 10, jailTurns: 3, jailCards: 1),
          player(p2),
          player(p3),
        ],
        cards: cards,
        deck: [101, 1],
      );
      final r = engine().apply(s, const UseJailCard(p1));
      expect(r.state.deck.where((id) => id == 101).length, 1,
          reason: 'não pode duplicar a carta que já estava no baralho');
      expect(r.state.deck.where((id) => id == 100).length, 1,
          reason: 'a carta devolvida é a que estava fora');
    });
  });
}
