import 'package:flutter_test/flutter_test.dart';
import 'package:quarteirao/game/game.dart';

void main() {
  group('rioBoard', () {
    test('tem exatamente 40 casas com índices 0..39 em ordem', () {
      expect(rioBoard, hasLength(40));
      for (var i = 0; i < 40; i++) {
        expect(rioBoard[i].index, i);
      }
    });

    test('cantos nos índices clássicos', () {
      expect(rioBoard[0].type, SquareType.inicio);
      expect(rioBoard[10].type, SquareType.prisao);
      expect(rioBoard[20].type, SquareType.estacionamento);
      expect(rioBoard[30].type, SquareType.vaParaPrisao);
    });

    test('22 propriedades em 8 grupos de cor com 2-4 casas cada', () {
      final props =
          rioBoard.where((s) => s.type == SquareType.propriedade).toList();
      expect(props, hasLength(22));
      final byGroup = <ColorGroup, int>{};
      for (final s in props) {
        expect(s.colorGroup, isNotNull, reason: '${s.name} sem grupo');
        byGroup[s.colorGroup!] = (byGroup[s.colorGroup!] ?? 0) + 1;
      }
      expect(byGroup.keys.toSet(), ColorGroup.values.toSet());
      for (final e in byGroup.entries) {
        expect(e.value, inInclusiveRange(2, 4), reason: '${e.key}');
      }
    });

    test('propriedades têm preço, tabela de aluguel crescente e housePrice', () {
      for (final s in rioBoard.where((s) => s.type == SquareType.propriedade)) {
        expect(s.price, greaterThan(0), reason: s.name);
        expect(s.housePrice, greaterThan(0), reason: s.name);
        expect(s.rentTable, hasLength(6), reason: s.name);
        for (var i = 1; i < 6; i++) {
          expect(s.rentTable[i], greaterThan(s.rentTable[i - 1]),
              reason: '${s.name} rentTable não crescente');
        }
      }
    });

    test('6 companhias com preço e taxa', () {
      final comps =
          rioBoard.where((s) => s.type == SquareType.companhia).toList();
      expect(comps, hasLength(6));
      for (final s in comps) {
        expect(s.price, greaterThan(0));
        expect(s.companyFee, greaterThan(0));
        expect(s.rentTable, isEmpty);
      }
    });

    test('6 sorte/azar, 1 imposto e 1 lucros', () {
      expect(rioBoard.where((s) => s.type == SquareType.sorteAzar), hasLength(6));
      expect(
          rioBoard.where((s) => s.type == SquareType.impostoDeRenda), hasLength(1));
      expect(rioBoard.where((s) => s.type == SquareType.lucrosDividendos),
          hasLength(1));
    });

    test('nomes únicos e não vazios', () {
      final names = rioBoard.map((s) => s.name).toList();
      expect(names.toSet(), hasLength(40));
      expect(names.every((n) => n.trim().isNotEmpty), isTrue);
    });
  });

  group('rioCards', () {
    test('tem pelo menos 30 cartas com ids únicos', () {
      expect(rioCards.length, greaterThanOrEqualTo(30));
      expect(rioCards.map((c) => c.id).toSet(), hasLength(rioCards.length));
    });

    test('composição: 1 saída-livre, prisão, comeback e avanço', () {
      expect(rioCards.where((c) => c.kind == CardKind.freeJail), hasLength(1));
      expect(rioCards.where((c) => c.kind == CardKind.goToPrison), hasLength(1));
      expect(rioCards.where((c) => c.kind == CardKind.receivePerHouse),
          isNotEmpty);
      expect(
          rioCards.where((c) => c.kind == CardKind.collectFromEach), isNotEmpty);
      expect(
          rioCards.where((c) => c.kind == CardKind.advanceToStart), isNotEmpty);
    });

    test('cartas de dinheiro têm amount > 0 e título', () {
      for (final c in rioCards) {
        expect(c.title.trim(), isNotEmpty);
        if (c.kind == CardKind.receive ||
            c.kind == CardKind.pay ||
            c.kind == CardKind.receivePerHouse ||
            c.kind == CardKind.collectFromEach) {
          expect(c.amount, greaterThan(0), reason: c.title);
        }
      }
    });
  });
}
