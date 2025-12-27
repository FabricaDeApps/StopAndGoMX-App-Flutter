import 'dart:ui';
import 'package:flutter/material.dart';
import 'play_book_model.dart';

class PlayBookPainter extends CustomPainter {
  final Size fieldSize;
  final List<PlayerToken> players;
  final String? selectedPlayerId;

  final bool isDragging;
  final String? draggingPlayerId;

  // NUEVO
  final bool isDrawMode;
  final Map<String, List<PlayRoute>> routesByPlayer;
  final List<Offset> activeRoutePoints; // puntos absolutos (preview)

  PlayBookPainter({
    required this.fieldSize,
    required this.players,
    required this.selectedPlayerId,
    required this.isDragging,
    required this.draggingPlayerId,
    required this.isDrawMode,
    required this.routesByPlayer,
    required this.activeRoutePoints,
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

    // ----- RUTAS GUARDADAS -----
    final routePaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Offset? _playerPos(String playerId) {
      final p = players.where((e) => e.id == playerId).toList();
      if (p.isEmpty) return null;
      return p.first.pos;
    }

    routesByPlayer.forEach((playerId, list) {
      final currentPos = _playerPos(playerId);
      if (currentPos == null) return;

      for (final r in list) {
        if (r.points.length < 2) continue;

        // r.points son RELATIVOS al originTokenPos
        // Para que “se mueva con el token”, dibujamos alrededor de currentPos:
        final worldPoints = r.points.map((rel) => currentPos + rel).toList();

        final path = Path()..moveTo(worldPoints.first.dx, worldPoints.first.dy);
        for (final p in worldPoints.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, routePaint);
      }
    });

    // ----- RUTA ACTIVA (PREVIEW EN VIVO) -----
    if (isDrawMode && activeRoutePoints.length >= 2) {
      final activePaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path()
        ..moveTo(activeRoutePoints.first.dx, activeRoutePoints.first.dy);
      for (final p in activeRoutePoints.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, activePaint);
    }

    // ----- JUGADORES -----
    for (final p in players) {
      final isSelected = p.id == selectedPlayerId;

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
        old.draggingPlayerId != draggingPlayerId ||
        old.isDrawMode != isDrawMode ||
        old.routesByPlayer != routesByPlayer ||
        old.activeRoutePoints != activeRoutePoints;
  }
}
