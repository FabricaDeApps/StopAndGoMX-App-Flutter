class Training {
  final int id;
  final int organizationId;
  final int categoryId;
  final DateTime startsAt;
  final int? durationMinutes;
  final String? venue;
  final String? address;
  final String? city;
  final String status;
  final String? notes;
  final int? markedPlayers;
  final int? presentPlayers;
  final int? expectedPlayers;
  final double? attendancePct;

  Training({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    required this.startsAt,
    this.durationMinutes,
    this.venue,
    this.address,
    this.city,
    required this.status,
    this.notes,
    this.markedPlayers,
    this.presentPlayers,
    this.expectedPlayers,
    this.attendancePct,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      categoryId: (json['category_id'] ?? 0) as int,
      startsAt: DateTime.parse(json['starts_at'] as String),
      durationMinutes: json['duration_minutes'] as int?,
      venue: json['venue'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      status: (json['status'] ?? '') as String,
      notes: json['notes'] as String?,
      markedPlayers: json['marked_players'] as int?,
      presentPlayers: json['present_players'] as int?,
      expectedPlayers: json['expected_players'] as int?,
      attendancePct: (json['attendance_pct'] is num)
          ? (json['attendance_pct'] as num).toDouble()
          : null,
    );
  }
}
