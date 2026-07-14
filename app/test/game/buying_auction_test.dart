import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

GameState landOnUnowned() {
  final s = testState(players: [
    player(p1, position: 35),
    player(p2),
    player(p3),
  ]);
  return engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3))).state;
}

void main() {
  group('compra', () {
    test('cair em propriedade sem dono abre a fase de compra', () {
      final s = landOnUnowned();
      expect(s.phase, TurnPhase.buying);
    });

    test('comprar transfere dinheiro e posse', () {
      final s = landOnUnowned();
      final r = engine().apply(s, const BuyProperty(p1));
      expect(r.state.squares[Rio.roxo2].ownerId, p1);
      expect(r.state.playerById(p1).money, 1500 - rioBoard[Rio.roxo2].price);
      expect(r.state.phase, TurnPhase.turnEnd);
      expect(r.events.whereType<PropertyBought>(), isNotEmpty);
    });

    test('comprar sem dinheiro suficiente é inválido', () {
      var s = testState(players: [
        player(p1, position: 35, money: 100),
        player(p2),
        player(p3),
      ]);
      s = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 3))).state;
      expect(s.phase, TurnPhase.buying);
      expect(() => engine().apply(s, const BuyProperty(p1)),
          throwsA(isA<GameRuleException>()));
    });
  });

  group('leilão', () {
    test('recusar compra abre leilão com todos os jogadores ativos', () {
      final s = landOnUnowned();
      final r = engine().apply(s, const DeclineBuy(p1));
      expect(r.state.phase, TurnPhase.auction);
      expect(r.state.auction!.squareIndex, Rio.roxo2);
      expect(r.state.auction!.participantIds.toSet(), {p1, p2, p3});
      expect(r.events.whereType<AuctionStarted>(), isNotEmpty);
    });

    test('primeiro lance mínimo de 10; lances seguintes devem superar', () {
      var s = engine().apply(landOnUnowned(), const DeclineBuy(p1)).state;
      expect(() => engine().apply(s, const PlaceBid(p2, 5)),
          throwsA(isA<GameRuleException>()));
      s = engine().apply(s, const PlaceBid(p2, 10)).state;
      expect(() => engine().apply(s, const PlaceBid(p3, 10)),
          throwsA(isA<GameRuleException>()));
      s = engine().apply(s, const PlaceBid(p3, 60)).state;
      expect(s.auction!.highestBidderId, p3);
      expect(s.auction!.highestBid, 60);
    });

    test('lance acima do próprio dinheiro é inválido', () {
      final s = engine().apply(landOnUnowned(), const DeclineBuy(p1)).state;
      expect(() => engine().apply(s, const PlaceBid(p2, 2000)),
          throwsA(isA<GameRuleException>()));
    });

    test('leilão termina quando todos menos o maior lance passam', () {
      var s = engine().apply(landOnUnowned(), const DeclineBuy(p1)).state;
      s = engine().apply(s, const PlaceBid(p2, 80)).state;
      s = engine().apply(s, const PassAuction(p1)).state;
      final r = engine().apply(s, const PassAuction(p3));
      expect(r.state.phase, TurnPhase.turnEnd);
      expect(r.state.auction, isNull);
      expect(r.state.squares[Rio.roxo2].ownerId, p2);
      expect(r.state.playerById(p2).money, 1500 - 80);
      final end = r.events.whereType<AuctionEnded>().single;
      expect(end.winnerId, p2);
      expect(end.amount, 80);
    });

    test('todos passam sem lance: propriedade fica sem dono', () {
      var s = engine().apply(landOnUnowned(), const DeclineBuy(p1)).state;
      s = engine().apply(s, const PassAuction(p1)).state;
      s = engine().apply(s, const PassAuction(p2)).state;
      final r = engine().apply(s, const PassAuction(p3));
      expect(r.state.phase, TurnPhase.turnEnd);
      expect(r.state.squares[Rio.roxo2].ownerId, isNull);
      expect(r.events.whereType<AuctionEnded>().single.winnerId, isNull);
    });

    test('quem recusou também pode dar lance (regra clássica)', () {
      var s = engine().apply(landOnUnowned(), const DeclineBuy(p1)).state;
      s = engine().apply(s, const PlaceBid(p1, 50)).state;
      s = engine().apply(s, const PassAuction(p2)).state;
      final r = engine().apply(s, const PassAuction(p3));
      expect(r.state.squares[Rio.roxo2].ownerId, p1);
    });

    test('fora do leilão, PlaceBid é inválido', () {
      final s = testState();
      expect(() => engine().apply(s, const PlaceBid(p2, 50)),
          throwsA(isA<GameRuleException>()));
    });
  });
}
