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
///

enum RouteEndType { arrow, block }

class PlayRoute {
  final String id;
  final String playerId;
  final Offset origin;
  final List<Offset> points;
  final RouteEndType endType;

  const PlayRoute({
    required this.id,
    required this.playerId,
    required this.origin,
    required this.points,
    this.endType = RouteEndType.arrow,
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
      endType: endType,
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
class PlaybookAttachment {
  final String url; // o key
  final String? name;
  final String? mimeType;
  final int? sizeBytes;

  const PlaybookAttachment({
    required this.url,
    this.name,
    this.mimeType,
    this.sizeBytes,
  });

  factory PlaybookAttachment.fromJson(Map<String, dynamic> json) {
    return PlaybookAttachment(
      url: (json['url'] as String?) ?? '',
      name: json['name'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: json['sizeBytes'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    if (name != null) 'name': name,
    if (mimeType != null) 'mimeType': mimeType,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
  };
}

class PlaybookPlay {
  final String id;
  final String alias;

  /// run/pass/blitz/coverage... (ideal: valores controlados)
  final String type;

  /// offense/defense
  final String side;

  /// go/attachment
  final String mode;

  /// Para mostrar rápido sin cargar players (y para attachment)
  final int playersCount;

  /// Solo para modo GO
  final List<PlayerToken> players;

  /// Solo para modo GO
  final Map<String, List<PlayRoute>> routesByPlayer;

  /// Solo para modo attachment
  final PlaybookAttachment? attachment;

  const PlaybookPlay({
    required this.id,
    required this.alias,
    required this.type,
    required this.side,
    required this.mode,
    required this.playersCount,
    this.players = const [],
    this.routesByPlayer = const {},
    this.attachment,
  });

  bool get isGo => mode == 'go' || mode == 'playbook_go';
  bool get isAttachment => mode == 'attachment';

  PlaybookPlay copyWith({
    String? id,
    String? alias,
    String? type,
    String? side,
    String? mode,
    int? playersCount,
    List<PlayerToken>? players,
    Map<String, List<PlayRoute>>? routesByPlayer,
    PlaybookAttachment? attachment,
  }) {
    return PlaybookPlay(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      type: type ?? this.type,
      side: side ?? this.side,
      mode: mode ?? this.mode,
      playersCount: playersCount ?? this.playersCount,
      players: players ?? this.players,
      routesByPlayer: routesByPlayer ?? this.routesByPlayer,
      attachment: attachment ?? this.attachment,
    );
  }

  factory PlaybookPlay.fromJson(Map<String, dynamic> json) {
    // ---- players: siempre lista o vacío
    final playersRaw = json['players'];
    final playersList = (playersRaw is List) ? playersRaw : const [];
    final playersJson = playersList
        .map((e) => PlayerToken.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    // ---- routesByPlayer: puede venir Map (GO) o [] (attachment) -> normalizamos a {}
    final rawRoutes = json['routesByPlayer'];

    final Map<String, dynamic> rbpJson = (rawRoutes is Map)
        ? Map<String, dynamic>.from(rawRoutes as Map)
        : <String, dynamic>{};

    final rbp = <String, List<PlayRoute>>{};
    rbpJson.forEach((playerId, routesListDynamic) {
      final routesList = (routesListDynamic is List)
          ? routesListDynamic
          : const [];
      rbp[playerId.toString()] = routesList
          .map((e) => PlayRoute.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    });

    // ---- attachment (puede ser null o map)
    final attachmentRaw = json['attachment'];
    final attachmentJson = attachmentRaw is Map
        ? Map<String, dynamic>.from(attachmentRaw as Map)
        : null;

    // ---- mode (compat)
    final inferredMode =
        (json['mode'] as String?) ??
        ((playersJson.isNotEmpty || rbp.isNotEmpty) ? 'go' : 'attachment');

    // ---- playersCount (puede venir int o string)
    final pcRaw = json['playersCount'];
    final inferredPlayersCount = (pcRaw is int)
        ? pcRaw
        : int.tryParse(pcRaw?.toString() ?? '') ??
              (playersJson.isNotEmpty ? playersJson.length : 0);

    return PlaybookPlay(
      id: json['id']?.toString() ?? '',
      alias: (json['alias'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'pass',
      side: (json['side'] as String?) ?? 'offense',
      mode: inferredMode,
      playersCount: inferredPlayersCount,
      players: playersJson,
      routesByPlayer: rbp,
      attachment: attachmentJson == null
          ? null
          : PlaybookAttachment.fromJson(attachmentJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alias': alias,
    'type': type,
    'side': side,
    'mode': mode,
    'playersCount': playersCount,
    // Solo manda players/rutas cuando es GO (si quieres)
    if (isGo) 'players': players.map((p) => p.toJson()).toList(),
    if (isGo)
      'routesByPlayer': routesByPlayer.map(
        (playerId, routes) =>
            MapEntry(playerId, routes.map((r) => r.toJson()).toList()),
      ),
    if (isAttachment && attachment != null) 'attachment': attachment!.toJson(),
  };
}
