/// Cartas de Sorte/Azar (card_config). Plano §2.3: inclui cartas de
/// comeback com valores relativos.
enum CardKind {
  /// Recebe [amount] do banco.
  receive,

  /// Paga [amount] ao banco.
  pay,

  /// Vai para a prisão.
  goToPrison,

  /// Saída livre da prisão — sai do baralho enquanto estiver com o jogador.
  freeJail,

  /// Recebe [amount] por casa construída (hotel = 5 casas).
  receivePerHouse,

  /// Todos os outros jogadores pagam [amount] a você (limitado ao que têm).
  collectFromEach,

  /// Avança até o Início e recebe o salário.
  advanceToStart,
}

class CardDef {
  final int id;
  final CardKind kind;
  final int amount;
  final String title;

  const CardDef({
    required this.id,
    required this.kind,
    this.amount = 0,
    required this.title,
  });
}
