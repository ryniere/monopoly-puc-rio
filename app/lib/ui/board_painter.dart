import 'package:flutter/material.dart';

import '../game/game.dart';

/// Cores dos grupos (paleta própria — deliberadamente distinta do trade
/// dress clássico, plano §1.1).
const groupColors = <ColorGroup, Color>{
  ColorGroup.rosa: Color(0xFFF06292),
  ColorGroup.azul: Color(0xFF4FC3F7),
  ColorGroup.vinho: Color(0xFF8E244D),
  ColorGroup.laranja: Color(0xFFFF9800),
  ColorGroup.vermelho: Color(0xFFE53935),
  ColorGroup.amarelo: Color(0xFFFDD835),
  ColorGroup.verde: Color(0xFF43A047),
  ColorGroup.roxo: Color(0xFF7E57C2),
};

const playerColors = <Color>[
  Color(0xFF1E88E5),
  Color(0xFFD81B60),
  Color(0xFF00897B),
  Color(0xFFF4511E),
  Color(0xFF6D4C41),
  Color(0xFF546E7A),
];

/// Retângulo de cada casa num tabuleiro quadrado de lado [side].
/// 0 no canto inferior-direito, sentido anti-horário (como o clássico).
Rect squareRect(int index, double side) {
  final corner = side * 0.135;
  final step = (side - 2 * corner) / 9;

  double x, y, w, h;
  if (index == 0) {
    x = side - corner; y = side - corner; w = corner; h = corner;
  } else if (index < 10) {
    w = step; h = corner;
    x = side - corner - step * index; y = side - corner;
  } else if (index == 10) {
    x = 0; y = side - corner; w = corner; h = corner;
  } else if (index < 20) {
    w = corner; h = step;
    x = 0; y = side - corner - step * (index - 10);
  } else if (index == 20) {
    x = 0; y = 0; w = corner; h = corner;
  } else if (index < 30) {
    w = step; h = corner;
    x = corner + step * (index - 21); y = 0;
  } else if (index == 30) {
    x = side - corner; y = 0; w = corner; h = corner;
  } else {
    w = corner; h = step;
    x = side - corner; y = corner + step * (index - 31);
  }
  return Rect.fromLTWH(x, y, w, h);
}

class BoardPainter extends CustomPainter {
  final GameState state;
  BoardPainter(this.state);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final bg = Paint()..color = const Color(0xFFE8F0E4);
    canvas.drawRect(Rect.fromLTWH(0, 0, side, side), bg);

    final border = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < state.board.length; i++) {
      final def = state.board[i];
      final st = state.squares[i];
      final rect = squareRect(i, side);

      // Fundo da casa.
      final fill = Paint()
        ..color = switch (def.type) {
          SquareType.inicio => const Color(0xFFB9DFB0),
          SquareType.prisao => const Color(0xFFCFD8DC),
          SquareType.estacionamento => const Color(0xFFF5F5F5),
          SquareType.vaParaPrisao => const Color(0xFFEF9A9A),
          SquareType.sorteAzar => const Color(0xFFFFF3C4),
          SquareType.impostoDeRenda => const Color(0xFFE1BEE7),
          SquareType.lucrosDividendos => const Color(0xFFC8E6C9),
          SquareType.companhia => const Color(0xFFE3F2FD),
          SquareType.propriedade => Colors.white,
        };
      canvas.drawRect(rect, fill);

      // Faixa do grupo de cor.
      if (def.colorGroup != null) {
        final band = Paint()..color = groupColors[def.colorGroup]!;
        final isVertical = rect.width < rect.height;
        final bandRect = isVertical
            ? Rect.fromLTWH(
                rect.left + (rect.left == 0 ? rect.width - 8 : 0),
                rect.top, 8, rect.height)
            : Rect.fromLTWH(rect.left,
                rect.top + (rect.top == 0 ? rect.height - 8 : 0), rect.width, 8);
        canvas.drawRect(bandRect, band);
      }

      // Dono (contorno colorido) e penhora (hachura cinza).
      if (st.ownerId != null) {
        final idx =
            state.players.indexWhere((p) => p.id == st.ownerId);
        final ownerPaint = Paint()
          ..color = playerColors[idx % playerColors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawRect(rect.deflate(2), ownerPaint);
      }
      if (st.mortgaged) {
        final grey = Paint()..color = Colors.black.withValues(alpha: 0.25);
        canvas.drawRect(rect, grey);
      }

      // Casas/hotel.
      if (st.houses > 0) {
        final houseSize = side * 0.012 + 3;
        final isHotel = st.houses == 5;
        final housePaint = Paint()
          ..color = isHotel ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
        final count = isHotel ? 1 : st.houses;
        for (var hIdx = 0; hIdx < count; hIdx++) {
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + 3 + hIdx * (houseSize + 2),
              rect.top + 3,
              isHotel ? houseSize * 2 : houseSize,
              houseSize,
            ),
            housePaint,
          );
        }
      }

      canvas.drawRect(rect, border);

      // Nome abreviado.
      final tp = TextPainter(
        text: TextSpan(
          text: _abbrev(def),
          style: TextStyle(
            color: const Color(0xFF263238),
            fontSize: (side * 0.018).clamp(7.0, 11.0),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: rect.width - 4);
      tp.paint(
        canvas,
        Offset(rect.left + (rect.width - tp.width) / 2,
            rect.top + (rect.height - tp.height) / 2),
      );
    }

    // Peões.
    final byPosition = <int, List<int>>{};
    for (var i = 0; i < state.players.length; i++) {
      final p = state.players[i];
      if (p.eliminated) continue;
      byPosition.putIfAbsent(p.position, () => []).add(i);
    }
    for (final entry in byPosition.entries) {
      final rect = squareRect(entry.key, side);
      final r = (side * 0.016).clamp(6.0, 12.0);
      for (var k = 0; k < entry.value.length; k++) {
        final playerIdx = entry.value[k];
        final cx = rect.left + r + 2 + (k % 3) * (r * 2 + 2);
        final cy = rect.bottom - r - 2 - (k ~/ 3) * (r * 2 + 2);
        final paint = Paint()
          ..color = playerColors[playerIdx % playerColors.length];
        canvas.drawCircle(Offset(cx, cy), r, paint);
        canvas.drawCircle(
            Offset(cx, cy),
            r,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        final isCurrent =
            state.players[playerIdx].id == state.currentPlayerId;
        if (isCurrent) {
          canvas.drawCircle(
              Offset(cx, cy),
              r + 2.5,
              Paint()
                ..color = Colors.black
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5);
        }
      }
    }
  }

  String _abbrev(SquareDef def) {
    switch (def.type) {
      case SquareType.inicio:
        return 'INÍCIO\n+\$200';
      case SquareType.prisao:
        return 'PRISÃO\n(visita)';
      case SquareType.estacionamento:
        return 'ESTAC.\nGRÁTIS';
      case SquareType.vaParaPrisao:
        return 'VÁ P/\nPRISÃO';
      case SquareType.sorteAzar:
        return '?';
      case SquareType.impostoDeRenda:
        return 'IMPOSTO\n10%';
      case SquareType.lucrosDividendos:
        return 'LUCROS\n+\$200';
      case SquareType.companhia:
        return '${def.name}\n\$${def.price}';
      case SquareType.propriedade:
        return '${def.name}\n\$${def.price}';
    }
  }

  @override
  bool shouldRepaint(covariant BoardPainter old) => old.state != state;
}
