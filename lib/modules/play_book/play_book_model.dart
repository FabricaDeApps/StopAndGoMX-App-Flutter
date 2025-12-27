import 'dart:ui';

class PlayerToken {
  final String id;
  final String name;
  final Offset pos; // coordenadas del "mundo"
  final bool isOffense;

  const PlayerToken({
    required this.id,
    required this.name,
    required this.pos,
    this.isOffense = true,
  });

  PlayerToken copyWith({Offset? pos}) => PlayerToken(
    id: id,
    name: name,
    pos: pos ?? this.pos,
    isOffense: isOffense,
  );
}

class PlayRoute {
  final String id;
  final String playerId;

  /// Puntos en coordenadas del campo cuando se dibujó
  final List<Offset> points;

  /// Posición del token al momento de guardar/crear la ruta (ancla)
  final Offset originTokenPos;

  const PlayRoute({
    required this.id,
    required this.playerId,
    required this.points,
    required this.originTokenPos,
  });
}
