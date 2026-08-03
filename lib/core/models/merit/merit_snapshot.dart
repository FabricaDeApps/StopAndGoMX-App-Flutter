class MeritScoreBreakdown {
  final String rubricItem;
  final double pointsEarned;
  final double pointsPossible;

  const MeritScoreBreakdown({
    required this.rubricItem,
    required this.pointsEarned,
    required this.pointsPossible,
  });

  factory MeritScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return MeritScoreBreakdown(
      rubricItem: (json['rubric_item'] ?? '').toString(),
      pointsEarned:
          double.tryParse(json['points_earned']?.toString() ?? '') ?? 0,
      pointsPossible:
          double.tryParse(json['points_possible']?.toString() ?? '') ?? 0,
    );
  }
}

class MeritSnapshotPlayer {
  final int id;
  final String firstName;
  final String lastName;
  final String? photo;

  const MeritSnapshotPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photo,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MeritSnapshotPlayer.fromJson(Map<String, dynamic> json) {
    return MeritSnapshotPlayer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
      photo: json['photo']?.toString(),
    );
  }
}

class MeritValidator {
  final int id;
  final String name;

  const MeritValidator({required this.id, required this.name});

  factory MeritValidator.fromJson(Map<String, dynamic> json) {
    return MeritValidator(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class MeritSnapshot {
  final int id;
  final int playerId;
  final DateTime? periodMonth;
  final double totalScore;
  final double extraPoints;
  final String meritLevel;
  final bool isFundEligible;
  final int? validatedByHeadCoachId;
  final int? validatedByManagerId;
  final DateTime? validatedAt;
  final DateTime? lockedAt;
  final List<MeritScoreBreakdown> breakdowns;
  final MeritSnapshotPlayer? player;
  final MeritValidator? validatedByHeadCoach;
  final MeritValidator? validatedByManager;

  const MeritSnapshot({
    required this.id,
    required this.playerId,
    this.periodMonth,
    required this.totalScore,
    required this.extraPoints,
    required this.meritLevel,
    required this.isFundEligible,
    this.validatedByHeadCoachId,
    this.validatedByManagerId,
    this.validatedAt,
    this.lockedAt,
    this.breakdowns = const [],
    this.player,
    this.validatedByHeadCoach,
    this.validatedByManager,
  });

  bool get isLocked => lockedAt != null;

  factory MeritSnapshot.fromJson(Map<String, dynamic> json) {
    final rawBreakdowns = json['breakdowns'];
    final rawPlayer = json['player'];
    final rawHeadCoach = json['validated_by_head_coach'];
    final rawManager = json['validated_by_manager'];

    return MeritSnapshot(
      id: (json['id'] as num?)?.toInt() ?? 0,
      playerId: (json['player_id'] as num?)?.toInt() ?? 0,
      periodMonth: DateTime.tryParse(json['period_month']?.toString() ?? ''),
      totalScore: double.tryParse(json['total_score']?.toString() ?? '') ?? 0,
      extraPoints:
          double.tryParse(json['extra_points']?.toString() ?? '') ?? 0,
      meritLevel: (json['merit_level'] ?? 'none').toString(),
      isFundEligible: (json['is_fund_eligible'] ?? false) == true,
      validatedByHeadCoachId:
          (json['validated_by_head_coach_id'] as num?)?.toInt(),
      validatedByManagerId: (json['validated_by_manager_id'] as num?)?.toInt(),
      validatedAt: DateTime.tryParse(json['validated_at']?.toString() ?? ''),
      lockedAt: DateTime.tryParse(json['locked_at']?.toString() ?? ''),
      breakdowns: rawBreakdowns is List
          ? rawBreakdowns
              .whereType<Map>()
              .map(
                (e) =>
                    MeritScoreBreakdown.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const <MeritScoreBreakdown>[],
      player: rawPlayer is Map
          ? MeritSnapshotPlayer.fromJson(Map<String, dynamic>.from(rawPlayer))
          : null,
      validatedByHeadCoach: rawHeadCoach is Map
          ? MeritValidator.fromJson(Map<String, dynamic>.from(rawHeadCoach))
          : null,
      validatedByManager: rawManager is Map
          ? MeritValidator.fromJson(Map<String, dynamic>.from(rawManager))
          : null,
    );
  }
}
