class MeritRecruiterCoach {
  final int id;
  final String name;

  const MeritRecruiterCoach({required this.id, required this.name});

  factory MeritRecruiterCoach.fromJson(Map<String, dynamic> json) {
    return MeritRecruiterCoach(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

class MeritRecruiterPlayer {
  final int id;
  final String firstName;
  final String lastName;

  const MeritRecruiterPlayer({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory MeritRecruiterPlayer.fromJson(Map<String, dynamic> json) {
    return MeritRecruiterPlayer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: (json['first_name'] ?? '').toString(),
      lastName: (json['last_name'] ?? '').toString(),
    );
  }
}

class MeritPaymentStage {
  final int id;
  final String stage;
  final String status;
  final DateTime? eligibleAt;
  final DateTime? paidAt;
  final double? amountMxn;

  const MeritPaymentStage({
    required this.id,
    required this.stage,
    required this.status,
    this.eligibleAt,
    this.paidAt,
    this.amountMxn,
  });

  factory MeritPaymentStage.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount_mxn'];
    return MeritPaymentStage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      stage: (json['stage'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      eligibleAt: DateTime.tryParse(json['eligible_at']?.toString() ?? ''),
      paidAt: DateTime.tryParse(json['paid_at']?.toString() ?? ''),
      amountMxn:
          rawAmount == null ? null : double.tryParse(rawAmount.toString()),
    );
  }
}

class MeritProspect {
  final int id;
  final String fullName;
  final String status;
  final MeritRecruiterCoach? recruitedByCoach;
  final MeritRecruiterPlayer? recruitedByPlayer;
  final int? enrolledPlayerId;
  final DateTime? enrolledAt;
  final DateTime? retentionConfirmedAt;
  final List<MeritPaymentStage> paymentStages;

  const MeritProspect({
    required this.id,
    required this.fullName,
    required this.status,
    this.recruitedByCoach,
    this.recruitedByPlayer,
    this.enrolledPlayerId,
    this.enrolledAt,
    this.retentionConfirmedAt,
    this.paymentStages = const [],
  });

  factory MeritProspect.fromJson(Map<String, dynamic> json) {
    final rawCoach = json['recruited_by_coach'];
    final rawPlayer = json['recruited_by_player'];
    final rawStages = json['payment_stages'];

    return MeritProspect(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['full_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      recruitedByCoach: rawCoach is Map
          ? MeritRecruiterCoach.fromJson(Map<String, dynamic>.from(rawCoach))
          : null,
      recruitedByPlayer: rawPlayer is Map
          ? MeritRecruiterPlayer.fromJson(Map<String, dynamic>.from(rawPlayer))
          : null,
      enrolledPlayerId: (json['enrolled_player_id'] as num?)?.toInt(),
      enrolledAt: DateTime.tryParse(json['enrolled_at']?.toString() ?? ''),
      retentionConfirmedAt:
          DateTime.tryParse(json['retention_confirmed_at']?.toString() ?? ''),
      paymentStages: rawStages is List
          ? rawStages
              .whereType<Map>()
              .map(
                (e) => MeritPaymentStage.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
          : const <MeritPaymentStage>[],
    );
  }
}
