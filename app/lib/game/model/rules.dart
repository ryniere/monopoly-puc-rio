/// Conjunto de regras de uma partida. O "modo" é um conjunto de parâmetros
/// (plano §2.1/§2.6) — nunca lógica condicional espalhada pelo engine.
enum GameMode { rapido, classico }

class RuleSet {
  final GameMode mode;
  final int initialMoney;
  final int salary;
  final int prisonFee;

  /// Rodadas até o fim (0 = sem limite, vence o último solvente).
  final int maxRounds;

  /// Propriedades sorteadas na largada (regra "Speed").
  final int startingProperties;

  /// Dinheiro de recomeço após falência no modo Rápido.
  final int bankruptcyRestartMoney;

  /// Falência elimina o jogador (Clássico) ou recomeça (Rápido).
  final bool eliminationEnabled;

  const RuleSet({
    required this.mode,
    required this.initialMoney,
    required this.salary,
    required this.prisonFee,
    required this.maxRounds,
    required this.startingProperties,
    required this.bankruptcyRestartMoney,
    required this.eliminationEnabled,
  });

  const RuleSet.rapido()
      : this(
          mode: GameMode.rapido,
          initialMoney: 1500,
          salary: 200,
          prisonFee: 50,
          maxRounds: 12,
          startingProperties: 2,
          bankruptcyRestartMoney: 500,
          eliminationEnabled: false,
        );

  const RuleSet.classico()
      : this(
          mode: GameMode.classico,
          initialMoney: 2458,
          salary: 200,
          prisonFee: 50,
          maxRounds: 0,
          startingProperties: 0,
          bankruptcyRestartMoney: 0,
          eliminationEnabled: true,
        );
}
