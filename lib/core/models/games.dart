// lib/core/models/dto/game_dto.dart
class Game {
  final int id;
  final int organizationId;
  final int categoryId;

  final String opponent;
  final String? opponentCategory;
  final String? opponentNotes;

  final DateTime? startsAt;
  final int? durationMinutes;

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
  final String? evidence; // en payload viene como "evidece"
  final String? evidenceUrl; // "evidece_url"

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Game({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    required this.opponent,
    this.opponentCategory,
    this.opponentNotes,
    this.startsAt,
    this.durationMinutes,
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
    this.createdAt,
    this.updatedAt,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    double? _parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return Game(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      categoryId: (json['category_id'] ?? 0) as int,
      opponent: (json['opponent'] ?? '') as String,
      opponentCategory: json['opponent_category']?.toString(),
      opponentNotes: json['opponent_notes']?.toString(),
      startsAt: _parseDate(json['starts_at']?.toString()),
      durationMinutes: json['duration_minutes'] as int?,
      venue: json['venue']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      lat: _parseDouble(json['lat']),
      lng: _parseDouble(json['lng']),
      status: json['status']?.toString(),
      isFriendly: (json['is_friendly'] ?? false) as bool,
      season: json['season']?.toString(),
      homeScore: json['home_score'] as int?,
      opponentScore: json['opponent_score'] as int?,
      notes: json['notes']?.toString(),
      evidence: json['evidece']?.toString(), // ojo: backend lo manda con typo
      evidenceUrl: json['evidece_url']?.toString(), // idem
      createdAt: _parseDate(json['created_at']?.toString()),
      updatedAt: _parseDate(json['updated_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'category_id': categoryId,
    'opponent': opponent,
    'opponent_category': opponentCategory,
    'opponent_notes': opponentNotes,
    'starts_at': startsAt?.toIso8601String(),
    'duration_minutes': durationMinutes,
    'venue': venue,
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
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

List<Game> gameDtoListFromData(dynamic data) {
  final list = (data as List?) ?? const [];
  return list
      .map((e) => Game.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}
