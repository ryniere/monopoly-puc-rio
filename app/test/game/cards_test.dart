import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

import 'helpers.dart';

/// Estado com p1 prestes a cair na casa de Sorte/Azar (índice 2) e um
/// baralho controlado começando pela carta [firstCardId].
GameState aboutToDraw(int firstCardId, {List<PlayerState>? players}) {
  final rest = rioCards
      .map((c) => c.id)
      .where((id) => id != firstCardId && id != cardIdOf(CardKind.freeJail))
      .toList();
  return testState(
    players: players ??
        [player(p1, position: 0), player(p2), player(p3)],
    deck: [firstCardId, ...rest],
  );
}

void main() {
  group('cartas de sorte/azar', () {
    test('cair na casa compra uma carta e avança o ponteiro', () {
      final id = cardIdOf(CardKind.receive);
      final s = aboutToDraw(id);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.events.whereType<CardDrawn>().single.cardId, id);
      expect(r.state.deckPointer, 1);
      expect(r.state.lastCardId, id);
    });

    test('carta de receber credita o valor', () {
      final card = rioCards.firstWhere((c) => c.kind == CardKind.receive);
      final s = aboutToDraw(card.id);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).money, 1500 + card.amount);
    });

    test('carta de pagar debita e pode gerar dívida com o banco', () {
      final card = rioCards.firstWhere((c) => c.kind == CardKind.pay);
      final s = aboutToDraw(card.id, players: [
        player(p1, position: 0, money: card.amount - 5),
        player(p2),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).money, -5);
      expect(r.state.phase, TurnPhase.debt);
      expect(r.state.debtCreditorId, isNull);
    });

    test('vá para a prisão via carta', () {
      final id = cardIdOf(CardKind.goToPrison);
      final s = aboutToDraw(id);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).position, Rio.prisao);
      expect(r.state.playerById(p1).jailTurns, 3);
    });

    test('saída livre sai do baralho e incrementa o contador', () {
      final id = cardIdOf(CardKind.freeJail);
      final rest = rioCards.map((c) => c.id).where((x) => x != id).toList();
      final s = testState(
        players: [player(p1, position: 0), player(p2), player(p3)],
        deck: [id, ...rest],
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).getOutOfJailCards, 1);
      expect(r.state.deck, isNot(contains(id)));
      expect(r.state.deckPointer, 0,
          reason: 'remoção compensa o avanço do ponteiro');
    });

    test('receba por casa construída conta casas e hotéis', () {
      final card =
          rioCards.firstWhere((c) => c.kind == CardKind.receivePerHouse);
      var s = aboutToDraw(card.id);
      s = GameState(
        rules: s.rules,
        board: s.board,
        cardDefs: s.cardDefs,
        players: s.players,
        squares: List.of(s.squares)
          ..[Rio.rosa1] = const SquareState(ownerId: p1, houses: 2)
          ..[Rio.rosa2] = const SquareState(ownerId: p1, houses: 5)
          ..[Rio.roxo2] = const SquareState(ownerId: p2, houses: 3),
        currentPlayerId: s.currentPlayerId,
        phase: s.phase,
        deck: s.deck,
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      // Só as casas do próprio jogador: 2 + 5 = 7.
      expect(r.state.playerById(p1).money, 1500 + card.amount * 7);
    });

    test('todos pagam a você, limitado ao que cada um tem', () {
      final card =
          rioCards.firstWhere((c) => c.kind == CardKind.collectFromEach);
      final s = aboutToDraw(card.id, players: [
        player(p1, position: 0),
        player(p2, money: 10),
        player(p3),
      ]);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      final paidByP2 = card.amount < 10 ? card.amount : 10;
      expect(r.state.playerById(p2).money, 10 - paidByP2);
      expect(r.state.playerById(p3).money, 1500 - card.amount);
      expect(r.state.playerById(p1).money, 1500 + paidByP2 + card.amount);
    });

    test('avance ao Início recebe salário', () {
      final id = cardIdOf(CardKind.advanceToStart);
      final s = aboutToDraw(id);
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      expect(r.state.playerById(p1).position, 0);
      expect(r.state.playerById(p1).money, 1700);
    });

    test('fim do baralho reembaralha sem as cartas de saída presas', () {
      final freeJailId = cardIdOf(CardKind.freeJail);
      final payId = cardIdOf(CardKind.pay);
      // Baralho com 2 cartas, ponteiro já na última.
      final s = testState(
        players: [
          player(p1, position: 0, jailCards: 1),
          player(p2),
          player(p3),
        ],
        deck: [cardIdOf(CardKind.receive), payId],
        deckPointer: 1,
      );
      final r = engine().apply(s, const RollDice(p1, roll: DiceRoll(1, 1)));
      // Comprou a última (pay): reembaralha e o ponteiro volta ao começo.
      expect(r.state.deckPointer, 0);
      expect(r.state.deck.toSet(),
          {cardIdOf(CardKind.receive), payId}..remove(freeJailId));
    });
  });
}
