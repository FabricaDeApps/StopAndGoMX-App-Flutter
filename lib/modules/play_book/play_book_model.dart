import 'dart:ui';

/// ------------------------------
/// Helpers para (de)serializar Offset
/// ------------------------------
Offset offsetFromJson(Map<String, dynamic> json) {
  final x = (json['x'] as num).toDouble();
  final y = (json['y'] as num).toDouble();
  return Offset(x, y);
}

Map<String, dynamic> offsetToJson(Offset o) => {'x': o.dx, 'y': o.dy};

/// ------------------------------
/// Player token (formación)
/// ------------------------------
class PlayerToken {
  final String id;
  final String name;
  final Offset pos;
  final bool isOffense;

  const PlayerToken({
    required this.id,
    required this.name,
    required this.pos,
    this.isOffense = true,
  });

  PlayerToken copyWith({
    String? id,
    String? name,
    Offset? pos,
    bool? isOffense,
  }) {
    return PlayerToken(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      isOffense: isOffense ?? this.isOffense,
    );
  }

  factory PlayerToken.fromJson(Map<String, dynamic> json) {
    return PlayerToken(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
      isOffense: (json['isOffense'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': pos.dx,
    'y': pos.dy,
    'isOffense': isOffense,
  };
}

/// ------------------------------
/// Ruta de un jugador (points RELATIVOS al origin)
/// ------------------------------
class PlayRoute {
  final String id;
  final String playerId;
  final Offset origin;
  final List<Offset> points;

  const PlayRoute({
    required this.id,
    required this.playerId,
    required this.origin,
    required this.points,
  });

  PlayRoute copyWith({
    String? id,
    String? playerId,
    Offset? origin,
    List<Offset>? points,
  }) {
    return PlayRoute(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      origin: origin ?? this.origin,
      points: points ?? this.points,
    );
  }

  factory PlayRoute.fromJson(Map<String, dynamic> json) {
    final originJson = (json['origin'] as Map<String, dynamic>);
    final pts = (json['points'] as List<dynamic>)
        .map((e) => offsetFromJson(e as Map<String, dynamic>))
        .toList();

    return PlayRoute(
      id: json['id'] as String,
      playerId: json['playerId'] as String,
      origin: offsetFromJson(originJson),
      points: pts,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'origin': offsetToJson(origin),
    'points': points.map(offsetToJson).toList(),
  };
}

/// ------------------------------
/// Jugada completa (PlaybookPlay)
/// ------------------------------
class PlaybookPlay {
  final String id;
  final String alias; // "Trips Right - Slant"
  final String type; // "Pase" | "Corrida" | "Defensa" (catálogo de strings)

  /// Formación completa
  final List<PlayerToken> players;

  /// Rutas por jugador: "wr1" -> [route1, route2...]
  final Map<String, List<PlayRoute>> routesByPlayer;

  const PlaybookPlay({
    required this.id,
    required this.alias,
    required this.type,
    required this.players,
    required this.routesByPlayer,
  });

  PlaybookPlay copyWith({
    String? id,
    String? alias,
    String? type,
    List<PlayerToken>? players,
    Map<String, List<PlayRoute>>? routesByPlayer,
  }) {
    return PlaybookPlay(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      type: type ?? this.type,
      players: players ?? this.players,
      routesByPlayer: routesByPlayer ?? this.routesByPlayer,
    );
  }

  factory PlaybookPlay.fromJson(Map<String, dynamic> json) {
    final playersJson = (json['players'] as List<dynamic>? ?? const [])
        .map((e) => PlayerToken.fromJson(e as Map<String, dynamic>))
        .toList();

    final rbpJson = (json['routesByPlayer'] as Map<String, dynamic>? ?? {});
    final rbp = <String, List<PlayRoute>>{};

    rbpJson.forEach((playerId, routesListDynamic) {
      final routesList = (routesListDynamic as List<dynamic>? ?? const []);
      rbp[playerId] = routesList
          .map((e) => PlayRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    return PlaybookPlay(
      id: json['id'] as String,
      alias: (json['alias'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'Pase',
      players: playersJson,
      routesByPlayer: rbp,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alias': alias,
    'type': type,
    'players': players.map((p) => p.toJson()).toList(),
    'routesByPlayer': routesByPlayer.map(
      (playerId, routes) =>
          MapEntry(playerId, routes.map((r) => r.toJson()).toList()),
    ),
  };
}
