import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _PlayerRow {
  final TextEditingController name;
  bool isAI;
  _PlayerRow(String initial, {this.isAI = false})
      : name = TextEditingController(text: initial);
}

class _HomeScreenState extends State<HomeScreen> {
  GameMode mode = GameMode.rapido;
  final rows = <_PlayerRow>[
    _PlayerRow('Você'),
    _PlayerRow('Carla', isAI: true),
  ];

  @override
  void dispose() {
    for (final r in rows) {
      r.name.dispose();
    }
    super.dispose();
  }

  void _start() {
    final players = <PlayerSetup>[];
    for (var i = 0; i < rows.length; i++) {
      final name = rows[i].name.text.trim();
      if (name.isEmpty) continue;
      players.add(PlayerSetup(
        id: 'p$i',
        name: rows[i].isAI ? '$name 🤖' : name,
        isAI: rows[i].isAI,
      ));
    }
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mínimo de 2 jogadores')));
      return;
    }
    final state = createGame(
      rules: mode == GameMode.rapido
          ? const RuleSet.rapido()
          : const RuleSet.classico(),
      players: players,
      rng: Random(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GameScreen(initialState: state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🎲 Quarteirão',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('Rio de Janeiro — protótipo',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 20),
                    SegmentedButton<GameMode>(
                      segments: const [
                        ButtonSegment(
                            value: GameMode.rapido,
                            label: Text('⚡ Rápido (12 rodadas)')),
                        ButtonSegment(
                            value: GameMode.classico,
                            label: Text('🏛️ Clássico')),
                      ],
                      selected: {mode},
                      onSelectionChanged: (s) =>
                          setState(() => mode = s.first),
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < rows.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Expanded(
                            child: TextField(
                              controller: rows[i].name,
                              decoration: InputDecoration(
                                labelText: 'Jogador ${i + 1}',
                                isDense: true,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text(rows[i].isAI ? '🤖 IA' : '🧑 Humano'),
                            selected: rows[i].isAI,
                            onSelected: (v) =>
                                setState(() => rows[i].isAI = v),
                          ),
                          if (rows.length > 2)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  setState(() => rows.removeAt(i)),
                            ),
                        ]),
                      ),
                    if (rows.length < 6)
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar jogador'),
                        onPressed: () => setState(() => rows.add(
                            _PlayerRow('Jogador ${rows.length + 1}',
                                isAI: true))),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _start,
                      child: const Text('Comece o jogo!',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
