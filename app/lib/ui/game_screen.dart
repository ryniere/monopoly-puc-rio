import 'dart:math';

import 'package:flutter/material.dart';

import '../ai/carla.dart';
import '../game/game.dart';
import 'board_painter.dart';

class GameScreen extends StatefulWidget {
  final GameState initialState;
  const GameScreen({super.key, required this.initialState});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameState state;
  late final GameEngine engine;
  late final CarlaAI carla;
  final log = <String>[];
  bool finishedDialogShown = false;

  @override
  void initState() {
    super.initState();
    state = widget.initialState;
    engine = GameEngine(Random());
    carla = CarlaAI(Random());
    _scheduleAI();
  }

  // ── Núcleo: aplicar ação e narrar eventos ──────────────────────────────

  void _apply(GameAction action) {
    try {
      final result = engine.apply(state, action);
      setState(() {
        state = result.state;
        for (final e in result.events) {
          final line = _describe(e);
          if (line != null) log.add(line);
        }
      });
      if (state.phase == TurnPhase.finished && !finishedDialogShown) {
        finishedDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showPodium();
        });
      }
      _scheduleAI();
    } on GameRuleException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _scheduleAI() {
    if (state.phase == TurnPhase.finished) return;
    final expectedSeq = state.seq;
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted || state.seq != expectedSeq) return;

      // 1) A IA responde trocas pendentes endereçadas a ela.
      for (final t in state.openTrades) {
        final to = state.playerById(t.toId);
        if (!to.isAI || to.eliminated) continue;
        var action = RespondTrade(t.toId, t.id, accept: _carlaAcceptsTrade(t));
        if (action.accept) {
          try {
            engine.apply(state, action);
          } on GameRuleException {
            action = RespondTrade(t.toId, t.id, accept: false);
          }
        }
        _apply(action);
        return; // _apply re-agenda o próximo passo da IA
      }

      // 2) A IA age no fluxo do jogo (turno, compra, leilão, dívida).
      for (final p in state.players) {
        if (!p.isAI || p.eliminated) continue;
        final action = carla.nextAction(state, p.id);
        if (action != null) {
          _apply(action);
          return;
        }
      }
    });
  }

  /// Avaliação de troca da Carla (plano §2.7): aceita se o que recebe vale
  /// ≥ 1,25× o que entrega; grupo completado vale 1,8× o preço.
  bool _carlaAcceptsTrade(TradeOffer t) {
    int value(List<int> squares, String forId) {
      var v = 0;
      for (final i in squares) {
        final def = state.board[i];
        var price = def.price;
        if (def.colorGroup != null) {
          final others = [
            for (final d in state.board)
              if (d.colorGroup == def.colorGroup && d.index != i) d.index,
          ];
          if (others.every((j) =>
              state.squares[j].ownerId == forId || squares.contains(j))) {
            price = (price * 1.8).round();
          }
        }
        v += price;
      }
      return v;
    }

    final ai = state.playerById(t.toId);
    if (t.money < 0 && ai.money < -t.money) return false;
    final gets = value(t.giveSquares, t.toId) + (t.money > 0 ? t.money : 0);
    final gives =
        value(t.receiveSquares, t.toId) + (t.money < 0 ? -t.money : 0);
    return gets > 0 && gets >= (gives * 1.25).round();
  }

  String _name(String id) => state.playerById(id).name;

  String? _describe(GameEvent e) {
    switch (e) {
      case DiceRolled(:final playerId, :final roll):
        return '🎲 ${_name(playerId)} tirou ${roll.d1} + ${roll.d2} = ${roll.sum}'
            '${roll.isDouble ? ' (dupla!)' : ''}';
      case Moved(:final playerId, :final to):
        return '➡️ ${_name(playerId)} foi para ${state.board[to].name}';
      case SalaryPaid(:final playerId, :final amount):
        return '💰 ${_name(playerId)} recebeu \$$amount de salário';
      case RentPaid(:final payerId, :final ownerId, :final amount, :final squareIndex):
        return '🏠 ${_name(payerId)} pagou \$$amount de aluguel a '
            '${_name(ownerId)} (${state.board[squareIndex].name})';
      case TaxPaid(:final playerId, :final amount):
        return '🧾 ${_name(playerId)} pagou \$$amount de imposto';
      case DividendsReceived(:final playerId, :final amount):
        return '📈 ${_name(playerId)} recebeu \$$amount de dividendos';
      case CardDrawn(:final playerId, :final cardId):
        final card = state.cardDefs.firstWhere((c) => c.id == cardId);
        return '🃏 ${_name(playerId)}: "${card.title}"';
      case CardMoneyApplied(:final playerId, :final delta):
        return delta >= 0
            ? '🍀 ${_name(playerId)} recebeu \$$delta'
            : '⚡ ${_name(playerId)} pagou \$${-delta}';
      case WentToPrison(:final playerId):
        return '🚔 ${_name(playerId)} foi preso!';
      case LeftPrison(:final playerId):
        return '🔓 ${_name(playerId)} saiu da prisão';
      case PropertyBought(:final playerId, :final squareIndex, :final price):
        return '🏷️ ${_name(playerId)} comprou '
            '${state.board[squareIndex].name} por \$$price';
      case AuctionStarted(:final squareIndex):
        return '🔨 Leilão: ${state.board[squareIndex].name}!';
      case BidPlaced(:final playerId, :final amount):
        return '✋ ${_name(playerId)} deu lance de \$$amount';
      case AuctionEnded(:final squareIndex, :final winnerId, :final amount):
        return winnerId == null
            ? '🔨 Ninguém arrematou ${state.board[squareIndex].name}'
            : '🔨 ${_name(winnerId)} arrematou '
                '${state.board[squareIndex].name} por \$$amount';
      case HouseBuilt(:final playerId, :final squareIndex, :final houses):
        return '🏗️ ${_name(playerId)} construiu em '
            '${state.board[squareIndex].name} ($houses)';
      case HouseSold(:final playerId, :final squareIndex, :final houses):
        return '💸 ${_name(playerId)} vendeu casa de '
            '${state.board[squareIndex].name} ($houses)';
      case PropertyMortgaged(:final playerId, :final squareIndex, :final amount):
        return '🏦 ${_name(playerId)} penhorou '
            '${state.board[squareIndex].name} (+\$$amount)';
      case PropertyUnmortgaged(:final playerId, :final squareIndex, :final amount):
        return '🏦 ${_name(playerId)} resgatou '
            '${state.board[squareIndex].name} (−\$$amount)';
      case TradeProposed(:final offer):
        return '🤝 ${_name(offer.fromId)} propôs troca a ${_name(offer.toId)}';
      case TradeAccepted(:final offer):
        return '🤝 Troca fechada entre ${_name(offer.fromId)} e '
            '${_name(offer.toId)}!';
      case TradeRejected():
        return '🚫 Troca recusada';
      case DebtEntered(:final playerId, :final shortfall):
        return '🔻 ${_name(playerId)} está devendo \$$shortfall';
      case WentBankrupt(:final playerId, :final uncoveredDebt):
        return '💥 ${_name(playerId)} faliu (dívida de \$$uncoveredDebt)';
      case PlayerEliminated(:final playerId):
        return '☠️ ${_name(playerId)} foi eliminado';
      case TurnEnded(:final nextPlayerId):
        return '🔁 Vez de ${_name(nextPlayerId)}';
      case ExtraRollGranted(:final playerId):
        return '🎲 ${_name(playerId)} joga de novo (dupla)';
      case GameFinished(:final winnerId):
        return '🏆 ${_name(winnerId)} venceu!';
      case GuessResolved(:final correctPlayerIds):
        return correctPlayerIds.isEmpty
            ? null
            : '🎯 Palpite certo: '
                '${correctPlayerIds.map(_name).join(', ')}';
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF263238),
      appBar: AppBar(
        title: Text(state.rules.mode == GameMode.rapido
            ? 'Modo Rápido — Rio de Janeiro'
            : 'Modo Clássico — Rio de Janeiro'),
        backgroundColor: const Color(0xFF37474F),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        final panel = _sidePanel();
        return wide
            ? Row(children: [
                Expanded(child: _board()),
                SizedBox(width: 380, child: panel),
              ])
            : Column(children: [
                Expanded(flex: 5, child: _board()),
                Expanded(flex: 4, child: panel),
              ]);
      }),
    );
  }

  Widget _board() {
    // O lado vem do espaço REALMENTE disponível — o mesmo valor alimenta o
    // painter e o hit-test, e nunca estoura as constraints (sem clamp
    // invertido em telas baixas).
    return LayoutBuilder(builder: (context, c) {
      final side = max(120.0, min(c.maxWidth, c.maxHeight) - 8);
      return Center(
        child: GestureDetector(
          onTapUp: (d) {
            for (var i = 0; i < 40; i++) {
              if (squareRect(i, side).contains(d.localPosition)) {
                _showSquareSheet(i);
                return;
              }
            }
          },
          child: CustomPaint(
            size: Size.square(side),
            painter: BoardPainter(state),
          ),
        ),
      );
    });
  }

  Widget _sidePanel() {
    return Container(
      color: const Color(0xFF37474F),
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        _playersStrip(),
        const SizedBox(height: 8),
        _actionArea(),
        const SizedBox(height: 8),
        if (state.openTrades.isNotEmpty) _tradesPanel(),
        Expanded(child: _logView()),
      ]),
    );
  }

  Widget _playersStrip() {
    final maxRounds = state.rules.maxRounds;
    return Column(children: [
      if (maxRounds > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Rodada ${(state.players.map((p) => p.turnsTaken).reduce(min) + 1).clamp(1, maxRounds)} de $maxRounds — vence o maior patrimônio',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      SizedBox(
        height: 64,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (var i = 0; i < state.players.length; i++)
              _playerChip(i),
          ],
        ),
      ),
    ]);
  }

  Widget _playerChip(int i) {
    final p = state.players[i];
    final current = p.id == state.currentPlayerId;
    final worth = netWorth(state, p.id);
    return Container(
      width: 118,
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: current ? Colors.white : Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: playerColors[i % playerColors.length], width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
                radius: 6,
                backgroundColor: playerColors[i % playerColors.length]),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                p.eliminated ? '☠️ ${p.name}' : p.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: current ? Colors.black : Colors.white,
                ),
              ),
            ),
          ]),
          Text('\$${p.money}${p.inJail ? '  🚔' : ''}',
              style: TextStyle(
                  fontSize: 12,
                  color: current ? Colors.black87 : Colors.white70)),
          Text('Patrimônio \$$worth',
              style: TextStyle(
                  fontSize: 10,
                  color: current ? Colors.black54 : Colors.white54)),
        ],
      ),
    );
  }

  Widget _actionArea() {
    final me = state.currentPlayer;
    final isHuman = !me.isAI;

    Widget content;
    switch (state.phase) {
      case TurnPhase.preRoll:
        if (!isHuman) {
          content = Text('${me.name} está pensando…',
              style: const TextStyle(color: Colors.white70));
        } else if (me.inJail) {
          content = Wrap(spacing: 8, runSpacing: 8, children: [
            _btn('🎲 Tentar dupla (${me.jailTurns})',
                () => _apply(RollDice(me.id))),
            if (me.money >= state.rules.prisonFee)
              _btn('💵 Pagar fiança \$${state.rules.prisonFee}',
                  () => _apply(PayJail(me.id))),
            if (me.getOutOfJailCards > 0)
              _btn('🃏 Usar carta de saída', () => _apply(UseJailCard(me.id))),
          ]);
        } else {
          content = Wrap(spacing: 8, runSpacing: 8, children: [
            _btn('🎲 Rolar dados', () => _apply(RollDice(me.id)),
                primary: true),
            _btn('🤝 Propor troca', _showTradeDialog),
          ]);
        }
      case TurnPhase.buying:
        final def = state.board[me.position];
        content = isHuman
            ? Wrap(spacing: 8, runSpacing: 8, children: [
                Text('${def.name} — \$${def.price}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                if (me.money >= def.price)
                  _btn('✅ Comprar', () => _apply(BuyProperty(me.id)),
                      primary: true),
                _btn('🔨 Recusar (leilão)', () => _apply(DeclineBuy(me.id))),
              ])
            : Text('${me.name} está decidindo…',
                style: const TextStyle(color: Colors.white70));
      case TurnPhase.auction:
        content = _auctionArea();
      case TurnPhase.debt:
        content = isHuman
            ? Wrap(spacing: 8, runSpacing: 8, children: [
                Text('Você deve \$${-me.money}. Venda ou penhore.',
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
                _btn('💥 Declarar falência',
                    () => _apply(DeclareBankruptcy(me.id))),
              ])
            : Text('${me.name} está se virando…',
                style: const TextStyle(color: Colors.white70));
      case TurnPhase.turnEnd:
        content = isHuman
            ? Wrap(spacing: 8, runSpacing: 8, children: [
                _btn('⏭️ Encerrar turno', () => _apply(EndTurn(me.id)),
                    primary: true),
                _btn('🤝 Propor troca', _showTradeDialog),
              ])
            : Text('${me.name}…', style: const TextStyle(color: Colors.white70));
      case TurnPhase.finished:
        content = _btn('🏆 Ver resultado', _showPodium, primary: true);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Vez de ${me.name}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        content,
      ]),
    );
  }

  Widget _auctionArea() {
    final a = state.auction!;
    final def = state.board[a.squareIndex];
    final pendingHumans = a.participantIds.where((id) {
      final p = state.playerById(id);
      return !p.isAI &&
          !a.passedIds.contains(id) &&
          a.highestBidderId != id;
    }).toList();

    if (pendingHumans.isEmpty) {
      return Text('Leilão de ${def.name}: aguardando…',
          style: const TextStyle(color: Colors.white70));
    }
    final actor = pendingHumans.first;
    final base = a.highestBid == 0 ? 10 : a.highestBid;
    final money = state.playerById(actor).money;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        '🔨 ${def.name} — lance atual \$${a.highestBid}'
        '${a.highestBidderId != null ? ' (${_name(a.highestBidderId!)})' : ''}',
        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 6),
      Text('${_name(actor)} decide:',
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final inc in [
          a.highestBid == 0 ? 10 : base + 10,
          base + 50,
          base + 100
        ])
          if (inc <= money)
            _btn('\$$inc', () => _apply(PlaceBid(actor, inc))),
        _btn('Passar', () => _apply(PassAuction(actor))),
      ]),
    ]);
  }

  Widget _tradesPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 132),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final t in state.openTrades)
                Row(children: [
                  Expanded(
                    child: Text(
                      '🤝 ${_name(t.fromId)} → ${_name(t.toId)}: '
                      '${t.giveSquares.map((i) => state.board[i].name).join('+')}'
                      '${t.money > 0 ? ' +\$${t.money}' : ''} por '
                      '${t.receiveSquares.map((i) => state.board[i].name).join('+')}'
                      '${t.money < 0 ? ' +\$${-t.money}' : ''}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  if (!state.playerById(t.toId).isAI) ...[
                    IconButton(
                      icon: const Icon(Icons.check,
                          color: Colors.green, size: 18),
                      onPressed: () =>
                          _apply(RespondTrade(t.toId, t.id, accept: true)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      onPressed: () =>
                          _apply(RespondTrade(t.toId, t.id, accept: false)),
                    ),
                  ] else if (!state.playerById(t.fromId).isAI)
                    IconButton(
                      tooltip: 'Cancelar proposta',
                      icon: const Icon(Icons.undo,
                          color: Colors.orange, size: 18),
                      onPressed: () =>
                          _apply(RespondTrade(t.fromId, t.id, accept: false)),
                    ),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logView() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        reverse: true,
        itemCount: log.length,
        itemBuilder: (_, i) => Text(
          log[log.length - 1 - i],
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _btn(String label, VoidCallback onTap, {bool primary = false}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary ? const Color(0xFF43A047) : Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      onPressed: onTap,
      child: Text(label),
    );
  }

  // ── Bottom sheet da casa (detalhe + gestão) ────────────────────────────

  void _showSquareSheet(int index) {
    final def = state.board[index];
    if (!def.isOwnable) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setSheet) {
        final st = state.squares[index];
        final me = state.currentPlayer;
        final canManage = !me.isAI &&
            st.ownerId == me.id &&
            (state.phase == TurnPhase.preRoll ||
                state.phase == TurnPhase.turnEnd ||
                state.phase == TurnPhase.debt);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (def.colorGroup != null)
                  Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.only(right: 8),
                      color: groupColors[def.colorGroup]),
                Text(def.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('\$${def.price}'),
              ]),
              const SizedBox(height: 8),
              Text(st.ownerId == null
                  ? 'Sem dono'
                  : 'Dono: ${_name(st.ownerId!)}'
                      '${st.mortgaged ? ' (penhorada)' : ''}'
                      '${st.houses > 0 ? ' — ${st.houses == 5 ? "hotel" : "${st.houses} casa(s)"}' : ''}'),
              const SizedBox(height: 8),
              if (def.type == SquareType.propriedade) ...[
                Text(
                  'Aluguel: \$${def.rentTable[0]} · grupo completo '
                  '\$${def.rentTable[0] * 2} · casas '
                  '${def.rentTable.sublist(1, 5).map((r) => '\$$r').join(' / ')}'
                  ' · hotel \$${def.rentTable[5]}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text('Casa: \$${def.housePrice} · Penhora: '
                    '\$${def.price ~/ 2} / resgate \$${(def.price * 6) ~/ 10}',
                    style: const TextStyle(fontSize: 12)),
              ] else
                Text('Aluguel: \$${def.companyFee} × soma dos dados',
                    style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              if (canManage)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (def.type == SquareType.propriedade &&
                      st.houses < 5 &&
                      !st.mortgaged &&
                      state.phase != TurnPhase.debt)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _apply(BuildHouse(me.id, index));
                      },
                      child: Text('🏗️ Construir (\$${def.housePrice})'),
                    ),
                  if (st.houses > 0)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _apply(SellHouse(me.id, index));
                      },
                      child:
                          Text('💸 Vender casa (+\$${def.housePrice ~/ 2})'),
                    ),
                  if (!st.mortgaged && st.houses == 0)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _apply(MortgageProperty(me.id, index));
                      },
                      child: Text('🏦 Penhorar (+\$${def.price ~/ 2})'),
                    ),
                  if (st.mortgaged && state.phase != TurnPhase.debt)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _apply(UnmortgageProperty(me.id, index));
                      },
                      child: Text(
                          '🏦 Resgatar (−\$${(def.price * 6) ~/ 10})'),
                    ),
                ]),
            ],
          ),
        );
      }),
    );
  }

  // ── Troca (balança simplificada) ───────────────────────────────────────

  void _showTradeDialog() {
    final me = state.currentPlayer;
    final others = state.activePlayers.where((p) => p.id != me.id).toList();
    if (others.isEmpty) return;
    String toId = others.first.id;
    final give = <int>{};
    final receive = <int>{};
    final moneyCtrl = TextEditingController(text: '0');

    List<int> ownedBy(String id) => [
          for (var i = 0; i < state.squares.length; i++)
            if (state.squares[i].ownerId == id && state.squares[i].houses == 0)
              i,
        ];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (context, setDialog) {
        return AlertDialog(
          title: const Text('Propor troca'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: toId,
                    items: [
                      for (final o in others)
                        DropdownMenuItem(value: o.id, child: Text(o.name)),
                    ],
                    onChanged: (v) => setDialog(() {
                      toId = v!;
                      receive.clear();
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text('Você dá:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(spacing: 4, children: [
                    for (final i in ownedBy(me.id))
                      FilterChip(
                        label: Text(state.board[i].name,
                            style: const TextStyle(fontSize: 11)),
                        selected: give.contains(i),
                        onSelected: (v) => setDialog(
                            () => v ? give.add(i) : give.remove(i)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  const Text('Você recebe:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(spacing: 4, children: [
                    for (final i in ownedBy(toId))
                      FilterChip(
                        label: Text(state.board[i].name,
                            style: const TextStyle(fontSize: 11)),
                        selected: receive.contains(i),
                        onSelected: (v) => setDialog(
                            () => v ? receive.add(i) : receive.remove(i)),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  TextField(
                    controller: moneyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        signed: true),
                    decoration: const InputDecoration(
                      labelText:
                          'Dinheiro (positivo: você paga; negativo: você recebe)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final money = int.tryParse(moneyCtrl.text) ?? 0;
                _apply(ProposeTrade(
                  me.id,
                  TradeOffer(
                    id: 'trade-${state.seq}',
                    fromId: me.id,
                    toId: toId,
                    giveSquares: give.toList(),
                    receiveSquares: receive.toList(),
                    money: money,
                  ),
                ));
              },
              child: const Text('Propor'),
            ),
          ],
        );
      }),
    );
  }

  // ── Pódio ──────────────────────────────────────────────────────────────

  void _showPodium() {
    final ranking = [...state.players]
      ..sort((a, b) => netWorth(state, b.id).compareTo(netWorth(state, a.id)));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('🏆 ${_name(state.winnerId!)} venceu!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < ranking.length; i++)
              ListTile(
                dense: true,
                leading: Text(['🥇', '🥈', '🥉', '4º', '5º', '6º'][i],
                    style: const TextStyle(fontSize: 18)),
                title: Text(ranking[i].name),
                trailing: Text('\$${netWorth(state, ranking[i].id)}'),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('🔁 Revanche'),
          ),
        ],
      ),
    );
  }
}
