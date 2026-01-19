import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';

class CombineMetricLeaderboardResponse {
  final CombineEvent event;
  final CombineMetric metric;
  final List<CombineLeaderboardEntry> leaderboard;

  CombineMetricLeaderboardResponse({
    required this.event,
    required this.metric,
    required this.leaderboard,
  });

  factory CombineMetricLeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return CombineMetricLeaderboardResponse(
      event: CombineEvent.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      metric: CombineMetric.fromJson(
        Map<String, dynamic>.from(json['metric'] as Map),
      ),
      leaderboard: ((json['leaderboard'] as List?) ?? const [])
          .map(
            (e) => CombineLeaderboardEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'event': event.toJson(),
    'metric': metric.toJson(),
    'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
  };
}

class CombineLeaderboardEntry {
  final int rank;
  final LeaderboardPlayerRef player;
  final double value;
  final String? unit;
  final DateTime? measuredAt; // viene "2026-01-20 18:22:00" (sin zona)

  CombineLeaderboardEntry({
    required this.rank,
    required this.player,
    required this.value,
    this.unit,
    this.measuredAt,
  });

  factory CombineLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final v = json['value'];

    return CombineLeaderboardEntry(
      rank: (json['rank'] as num).toInt(),
      player: LeaderboardPlayerRef.fromJson(
        Map<String, dynamic>.from(json['player'] as Map),
      ),
      value: v is num ? v.toDouble() : double.tryParse('$v') ?? 0.0,
      unit: json['unit']?.toString(),
      measuredAt: _parseMysqlLike(json['measured_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'player': player.toJson(),
    'value': value,
    'unit': unit,
    'measured_at': measuredAt?.toIso8601String(),
  };

  static DateTime? _parseMysqlLike(String? s) {
    if (s == null) return null;
    final t = s.trim();
    if (t.isEmpty) return null;

    // Soporta: "2026-01-20 18:22:00" o ISO
    // Si trae espacio, lo convertimos a ISO básico "YYYY-MM-DDTHH:mm:ss"
    final normalized = t.contains(' ') ? t.replaceFirst(' ', 'T') : t;

    return DateTime.tryParse(normalized);
  }
}

class LeaderboardPlayerRef {
  final int id;
  final String name;

  LeaderboardPlayerRef({required this.id, required this.name});

  factory LeaderboardPlayerRef.fromJson(Map<String, dynamic> json) {
    return LeaderboardPlayerRef(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
