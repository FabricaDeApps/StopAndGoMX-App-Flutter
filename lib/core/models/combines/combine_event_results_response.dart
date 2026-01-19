import 'package:stopandgo/core/models/combines/combine_event.dart';
import 'package:stopandgo/core/models/combines/combine_metric.dart';
import 'package:stopandgo/core/models/combines/combine_metric_leaderboard_response.dart';

class CombineEventResultsResponse {
  final CombineEvent event;
  final List<CombineEventResult> results;

  CombineEventResultsResponse({required this.event, required this.results});

  factory CombineEventResultsResponse.fromJson(Map<String, dynamic> json) {
    return CombineEventResultsResponse(
      event: CombineEvent.fromJson(
        Map<String, dynamic>.from(json['event'] as Map),
      ),
      results: ((json['results'] as List?) ?? const [])
          .map(
            (e) => CombineEventResult.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'event': event.toJson(),
    'results': results.map((e) => e.toJson()).toList(),
  };
}

class CombineEventResult {
  final int id;
  final int combineEventId;
  final LeaderboardPlayerRef player;
  final DateTime? measuredAt;
  final int? checkedBy;
  final String? notes;
  final double? overallScore;
  final List<CombineEventResultValue> values;

  CombineEventResult({
    required this.id,
    required this.combineEventId,
    required this.player,
    required this.measuredAt,
    required this.checkedBy,
    required this.notes,
    required this.overallScore,
    required this.values,
  });

  factory CombineEventResult.fromJson(Map<String, dynamic> json) {
    final os = json['overall_score'];
    return CombineEventResult(
      id: (json['id'] as num).toInt(),
      combineEventId: (json['combine_event_id'] as num).toInt(),
      player: LeaderboardPlayerRef.fromJson(
        Map<String, dynamic>.from(json['player'] as Map),
      ),
      measuredAt: DateTime.tryParse((json['measured_at'] ?? '').toString()),
      checkedBy: (json['checked_by'] as num?)?.toInt(),
      notes: json['notes']?.toString(),
      overallScore: os == null ? null : double.tryParse(os.toString()),
      values: ((json['values'] as List?) ?? const [])
          .map(
            (e) => CombineEventResultValue.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
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
    'values': values.map((e) => e.toJson()).toList(),
  };
}

class CombineEventResultValue {
  final CombineMetric metric; // tu modelo existente
  final double? valueNumber;
  final String? valueText;
  final Map<String, dynamic>? meta;

  CombineEventResultValue({
    required this.metric,
    required this.valueNumber,
    required this.valueText,
    required this.meta,
  });

  factory CombineEventResultValue.fromJson(Map<String, dynamic> json) {
    final vn = json['value_number'];
    return CombineEventResultValue(
      metric: CombineMetric.fromJson(
        Map<String, dynamic>.from(json['metric'] as Map),
      ),
      valueNumber: vn is num ? vn.toDouble() : double.tryParse('$vn'),
      valueText: json['value_text']?.toString(),
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'metric': metric.toJson(),
    'value_number': valueNumber,
    'value_text': valueText,
    'meta': meta,
  };
}
