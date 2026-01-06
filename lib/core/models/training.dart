class Training {
  final int id;
  final int organizationId;
  final int categoryId;
  final int? venueId;
  final String? venueName;
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
    this.venueId,
    this.durationMinutes,
    this.venueName,
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
    final dynamic venueRaw = json['venue'];
    String? venueName;
    if (venueRaw is Map) {
      final name = venueRaw['name'];
      if (name is String && name.trim().isNotEmpty) venueName = name.trim();
    } else if (venueRaw is String && venueRaw.trim().isNotEmpty) {
      venueName = venueRaw.trim();
    }
    final vNameLegacy = json['venue_name'];
    if ((venueName == null || venueName.isEmpty) &&
        vNameLegacy is String &&
        vNameLegacy.trim().isNotEmpty) {
      venueName = vNameLegacy.trim();
    }

    return Training(
      id: (json['id'] as num?)?.toInt() ?? 0,
      organizationId: (json['organization_id'] as num?)?.toInt() ?? 0,
      categoryId: (json['category_id'] as num?)?.toInt() ?? 0,
      venueId: (json['venue_id'] as num?)?.toInt(),
      startsAt: DateTime.parse((json['starts_at'] ?? '') as String),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
      venueName: venueName,
      address: json['address'] as String?,
      city: json['city'] as String?,
      status: (json['status'] ?? '') as String,
      notes: json['notes'] as String?,
      markedPlayers: (json['marked_players'] as num?)?.toInt(),
      presentPlayers: (json['present_players'] as num?)?.toInt(),
      expectedPlayers: (json['expected_players'] as num?)?.toInt(),
      attendancePct: (json['attendance_pct'] is num)
          ? (json['attendance_pct'] as num).toDouble()
          : null,
    );
  }
}
