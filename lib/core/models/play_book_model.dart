import 'dart:ui';

const Object _unset = Object();

/// ------------------------------
/// Helpers para (de)serializar Offset
/// ------------------------------
Offset offsetFromJson(Map<String, dynamic> json) {
  final x = (json['x'] as num).toDouble();
  final y = (json['y'] as num).toDouble();
  return Offset(x, y);
}

Map<String, dynamic> offsetToJson(Offset o) => {'x': o.dx, 'y': o.dy};

DateTime? _dateTimeFromJson(dynamic raw) {
  final value = raw?.toString().trim();
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int? _intFromJson(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}

/// ------------------------------
/// Player token (formación)
/// ------------------------------
class PlayerToken {
  final String id;
  final String name;
  final Offset pos;
  final bool isOffense;
  final String? infoText;
  final bool hasInfo;

  const PlayerToken({
    required this.id,
    required this.name,
    required this.pos,
    this.isOffense = true,
    this.infoText,
    this.hasInfo = false,
  });

  PlayerToken copyWith({
    String? id,
    String? name,
    Offset? pos,
    bool? isOffense,
    Object? infoText = _unset,
    bool? hasInfo,
  }) {
    return PlayerToken(
      id: id ?? this.id,
      name: name ?? this.name,
      pos: pos ?? this.pos,
      isOffense: isOffense ?? this.isOffense,
      infoText: identical(infoText, _unset) ? this.infoText : infoText as String?,
      hasInfo: hasInfo ?? this.hasInfo,
    );
  }

  factory PlayerToken.fromJson(Map<String, dynamic> json) {
    final info = json['infoText']?.toString();
    final normalizedInfo = info?.trim().isEmpty == true ? null : info?.trim();
    return PlayerToken(
      id: json['id'] as String,
      name: json['name'] as String,
      pos: Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble()),
      isOffense:
          (json['isOffense'] as bool?) ?? (json['is_offense'] as bool?) ?? true,
      infoText: normalizedInfo,
      hasInfo: (json['hasInfo'] as bool?) ??
          (json['has_info'] as bool?) ??
          (normalizedInfo != null && normalizedInfo.isNotEmpty),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'x': pos.dx,
    'y': pos.dy,
    'isOffense': isOffense,
    'infoText': infoText,
    'hasInfo': hasInfo,
  };
}

class PlaybookLikeUser {
  final int? id;
  final String name;
  final String? role;
  final String? profilePhotoUrl;
  final DateTime? likedAt;

  const PlaybookLikeUser({
    this.id,
    required this.name,
    this.role,
    this.profilePhotoUrl,
    this.likedAt,
  });

  factory PlaybookLikeUser.fromJson(Map<String, dynamic> json) {
    return PlaybookLikeUser(
      id: _intFromJson(json['id']),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Sin nombre',
      role: json['role']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
      likedAt: _dateTimeFromJson(json['liked_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (role != null) 'role': role,
    if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
    if (likedAt != null) 'liked_at': likedAt!.toIso8601String(),
  };
}

class PlaybookLikes {
  final int count;
  final bool isLiked;
  final List<PlaybookLikeUser> users;

  const PlaybookLikes({
    this.count = 0,
    this.isLiked = false,
    this.users = const [],
  });

  PlaybookLikes copyWith({
    int? count,
    bool? isLiked,
    List<PlaybookLikeUser>? users,
  }) {
    return PlaybookLikes(
      count: count ?? this.count,
      isLiked: isLiked ?? this.isLiked,
      users: users ?? this.users,
    );
  }

  factory PlaybookLikes.fromJson(Map<String, dynamic> json) {
    final usersRaw = (json['users'] as List?) ?? const [];
    return PlaybookLikes(
      count: _intFromJson(json['count']) ?? 0,
      isLiked: json['is_liked'] == true || json['isLiked'] == true,
      users: usersRaw
          .whereType<Map>()
          .map((e) => PlaybookLikeUser.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'is_liked': isLiked,
    'users': users.map((e) => e.toJson()).toList(),
  };
}

/// ------------------------------
/// Ruta de un jugador (points RELATIVOS al origin)
/// ------------------------------
///

enum RouteEndType { arrow, block, stop, motion, pitch, adjustment }

RouteEndType routeEndTypeFromJson(dynamic raw) {
  final value = raw?.toString().trim().toLowerCase();
  switch (value) {
    case 'block':
      return RouteEndType.block;
    case 'stop':
      return RouteEndType.stop;
    case 'motion':
      return RouteEndType.motion;
    case 'pitch':
      return RouteEndType.pitch;
    case 'adjustment':
      return RouteEndType.adjustment;
    case 'arrow':
    default:
      return RouteEndType.arrow;
  }
}

String routeEndTypeToJson(RouteEndType endType) {
  switch (endType) {
    case RouteEndType.block:
      return 'block';
    case RouteEndType.stop:
      return 'stop';
    case RouteEndType.motion:
      return 'motion';
    case RouteEndType.pitch:
      return 'pitch';
    case RouteEndType.adjustment:
      return 'adjustment';
    case RouteEndType.arrow:
      return 'arrow';
  }
}

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
    RouteEndType? endType,
  }) {
    return PlayRoute(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      origin: origin ?? this.origin,
      points: points ?? this.points,
      endType: endType ?? this.endType,
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
      endType: routeEndTypeFromJson(json['endType']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'origin': offsetToJson(origin),
    'points': points.map(offsetToJson).toList(),
    'endType': routeEndTypeToJson(endType),
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
  final String? kind;

  const PlaybookAttachment({
    required this.url,
    this.name,
    this.mimeType,
    this.sizeBytes,
    this.kind,
  });

  factory PlaybookAttachment.fromJson(Map<String, dynamic> json) {
    return PlaybookAttachment(
      url: (json['url'] as String?) ?? '',
      name: json['name'] as String?,
      mimeType: json['mimeType'] as String?,
      sizeBytes: _intFromJson(json['sizeBytes']),
      kind: json['kind']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    if (name != null) 'name': name,
    if (mimeType != null) 'mimeType': mimeType,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
    if (kind != null) 'kind': kind,
  };
}

class PlaybookCategoryRef {
  final int id;
  final String name;
  final String? code;
  final String? slug;

  const PlaybookCategoryRef({
    required this.id,
    required this.name,
    this.code,
    this.slug,
  });

  factory PlaybookCategoryRef.fromJson(Map<String, dynamic> json) {
    return PlaybookCategoryRef(
      id: _intFromJson(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (code != null) 'code': code,
    if (slug != null) 'slug': slug,
  };
}

class PlaybookFeedbackAuthor {
  final int? id;
  final String name;
  final String? role;
  final String? profilePhotoUrl;

  const PlaybookFeedbackAuthor({
    this.id,
    required this.name,
    this.role,
    this.profilePhotoUrl,
  });

  factory PlaybookFeedbackAuthor.fromJson(Map<String, dynamic> json) {
    return PlaybookFeedbackAuthor(
      id: _intFromJson(json['id']),
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'Sin nombre',
      role: json['role']?.toString(),
      profilePhotoUrl: json['profile_photo_url']?.toString(),
    );
  }
}

class PlaybookFeedback {
  final int id;
  final String playId;
  final int? categoryId;
  final String? categoryName;
  final String authorName;
  final PlaybookFeedbackAuthor? author;
  final String message;
  final PlaybookAttachment? attachment;
  final bool canDelete;
  final DateTime? createdAt;

  const PlaybookFeedback({
    required this.id,
    required this.playId,
    this.categoryId,
    this.categoryName,
    required this.authorName,
    this.author,
    required this.message,
    this.attachment,
    required this.canDelete,
    this.createdAt,
  });

  factory PlaybookFeedback.fromJson(Map<String, dynamic> json) {
    final authorRaw = json['author'];
    final attachmentRaw = json['attachment'];

    return PlaybookFeedback(
      id: _intFromJson(json['id']) ?? 0,
      playId: json['play_id']?.toString() ?? '',
      categoryId: _intFromJson(json['category_id']),
      categoryName: json['category_name']?.toString(),
      authorName: (json['author_name']?.toString().trim().isNotEmpty == true)
          ? json['author_name'].toString().trim()
          : (authorRaw is Map
                ? (authorRaw['name']?.toString().trim().isNotEmpty == true
                      ? authorRaw['name'].toString().trim()
                      : 'Sin autor')
                : 'Sin autor'),
      author: authorRaw is Map
          ? PlaybookFeedbackAuthor.fromJson(Map<String, dynamic>.from(authorRaw))
          : null,
      message: json['message']?.toString() ?? '',
      attachment: attachmentRaw is Map
          ? PlaybookAttachment.fromJson(
              Map<String, dynamic>.from(attachmentRaw),
            )
          : null,
      canDelete: json['can_delete'] == true,
      createdAt: _dateTimeFromJson(json['created_at']),
    );
  }
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
  final int? categoryId;
  final PlaybookCategoryRef? category;
  final List<PlaybookCategoryRef> sharedCategories;
  final String? notes;
  final PlaybookLikes likes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.categoryId,
    this.category,
    this.sharedCategories = const [],
    this.notes,
    this.likes = const PlaybookLikes(),
    this.createdAt,
    this.updatedAt,
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
    int? categoryId,
    PlaybookCategoryRef? category,
    List<PlaybookCategoryRef>? sharedCategories,
    String? notes,
    PlaybookLikes? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      sharedCategories: sharedCategories ?? this.sharedCategories,
      notes: notes ?? this.notes,
      likes: likes ?? this.likes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
        ? Map<String, dynamic>.from(rawRoutes)
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
        ? Map<String, dynamic>.from(attachmentRaw)
        : null;
    final categoryRaw = json['category'];
    final categoryJson = categoryRaw is Map
        ? Map<String, dynamic>.from(categoryRaw)
        : null;
    final sharedCategoriesRaw = (json['shared_categories'] as List?) ?? const [];
    final sharedCategories = sharedCategoriesRaw
        .whereType<Map>()
        .map((e) => PlaybookCategoryRef.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final likesRaw = json['likes'];
    final likesJson = likesRaw is Map ? Map<String, dynamic>.from(likesRaw) : null;

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
      categoryId: _intFromJson(json['category_id']),
      category: categoryJson == null
          ? null
          : PlaybookCategoryRef.fromJson(categoryJson),
      sharedCategories: sharedCategories,
      notes: json['notes']?.toString(),
      likes: likesJson == null
          ? const PlaybookLikes()
          : PlaybookLikes.fromJson(likesJson),
      createdAt: _dateTimeFromJson(json['created_at']),
      updatedAt: _dateTimeFromJson(json['updated_at']),
    );
  }

  bool isOwnedByCategory(int? selectedCategoryId) {
    if (selectedCategoryId == null || categoryId == null) return false;
    return categoryId == selectedCategoryId;
  }

  bool isSharedWithCategory(int? selectedCategoryId) {
    if (selectedCategoryId == null) return false;
    return sharedCategories.any((e) => e.id == selectedCategoryId);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'alias': alias,
    'type': type,
    'side': side,
    'mode': mode,
    'playersCount': playersCount,
    if (categoryId != null) 'category_id': categoryId,
    if (category != null) 'category': category!.toJson(),
    if (sharedCategories.isNotEmpty)
      'shared_categories': sharedCategories.map((e) => e.toJson()).toList(),
    if (notes != null) 'notes': notes,
    'likes': likes.toJson(),
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
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
