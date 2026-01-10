import 'package:flutter/material.dart';
import '../../core/models/play_book_model.dart';

class PlayBookPainter extends CustomPainter {
  final Size fieldSize;
  final List<PlayerToken> players;
  final String? selectedPlayerId;

  final bool isDragging;
  final String? draggingPlayerId;

  final bool isDrawMode;
  final Map<String, List<PlayRoute>> routesByPlayer;
  final List<Offset> activeRoutePoints;

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
      final y = fieldSize.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(fieldSize.width, y), line);
    }

    // Helpers
    Offset? _playerPos(String playerId) {
      for (final p in players) {
        if (p.id == playerId) return p.pos;
      }
      return null;
    }

    // Flecha (triángulo + colita)
    void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
      final dir = to - from;
      final len = dir.distance;
      if (len < 1) return;

      final ux = dir.dx / len;
      final uy = dir.dy / len;

      // Ajusta aquí el “look” de la flecha
      const double arrowSize = 18.0; // largo del triángulo
      const double arrowWidth = 14.0; // ancho de base del triángulo
      const double tailLength = 10.0; // colita (línea hacia atrás)

      // Punta
      final tip = to;

      // Base del triángulo (un poco atrás del tip)
      final baseCenter = tip - Offset(ux * arrowSize, uy * arrowSize);

      // Vector perpendicular unitario
      final px = -uy;
      final py = ux;

      final left =
          baseCenter + Offset(px * (arrowWidth / 2), py * (arrowWidth / 2));
      final right =
          baseCenter - Offset(px * (arrowWidth / 2), py * (arrowWidth / 2));

      // Colita
      final tailStart = baseCenter - Offset(ux * tailLength, uy * tailLength);
      canvas.drawLine(tailStart, baseCenter, paint);

      // Triángulo sólido
      final fill = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      final tri = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();

      canvas.drawPath(tri, fill);
    }

    // ----- RUTAS GUARDADAS -----
    final routePaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    routesByPlayer.forEach((playerId, list) {
      final currentPos = _playerPos(playerId);
      if (currentPos == null) return;

      for (final r in list) {
        if (r.points.length < 2) continue;

        // puntos RELATIVOS -> mundo con token actual
        final worldPoints = r.points.map((rel) => currentPos + rel).toList();

        // path
        final path = Path()..moveTo(worldPoints.first.dx, worldPoints.first.dy);
        for (final p in worldPoints.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, routePaint);

        // flecha en el último segmento
        final a = worldPoints[worldPoints.length - 2];
        final b = worldPoints.last;
        if (r.endType == RouteEndType.arrow) {
          _drawArrow(canvas, a, b, routePaint);
        } else {
          _drawBlockEnd(canvas, b, routePaint);
        }
      }
    });

    // ----- RUTA ACTIVA (PREVIEW) -----
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

      final a = activeRoutePoints[activeRoutePoints.length - 2];
      final b = activeRoutePoints.last;
      _drawArrow(canvas, a, b, activePaint);
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

  void _drawBlockEnd(Canvas canvas, Offset center, Paint paint) {
    final p = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    const size = 10.0;

    canvas.drawLine(
      center + Offset(-size, -size),
      center + Offset(size, size),
      p,
    );
    canvas.drawLine(
      center + Offset(-size, size),
      center + Offset(size, -size),
      p,
    );
  }
}
