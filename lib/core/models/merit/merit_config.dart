class MeritLevelThreshold {
  final String name;
  final int min;
  final int max;
  final double participationWeight;

  const MeritLevelThreshold({
    required this.name,
    required this.min,
    required this.max,
    required this.participationWeight,
  });

  factory MeritLevelThreshold.fromJson(Map<String, dynamic> json) {
    return MeritLevelThreshold(
      name: (json['name'] ?? '').toString(),
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
      participationWeight:
          (json['participation_weight'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MeritRubricItem {
  final String total;
  final Map<String, num> items;
  final num? extraMax;

  const MeritRubricItem({
    required this.total,
    required this.items,
    this.extraMax,
  });

  factory MeritRubricItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return MeritRubricItem(
      total: (json['total'] ?? '').toString(),
      items: rawItems is Map
          ? rawItems.map(
              (k, v) => MapEntry(k.toString(), (v as num?) ?? 0),
            )
          : const <String, num>{},
      extraMax: json['extra_max'] as num?,
    );
  }
}

class MeritConfig {
  final int? id;
  final int organizationId;
  final int? seasonId;
  final double fundPercentage;
  final int minScoreToParticipate;
  final int maxBaseScore;
  final String distributionModel;
  final List<MeritLevelThreshold> levelThresholds;
  final Map<String, MeritRubricItem> rubricWeights;
  final int cutoffDayOfMonth;
  final double coachMinAttendancePercentage;
  final bool isActive;
  final bool isDefault;

  const MeritConfig({
    this.id,
    required this.organizationId,
    this.seasonId,
    required this.fundPercentage,
    required this.minScoreToParticipate,
    required this.maxBaseScore,
    required this.distributionModel,
    required this.levelThresholds,
    required this.rubricWeights,
    required this.cutoffDayOfMonth,
    required this.coachMinAttendancePercentage,
    required this.isActive,
    required this.isDefault,
  });

  factory MeritConfig.fromJson(
    Map<String, dynamic> json, {
    bool isDefault = false,
  }) {
    final rawThresholds = json['level_thresholds'];
    final rawRubric = json['rubric_weights'];

    return MeritConfig(
      id: (json['id'] as num?)?.toInt(),
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      seasonId: (json['season_id'] as num?)?.toInt(),
      fundPercentage:
          double.tryParse(json['fund_percentage']?.toString() ?? '') ?? 15,
      minScoreToParticipate:
          (json['min_score_to_participate'] as num?)?.toInt() ?? 80,
      maxBaseScore: (json['max_base_score'] as num?)?.toInt() ?? 100,
      distributionModel: (json['distribution_model'] ?? 'equal').toString(),
      levelThresholds: rawThresholds is List
          ? rawThresholds
              .whereType<Map>()
              .map(
                (e) =>
                    MeritLevelThreshold.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const <MeritLevelThreshold>[],
      rubricWeights: rawRubric is Map
          ? rawRubric.map(
              (k, v) => MapEntry(
                k.toString(),
                MeritRubricItem.fromJson(Map<String, dynamic>.from(v as Map)),
              ),
            )
          : const <String, MeritRubricItem>{},
      cutoffDayOfMonth: (json['cutoff_day_of_month'] as num?)?.toInt() ?? 1,
      coachMinAttendancePercentage: double.tryParse(
            json['coach_min_attendance_percentage']?.toString() ?? '',
          ) ??
          80,
      isActive: (json['is_active'] ?? true) == true,
      isDefault: isDefault,
    );
  }
}
