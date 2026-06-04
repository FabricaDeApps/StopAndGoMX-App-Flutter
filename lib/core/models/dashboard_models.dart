import 'package:stopandgo/core/models/attendance_dashboard.dart';
import 'package:stopandgo/core/models/games/games.dart';

/// --------- MODELOS COMPARTIDOS ---------

class DashboardNotice {
  final int id;
  final int organizationId;
  final int? userId;
  final String title;
  final String? message;
  final int? categoryId;
  final String? image;
  final String? attachment;
  final String? externalUrl;
  final bool isPublished;
  final bool pinned;
  final DateTime? publishedAt;
  final DateTime? pushSentAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DashboardNotice({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.categoryId,
    required this.image,
    required this.attachment,
    required this.externalUrl,
    required this.isPublished,
    required this.pinned,
    required this.publishedAt,
    required this.pushSentAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DashboardNotice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? value) =>
        (value == null) ? null : DateTime.parse(value);

    return DashboardNotice(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      userId: json['user_id'] as int?,
      title: json['title'] as String,
      message: json['message'] as String?,
      categoryId: json['category_id'] as int?,
      image: json['image'] as String?,
      attachment: json['attachment'] as String?,
      externalUrl: json['external_url'] as String?,
      isPublished: json['is_published'] == true || json['is_published'] == 1,
      pinned: json['pinned'] == true || json['pinned'] == 1,
      publishedAt: parseDate(json['published_at'] as String?),
      pushSentAt: parseDate(json['push_sent_at'] as String?),
      expiresAt: parseDate(json['expires_at'] as String?),
      createdAt: parseDate(json['created_at'] as String?),
      updatedAt: parseDate(json['updated_at'] as String?),
    );
  }
}

/// --------- MANAGER ---------

class ManagerDashboardCategory {
  final int id;
  final String name;
  final int playersCount;

  ManagerDashboardCategory({
    required this.id,
    required this.name,
    required this.playersCount,
  });

  factory ManagerDashboardCategory.fromJson(Map<String, dynamic> json) {
    return ManagerDashboardCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      playersCount: json['players_count'] as int,
    );
  }
}

class ManagerDashboardResponse {
  final String role;
  final List<Game> nextGames;
  final List<ManagerDashboardCategory> categories;

  /// Lista completa de avisos (nuevo)
  final List<DashboardNotice> notices;

  /// Compat: antes venía como objeto
  final DashboardNotice? lastNotice;

  ManagerDashboardResponse({
    required this.role,
    required this.nextGames,
    required this.categories,
    required this.notices,
    required this.lastNotice,
  });

  factory ManagerDashboardResponse.fromJson(Map<String, dynamic> json) {
    final nextGamesJson = (json['next_games'] as List?) ?? const [];
    final categoriesJson = (json['categories'] as List?) ?? const [];
    final noticesJson = (json['notices'] as List?) ?? const [];

    // 1) Parse lista notices (nuevo)
    final parsedNotices = noticesJson
        .whereType<Map>()
        .map((e) => DashboardNotice.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // 2) Compat last_notice si viene
    DashboardNotice? parsedLastNotice;
    final rawLast = json['last_notice'];
    if (rawLast is Map) {
      parsedLastNotice = DashboardNotice.fromJson(
        Map<String, dynamic>.from(rawLast),
      );
    } else if (parsedNotices.isNotEmpty) {
      // 3) Si no viene last_notice, usamos el primero de notices (ya viene ordenado desc)
      parsedLastNotice = parsedNotices.first;
    }

    return ManagerDashboardResponse(
      role: (json['role'] ?? '') as String,
      nextGames: nextGamesJson
          .whereType<Map>()
          .map((e) => Game.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      categories: categoriesJson
          .whereType<Map>()
          .map(
            (e) =>
                ManagerDashboardCategory.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      notices: parsedNotices,
      lastNotice: parsedLastNotice,
    );
  }
}

/// --------- PLAYER ---------

class PlayerDashboardCategory {
  final int id;
  final String name;
  final Game? nextGame;

  PlayerDashboardCategory({
    required this.id,
    required this.name,
    required this.nextGame,
  });

  factory PlayerDashboardCategory.fromJson(Map<String, dynamic> json) {
    return PlayerDashboardCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      nextGame: json['next_game'] != null
          ? Game.fromJson(json['next_game'] as Map<String, dynamic>)
          : null,
    );
  }
}

class PlayerDashboardResponse {
  final String role;
  final int playerId;
  final List<PlayerDashboardCategory> categories;
  final double pendingTotal;
  final DashboardNotice? lastNotice;
  final AttendanceDashboard attendance;

  PlayerDashboardResponse({
    required this.role,
    required this.playerId,
    required this.categories,
    required this.pendingTotal,
    required this.lastNotice,
    required this.attendance,
  });

  factory PlayerDashboardResponse.fromJson(Map<String, dynamic> json) {
    final catsJson = (json['categories'] as List<dynamic>? ?? []);

    return PlayerDashboardResponse(
      role: json['role'] as String,
      playerId: json['player_id'] as int,
      categories: catsJson
          .map(
            (e) => PlayerDashboardCategory.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      pendingTotal: (json['pending_total'] as num?)?.toDouble() ?? 0.0,
      lastNotice: json['last_notice'] != null
          ? DashboardNotice.fromJson(
              json['last_notice'] as Map<String, dynamic>,
            )
          : null,
      attendance: json['attendance'] != null
          ? AttendanceDashboard.fromJson(
              json['attendance'] as Map<String, dynamic>,
            )
          : AttendanceDashboard.empty,
    );
  }
}

/// --------- PARENT ---------

class ParentDashboardChild {
  final int playerId;
  final String playerName;
  final List<Game> upcomingGames;

  ParentDashboardChild({
    required this.playerId,
    required this.playerName,
    required this.upcomingGames,
  });

  factory ParentDashboardChild.fromJson(Map<String, dynamic> json) {
    final gamesJson = (json['upcoming_games'] as List<dynamic>? ?? []);

    return ParentDashboardChild(
      playerId: json['player_id'] as int,
      playerName: json['player_name'] as String? ?? '',
      upcomingGames: gamesJson
          .map((e) => Game.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ParentDashboardResponse {
  final String role; // "parent"
  final List<ParentDashboardChild> children;
  final double pendingTotal;
  final DashboardNotice? lastNotice;

  ParentDashboardResponse({
    required this.role,
    required this.children,
    required this.pendingTotal,
    required this.lastNotice,
  });

  factory ParentDashboardResponse.fromJson(Map<String, dynamic> json) {
    final childrenJson = (json['children'] as List<dynamic>? ?? []);

    return ParentDashboardResponse(
      role: json['role'] as String,
      children: childrenJson
          .map((e) => ParentDashboardChild.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingTotal: (json['pending_total'] as num?)?.toDouble() ?? 0.0,
      lastNotice: json['last_notice'] != null
          ? DashboardNotice.fromJson(
              json['last_notice'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class StaffDashboard {
  final List<Game> upcomingGames;
  final DashboardNotice? lastNotice;

  StaffDashboard({required this.upcomingGames, required this.lastNotice});

  factory StaffDashboard.fromJson(Map<String, dynamic> json) {
    final gamesJson = (json['upcomingGames'] as List<dynamic>? ?? []);

    return StaffDashboard(
      upcomingGames: gamesJson
          .map((e) => Game.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastNotice: json['last_notice'] != null
          ? DashboardNotice.fromJson(
              json['last_notice'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}
