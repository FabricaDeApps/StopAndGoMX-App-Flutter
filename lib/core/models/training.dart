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
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'],
      organizationId: json['organization_id'],
      categoryId: json['category_id'],
      startsAt: DateTime.parse(json['starts_at']),
      durationMinutes: json['duration_minutes'],
      venue: json['venue'],
      address: json['address'],
      city: json['city'],
      status: json['status'],
      notes: json['notes'],
    );
  }
}
