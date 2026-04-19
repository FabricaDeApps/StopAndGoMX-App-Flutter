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
  final RouteEndType currentRouteType;

  PlayBookPainter({
    required this.fieldSize,
    required this.players,
    required this.selectedPlayerId,
    required this.isDragging,
    required this.draggingPlayerId,
    required this.isDrawMode,
    required this.routesByPlayer,
    required this.activeRoutePoints,
    required this.currentRouteType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo campo
    final bg = Paint()..color = const Color(0xFF0F3D2E);
    canvas.drawRect(Offset.zero & fieldSize, bg);

    // Líneas
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(Offset.zero & fieldSize, line);

    for (int i = 1; i <= 4; i++) {
      final y = fieldSize.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(fieldSize.width, y), line);
    }

    // Helpers
    Offset? playerPos(String playerId) {
      for (final p in players) {
        if (p.id == playerId) return p.pos;
      }
      return null;
    }

    void drawPathSegments(
      Canvas canvas,
      List<Offset> points,
      Paint paint, {
      List<double>? pattern,
    }) {
      if (points.length < 2) return;

      if (pattern == null || pattern.isEmpty) {
        final path = Path()..moveTo(points.first.dx, points.first.dy);
        for (final p in points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
        return;
      }

      for (int i = 0; i < points.length - 1; i++) {
        final start = points[i];
        final end = points[i + 1];
        final vector = end - start;
        final length = vector.distance;
        if (length <= 0) continue;

        final direction = Offset(vector.dx / length, vector.dy / length);
        double distance = 0;
        int patternIndex = 0;

        while (distance < length) {
          final segmentLength = pattern[patternIndex % pattern.length];
          final nextDistance = (distance + segmentLength)
              .clamp(0.0, length)
              .toDouble();
          if (patternIndex.isEven) {
            final segmentStart = start + direction * distance;
            final segmentEnd = start + direction * nextDistance;
            canvas.drawLine(segmentStart, segmentEnd, paint);
          }
          distance = nextDistance;
          patternIndex++;
        }
      }
    }

    // Flecha (triángulo + colita)
    void drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
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

    void drawStopEnd(Canvas canvas, Offset from, Offset to, Paint paint) {
      final dir = to - from;
      final len = dir.distance;
      if (len < 1) return;

      final ux = dir.dx / len;
      final uy = dir.dy / len;
      final perp = Offset(-uy, ux);
      const stopHalf = 10.0;
      final left = to + perp * stopHalf;
      final right = to - perp * stopHalf;

      final stopPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = paint.strokeWidth;
      canvas.drawLine(left, right, stopPaint);
    }

    // ----- RUTAS GUARDADAS -----
    Paint routePaintFor(RouteEndType endType) => Paint()
      ..color = switch (endType) {
        RouteEndType.pitch => Colors.orangeAccent,
        RouteEndType.motion => Colors.lightBlueAccent,
        RouteEndType.adjustment => Colors.white70,
        _ => Colors.amberAccent.withValues(alpha: 0.9),
      }
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    List<double>? patternFor(RouteEndType endType) => switch (endType) {
      RouteEndType.motion => const [14, 10],
      RouteEndType.pitch => const [10, 8],
      RouteEndType.adjustment => const [3, 8],
      _ => null,
    };

    void drawRouteEnding(
      Canvas canvas,
      Offset from,
      Offset to,
      Paint paint,
      RouteEndType endType,
    ) {
      switch (endType) {
        case RouteEndType.arrow:
        case RouteEndType.motion:
        case RouteEndType.pitch:
        case RouteEndType.adjustment:
          drawArrow(canvas, from, to, paint);
          break;
        case RouteEndType.block:
          _drawBlockEnd(canvas, to, paint);
          break;
        case RouteEndType.stop:
          drawStopEnd(canvas, from, to, paint);
          break;
      }
    }

    routesByPlayer.forEach((playerId, list) {
      final currentPos = playerPos(playerId);
      if (currentPos == null) return;

      for (final r in list) {
        if (r.points.length < 2) continue;

        // puntos RELATIVOS -> mundo con token actual
        final worldPoints = r.points.map((rel) => currentPos + rel).toList();
        final routePaint = routePaintFor(r.endType);

        drawPathSegments(
          canvas,
          worldPoints,
          routePaint,
          pattern: patternFor(r.endType),
        );

        final a = worldPoints[worldPoints.length - 2];
        final b = worldPoints.last;
        drawRouteEnding(canvas, a, b, routePaint, r.endType);
      }
    });

    // ----- RUTA ACTIVA (PREVIEW) -----
    if (isDrawMode && activeRoutePoints.length >= 2) {
      final activePaint = routePaintFor(currentRouteType)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      drawPathSegments(
        canvas,
        activeRoutePoints,
        activePaint,
        pattern: patternFor(currentRouteType),
      );

      final a = activeRoutePoints[activeRoutePoints.length - 2];
      final b = activeRoutePoints.last;
      drawRouteEnding(canvas, a, b, activePaint, currentRouteType);
    }

    // ----- JUGADORES -----
    for (final p in players) {
      final isSelected = p.id == selectedPlayerId;
      final bool isThisDragging = isDragging && (p.id == draggingPlayerId);

      final double r = isThisDragging ? 32.0 : 18.0;

      final fill = Paint()
        ..color = isSelected ? Colors.white : Colors.blueAccent;

      final stroke = Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
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

      if (p.hasInfo) {
        final badgeCenter = p.pos + Offset(r * 0.72, -r * 0.72);
        final badgeFill = Paint()..color = Colors.amber.shade700;
        final badgeStroke = Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        canvas.drawCircle(badgeCenter, 8, badgeFill);
        canvas.drawCircle(badgeCenter, 8, badgeStroke);

        final infoPainter = TextPainter(
          text: const TextSpan(
            text: 'i',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        infoPainter.paint(
          canvas,
          badgeCenter - Offset(infoPainter.width / 2, infoPainter.height / 2),
        );
      }
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
        old.activeRoutePoints != activeRoutePoints ||
        old.currentRouteType != currentRouteType;
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
