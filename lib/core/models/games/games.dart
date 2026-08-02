// lib/core/models/dto/game_dto.dart

class Venue {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final double? lat;
  final double? lng;
  final String? notes;
  final bool? isActive;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Venue({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.country,
    this.lat,
    this.lng,
    this.notes,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic s) {
      final str = s?.toString();
      if (str == null || str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Venue(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      country: json['country']?.toString(),
      lat: parseDouble(json['lat']),
      lng: parseDouble(json['lng']),
      notes: json['notes']?.toString(),
      isActive: json['is_active'] as bool?,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      deletedAt: parseDate(json['deleted_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'state': state,
    'country': country,
    'lat': lat,
    'lng': lng,
    'notes': notes,
    'is_active': isActive,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
  };
}

class Game {
  final int id;
  final int organizationId;
  final int categoryId;
  final String? categoryName;

  final String opponent;
  final String? opponentCategory;
  final String? opponentNotes;

  final DateTime? startsAt;
  final int? durationMinutes;

  final Venue? venueObj;
  final int? venueId;
  final String? venue;

  final String? address;
  final String? city;

  final double? lat;
  final double? lng;

  final String? status;
  final bool isFriendly;
  final String? season;

  final int? homeScore;
  final int? opponentScore;

  final String? notes;
  final String? evidence; // backend: "evidece"
  final String? evidenceUrl; // "evidece_url"

  // ===== LIVE / STREAMING =====
  final String? liveStatus; // 'live' | 'replay' | null
  final bool? canWatchLive; // true | false | null
  final int? liveEventId; // último live_event.id
  final String? livePlayUrl; // HLS o WebRTC playback

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<String> images; // urls

  final int likesCount;
  final bool isLikedByMe;

  Game({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    this.categoryName,
    required this.opponent,
    this.opponentCategory,
    this.opponentNotes,
    this.startsAt,
    this.durationMinutes,
    this.venueObj,
    this.venueId,
    this.venue,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.status,
    required this.isFriendly,
    this.season,
    this.homeScore,
    this.opponentScore,
    this.notes,
    this.evidence,
    this.evidenceUrl,

    // 👇 nuevos
    this.liveStatus,
    this.canWatchLive,
    this.liveEventId,
    this.livePlayUrl,

    this.createdAt,
    this.updatedAt,
    this.images = const [],
    this.likesCount = 0,
    this.isLikedByMe = false,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic s) {
      final str = s?.toString();
      if (str == null || str.isEmpty) return null;
      return DateTime.tryParse(str);
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    // venue puede venir como:
    // - Map => venueObj
    // - String => venue (legacy)
    // - null
    Venue? venueObj;
    int? venueId;
    String? venueName;

    final v = json['venue'];
    if (v is Map) {
      final map = Map<String, dynamic>.from(v);
      venueObj = Venue.fromJson(map);
      venueId = (map['id'] as num?)?.toInt();
      venueName = map['name']?.toString();
    } else if (v != null) {
      venueName = v.toString();
    }

    // Si el backend también manda venue_id separado, lo respetamos
    venueId ??= (json['venue_id'] as num?)?.toInt();

    // address/city/lat/lng: prioriza venueObj si existe
    final resolvedAddress = venueObj?.address ?? json['address']?.toString();
    final resolvedCity = venueObj?.city ?? json['city']?.toString();
    final resolvedLat = venueObj?.lat ?? parseDouble(json['lat']);
    final resolvedLng = venueObj?.lng ?? parseDouble(json['lng']);

    return Game(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      categoryId: (json['category_id'] ?? 0) as int,
      categoryName: json['category_name']?.toString(),
      opponent: (json['opponent_name'] ?? json['opponent'] ?? '') as String,
      opponentCategory: json['opponent_category']?.toString(),
      opponentNotes: json['opponent_notes']?.toString(),
      startsAt: parseDate(json['starts_at']),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      venueObj: venueObj,
      venueId: venueId,
      venue: venueName,
      address: resolvedAddress,
      city: resolvedCity,
      lat: resolvedLat,
      lng: resolvedLng,
      status: json['status']?.toString(),
      isFriendly: (json['is_friendly'] ?? false) as bool,
      season: json['season']?.toString(),
      homeScore: (json['home_score'] as num?)?.toInt(),
      opponentScore: (json['opponent_score'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      evidence: json['evidece']?.toString(),
      evidenceUrl: json['evidece_url']?.toString(),

      // ===== LIVE =====
      liveStatus: json['live_status']?.toString(),
      canWatchLive: json['can_watch_live'] as bool?,
      liveEventId: (json['live_event_id'] as num?)?.toInt(),
      livePlayUrl: json['live_play_url']?.toString(),

      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),

      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ??
          const [],

      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      isLikedByMe: (json['is_liked_by_me'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'category_id': categoryId,
    'category_name': categoryName,
    'opponent': opponent,
    'opponent_category': opponentCategory,
    'opponent_notes': opponentNotes,
    'starts_at': startsAt?.toIso8601String(),
    'duration_minutes': durationMinutes,
    'venue_id': venueId,
    'venue': venueObj?.toJson() ?? venue,
    'address': address,
    'city': city,
    'lat': lat,
    'lng': lng,
    'status': status,
    'is_friendly': isFriendly,
    'season': season,
    'home_score': homeScore,
    'opponent_score': opponentScore,
    'notes': notes,
    'evidece': evidence,
    'evidece_url': evidenceUrl,

    // live (solo lectura normalmente)
    'live_status': liveStatus,
    'can_watch_live': canWatchLive,
    'live_event_id': liveEventId,
    'live_play_url': livePlayUrl,

    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'likes_count': likesCount,
    'is_liked_by_me': isLikedByMe,
  };

  // ===== Helpers útiles para UI =====
  bool get hasLive => canWatchLive == true && liveEventId != null;
  bool get isLiveNow => liveStatus == 'live';
  bool get isReplay => liveStatus == 'replay';
  bool get isFinished => liveStatus == 'finished';
}

List<Game> gameDtoListFromData(dynamic data) {
  final list = (data as List?) ?? const [];
  return list
      .map((e) => Game.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
