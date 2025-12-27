import 'dart:ui';
import 'package:flutter/material.dart';
import 'play_book_model.dart';

class PlayBookPainter extends CustomPainter {
  final Size fieldSize;
  final List<PlayerToken> players;
  final String? selectedPlayerId;

  // ✅ nuevos
  final bool isDragging;
  final String? draggingPlayerId;

  PlayBookPainter({
    required this.fieldSize,
    required this.players,
    required this.selectedPlayerId,
    required this.isDragging,
    required this.draggingPlayerId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo campo
    final bg = Paint()..color = const Color(0xFF0F3D2E);
    canvas.drawRect(Offset.zero & fieldSize, bg);

    // Líneas
    final line = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Offset.zero & fieldSize, line);

    for (int i = 1; i <= 4; i++) {
      final x = fieldSize.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, fieldSize.height), line);
    }

    // Jugadores
    for (final p in players) {
      final isSelected = p.id == selectedPlayerId;

      // ✅ Si este jugador se está arrastrando, crece
      final bool isThisDragging = isDragging && (p.id == draggingPlayerId);
      final double r = isThisDragging ? 32.0 : 18.0;

      final fill = Paint()
        ..color = isSelected ? Colors.white : Colors.blueAccent;

      final stroke = Paint()
        ..color = Colors.black.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(p.pos, r, fill);
      canvas.drawCircle(p.pos, r, stroke);

      final tp = TextPainter(
        text: TextSpan(
          text: p.name,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, p.pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant PlayBookPainter old) {
    return old.players != players ||
        old.selectedPlayerId != selectedPlayerId ||
        old.isDragging != isDragging ||
        old.draggingPlayerId != draggingPlayerId;
  }
}
