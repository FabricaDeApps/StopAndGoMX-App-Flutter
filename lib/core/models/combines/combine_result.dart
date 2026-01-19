import 'package:stopandgo/core/models/combines/combine_value.dart';

class CombineResult {
  final int id;
  final int combineEventId;

  final PlayerMini player;
  final DateTime? measuredAt;
  final int? checkedBy;
  final String? notes;
  final double? overallScore;

  // En algunos endpoints viene event, en otros viene null
  final EventMini? event;

  final List<CombineValue> values;

  CombineResult({
    required this.id,
    required this.combineEventId,
    required this.player,
    required this.measuredAt,
    required this.checkedBy,
    required this.notes,
    required this.overallScore,
    required this.event,
    required this.values,
  });

  factory CombineResult.fromJson(Map<String, dynamic> json) {
    return CombineResult(
      id: (json['id'] ?? 0) as int,
      combineEventId: (json['combine_event_id'] ?? 0) as int,
      player: PlayerMini.fromJson(
        (json['player'] ?? {}) as Map<String, dynamic>,
      ),
      measuredAt: DateTime.tryParse((json['measured_at'] ?? '').toString()),
      checkedBy: json['checked_by'] is int
          ? json['checked_by'] as int
          : int.tryParse('${json['checked_by']}'),
      notes: json['notes']?.toString(),
      overallScore: json['overall_score'] == null
          ? null
          : double.tryParse('${json['overall_score']}'),
      event: json['event'] == null
          ? null
          : EventMini.fromJson(json['event'] as Map<String, dynamic>),
      values: ((json['values'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => CombineValue.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'combine_event_id': combineEventId,
    'player': player.toJson(),
    'measured_at': measuredAt?.toIso8601String(),
    'checked_by': checkedBy,
    'notes': notes,
    'overall_score': overallScore,
    'event': event?.toJson(),
    'values': values.map((v) => v.toJson()).toList(),
  };
}

class PlayerMini {
  final int id;
  final String? name;

  PlayerMini({required this.id, required this.name});

  factory PlayerMini.fromJson(Map<String, dynamic> json) =>
      PlayerMini(id: (json['id'] ?? 0) as int, name: json['name']?.toString());

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class EventMini {
  final int id;
  final String? name;
  final int? categoryId;
  final int? seasonId;
  final int? venueId;
  final DateTime? startsAt;
  final DateTime? endsAt;

  EventMini({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.seasonId,
    required this.venueId,
    required this.startsAt,
    required this.endsAt,
  });

  factory EventMini.fromJson(Map<String, dynamic> json) => EventMini(
    id: (json['id'] ?? 0) as int,
    name: json['name']?.toString(),
    categoryId: json['category_id'] is int
        ? json['category_id'] as int
        : int.tryParse('${json['category_id']}'),
    seasonId: json['season_id'] is int
        ? json['season_id'] as int
        : int.tryParse('${json['season_id']}'),
    venueId: json['venue_id'] is int
        ? json['venue_id'] as int
        : int.tryParse('${json['venue_id']}'),
    startsAt: DateTime.tryParse((json['starts_at'] ?? '').toString()),
    endsAt: DateTime.tryParse((json['ends_at'] ?? '').toString()),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category_id': categoryId,
    'season_id': seasonId,
    'venue_id': venueId,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
  };
}
