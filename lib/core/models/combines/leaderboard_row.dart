import 'package:stopandgo/core/models/combines/combine_result.dart';

class LeaderboardRow {
  final int rank;
  final PlayerMini player;
  final double value;
  final String? unit;
  final DateTime? measuredAt;

  LeaderboardRow({
    required this.rank,
    required this.player,
    required this.value,
    required this.unit,
    required this.measuredAt,
  });

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      rank: (json['rank'] ?? 0) as int,
      player: PlayerMini.fromJson(
        (json['player'] ?? {}) as Map<String, dynamic>,
      ),
      value: double.tryParse('${json['value']}') ?? 0,
      unit: json['unit']?.toString(),
      measuredAt: DateTime.tryParse((json['measured_at'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'player': player.toJson(),
    'value': value,
    'unit': unit,
    'measured_at': measuredAt?.toIso8601String(),
  };
}
