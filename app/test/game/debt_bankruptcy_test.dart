import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

/// p1 em dívida de -100 com p2, dono da rosa1 (com 1 casa) e rosa2.
GameState inDebt({
  RuleSet rules = const RuleSet.rapido(),
  int money = -100,
  String? creditor = p2,
}) {
  return testState(
    rules: rules,
    players: [player(p1, money: money), player(p2), player(p3)],
    phase: TurnPhase.debt,
    debtCreditorId: creditor,
    squareOverrides: {
      Rio.rosa1: const SquareState(ownerId: p1, houses: 1),
      Rio.rosa2: const SquareState(ownerId: p1),
    },
  );
}

void main() {
  group('fase de dívida', () {
    test('encerrar o turno devendo é inválido', () {
      expect(() => engine().apply(inDebt(), const EndTurn(p1)),
          throwsA(isA<GameRuleException>()));
    });

    test('vender ativos até cobrir sai da dívida automaticamente', () {
      var s = inDebt();
      s = engine().apply(s, const SellHouse(p1, Rio.rosa1)).state; // +25
      expect(s.phase, TurnPhase.debt, reason: 'ainda negativo');
      final r = engine().apply(s, const MortgageProperty(p1, Rio.rosa2));
      // +30 (60/2) → -100 +25 +30 = -45? Ainda negativo: continua em dívida.
      // Vamos penhorar a rosa1 também (agora sem casas): +30 → -15. Negativo.
      var s2 = r.state;
      if (s2.phase == TurnPhase.debt) {
        s2 = engine().apply(s2, const MortgageProperty(p1, Rio.rosa1)).state;
      }
      // -100 +25 +30 +30 = -15 → segue em dívida (asserção estrutural).
      expect(s2.playerById(p1).money, -15);
      expect(s2.phase, TurnPhase.debt);
    });

    test('ao ficar não-negativo, a fase avança sozinha para turnEnd', () {
      var s = inDebt(money: -20);
      final r = engine().apply(s, const SellHouse(p1, Rio.rosa1)); // +25
      expect(r.state.playerById(p1).money, 5);
      expect(r.state.phase, TurnPhase.turnEnd);
      expect(r.state.debtCreditorId, isNull);
    });
  });

  group('falência no Rápido (sem eliminação)', () {
    test('recomeça com 500, penalidade permanente e leilão das propriedades',
        () {
      final r = engine().apply(inDebt(), const DeclareBankruptcy(p1));
      final me = r.state.playerById(p1);
      expect(me.eliminated, isFalse);
      // Casas vendidas automaticamente (+25) reduzem a dívida: -100+25 = -75.
      expect(me.debtPenalty, 75);
      expect(me.money, 500);
      expect(r.events.whereType<WentBankrupt>().single.uncoveredDebt, 75);
      // Propriedades vão a leilão entre os demais.
      expect(r.state.phase, TurnPhase.auction);
      final auction = r.state.auction!;
      expect(auction.participantIds.toSet(), {p2, p3});
      expect({auction.squareIndex, ...auction.queue},
          {Rio.rosa1, Rio.rosa2});
      expect(r.state.squares[Rio.rosa1].ownerId, isNull);
      expect(r.state.squares[Rio.rosa1].houses, 0);
    });

    test('credor recebe o produto do leilão até o valor da dívida', () {
      var s = engine().apply(inDebt(), const DeclareBankruptcy(p1)).state;
      // Venda automática das casas (2 × 25 = 25) já foi ao credor:
      // dívida de 100 → restante 75; p2 = 1500 + 25.
      expect(s.playerById(p2).money, 1525);
      // Leilão 1: p3 arremata por 60 → 60 ao credor (restante 15).
      s = engine().apply(s, const PlaceBid(p3, 60)).state;
      var r = engine().apply(s, const PassAuction(p2));
      s = r.state;
      expect(s.playerById(p2).money, 1525 + 60);
      expect(s.playerById(p3).money, 1500 - 60);
      // Leilão 2 na fila: p2 arremata por 40 → só 15 da dívida vão a ele mesmo
      // (credor); o excedente fica com o banco.
      expect(s.phase, TurnPhase.auction);
      s = engine().apply(s, const PlaceBid(p2, 40)).state;
      r = engine().apply(s, const PassAuction(p3));
      s = r.state;
      expect(s.phase, isNot(TurnPhase.auction));
      // p2 pagou 40 e recebeu 15 de si mesmo via banco → -40 +15.
      expect(s.playerById(p2).money, 1525 + 60 - 40 + 15);
    });

    test('após a fila de leilões, o turno avança para o próximo jogador', () {
      var s = engine().apply(inDebt(), const DeclareBankruptcy(p1)).state;
      s = engine().apply(s, const PassAuction(p2)).state;
      s = engine().apply(s, const PassAuction(p3)).state; // leilão 1 sem lances
      s = engine().apply(s, const PassAuction(p2)).state;
      s = engine().apply(s, const PassAuction(p3)).state; // leilão 2 sem lances
      expect(s.phase, TurnPhase.preRoll);
      expect(s.currentPlayerId, isNot(p1));
    });

    test('falir sem estar em dívida é inválido', () {
      expect(() => engine().apply(testState(), const DeclareBankruptcy(p1)),
          throwsA(isA<GameRuleException>()));
    });
  });

  group('falência no Clássico (eliminação)', () {
    test('elimina o jogador', () {
      final r = engine().apply(
          inDebt(rules: const RuleSet.classico()), const DeclareBankruptcy(p1));
      expect(r.state.playerById(p1).eliminated, isTrue);
      expect(r.events.whereType<PlayerEliminated>(), isNotEmpty);
    });

    test('último solvente vence', () {
      final s = testState(
        rules: const RuleSet.classico(),
        players: [
          player(p1, money: -100),
          player(p2),
          player(p3, eliminated: true),
        ],
        phase: TurnPhase.debt,
        debtCreditorId: p2,
      );
      final r = engine().apply(s, const DeclareBankruptcy(p1));
      expect(r.state.phase, TurnPhase.finished);
      expect(r.state.winnerId, p2);
      expect(r.events.whereType<GameFinished>().single.winnerId, p2);
    });
  });

  group('patrimônio líquido', () {
    test('soma dinheiro, propriedades, casas e desconta penalidades', () {
      final s = testState(
        players: [
          player(p1, money: 1000, debtPenalty: 75),
          player(p2),
          player(p3),
        ],
        squareOverrides: {
          Rio.rosa1: const SquareState(ownerId: p1, houses: 2),
          Rio.roxo2: const SquareState(ownerId: p1, mortgaged: true),
        },
      );
      final expected = 1000 +
          rioBoard[Rio.rosa1].price +
          2 * rioBoard[Rio.rosa1].housePrice +
          rioBoard[Rio.roxo2].price ~/ 2 - // penhorada vale 50%
          75;
      expect(netWorth(s, p1), expected);
    });
  });
}
