/// Definição estática de uma casa do tabuleiro (board_config), separada do
/// estado dinâmico (SquareState). Plano §5.4: config remoto/versionado.
enum SquareType {
  inicio,
  propriedade,
  companhia,
  sorteAzar,
  impostoDeRenda,
  lucrosDividendos,
  prisao, // só visita
  vaParaPrisao,
  estacionamento,
}

enum ColorGroup { rosa, azul, vinho, laranja, vermelho, amarelo, verde, roxo }

class SquareDef {
  final int index;
  final String name;
  final SquareType type;
  final ColorGroup? colorGroup;
  final int price;

  /// [base, 1 casa, 2, 3, 4, hotel] — só para propriedades.
  final List<int> rentTable;
  final int housePrice;

  /// Companhias: aluguel = companyFee × soma dos dados.
  final int companyFee;

  const SquareDef({
    required this.index,
    required this.name,
    required this.type,
    this.colorGroup,
    this.price = 0,
    this.rentTable = const [],
    this.housePrice = 0,
    this.companyFee = 0,
  });

  bool get isOwnable =>
      type == SquareType.propriedade || type == SquareType.companhia;
}
