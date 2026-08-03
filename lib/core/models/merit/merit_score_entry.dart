class MeritEnteredBy {
  final int id;
  final String name;

  const MeritEnteredBy({required this.id, required this.name});

  factory MeritEnteredBy.fromJson(Map<String, dynamic> json) {
    return MeritEnteredBy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class MeritScoreEntry {
  final int id;
  final int playerId;
  final int? categoryId;
  final int? seasonId;
  final String rubricCategory;
  final String rubricItem;
  final double points;
  final bool isExtraPoint;
  final DateTime? periodMonth;
  final MeritEnteredBy? enteredBy;
  final String? reason;
  final String? evidencePath;

  const MeritScoreEntry({
    required this.id,
    required this.playerId,
    this.categoryId,
    this.seasonId,
    required this.rubricCategory,
    required this.rubricItem,
    required this.points,
    required this.isExtraPoint,
    this.periodMonth,
    this.enteredBy,
    this.reason,
    this.evidencePath,
  });

  factory MeritScoreEntry.fromJson(Map<String, dynamic> json) {
    final rawEnteredBy = json['entered_by'];
    return MeritScoreEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      playerId: (json['player_id'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt(),
      seasonId: (json['season_id'] as num?)?.toInt(),
      rubricCategory: (json['rubric_category'] ?? '').toString(),
      rubricItem: (json['rubric_item'] ?? '').toString(),
      points: double.tryParse(json['points']?.toString() ?? '') ?? 0,
      isExtraPoint: (json['is_extra_point'] ?? false) == true,
      periodMonth: DateTime.tryParse(json['period_month']?.toString() ?? ''),
      enteredBy: rawEnteredBy is Map
          ? MeritEnteredBy.fromJson(Map<String, dynamic>.from(rawEnteredBy))
          : null,
      reason: json['reason']?.toString(),
      evidencePath: json['evidence_path']?.toString(),
    );
  }
}
