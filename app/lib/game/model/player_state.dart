/// Estado dinâmico de um jogador. Referências sempre por id (UUID),
/// nunca por índice (plano §5.4).
class PlayerState {
  final String id;
  final String name;
  final bool isAI;
  final int money;
  final int position;

  /// 0 = livre; senão, tentativas restantes de sair da prisão (3 ao entrar).
  final int jailTurns;
  final int getOutOfJailCards;
  final bool eliminated;

  /// Modo Rápido: dívida não coberta em falência vira penalidade permanente
  /// subtraída do patrimônio final (anti-exploit, plano §2.1).
  final int debtPenalty;

  /// Duplas consecutivas neste turno (3 = prisão).
  final int doublesCount;

  /// Turnos completos jogados (fim de partida do Rápido).
  final int turnsTaken;

  const PlayerState({
    required this.id,
    required this.name,
    this.isAI = false,
    required this.money,
    this.position = 0,
    this.jailTurns = 0,
    this.getOutOfJailCards = 0,
    this.eliminated = false,
    this.debtPenalty = 0,
    this.doublesCount = 0,
    this.turnsTaken = 0,
  });

  bool get inJail => jailTurns > 0;

  PlayerState copyWith({
    int? money,
    int? position,
    int? jailTurns,
    int? getOutOfJailCards,
    bool? eliminated,
    int? debtPenalty,
    int? doublesCount,
    int? turnsTaken,
  }) {
    return PlayerState(
      id: id,
      name: name,
      isAI: isAI,
      money: money ?? this.money,
      position: position ?? this.position,
      jailTurns: jailTurns ?? this.jailTurns,
      getOutOfJailCards: getOutOfJailCards ?? this.getOutOfJailCards,
      eliminated: eliminated ?? this.eliminated,
      debtPenalty: debtPenalty ?? this.debtPenalty,
      doublesCount: doublesCount ?? this.doublesCount,
      turnsTaken: turnsTaken ?? this.turnsTaken,
    );
  }
}
