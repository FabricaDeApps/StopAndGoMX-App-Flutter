class GazettaItem {
  final int id;
  final int? organizationId;
  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String? status;
  final String? roleMode;
  final String? subject;
  final DateTime? publishedAt;
  final DateTime? sentAt;
  final DateTime? updatedAt;

  const GazettaItem({
    required this.id,
    this.organizationId,
    this.weekStart,
    this.weekEnd,
    this.status,
    this.roleMode,
    this.subject,
    this.publishedAt,
    this.sentAt,
    this.updatedAt,
  });

  factory GazettaItem.fromJson(Map<String, dynamic> json) {
    return GazettaItem(
      id: _asInt(json['id']) ?? 0,
      organizationId: _asInt(json['organization_id']),
      weekStart: _asDate(json['week_start']),
      weekEnd: _asDate(json['week_end']),
      status: _asString(json['status']),
      roleMode: _asString(json['role_mode']),
      subject: _asString(json['subject']),
      publishedAt: _asDate(json['published_at']),
      sentAt: _asDate(json['sent_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'week_start': weekStart?.toIso8601String(),
    'week_end': weekEnd?.toIso8601String(),
    'status': status,
    'role_mode': roleMode,
    'subject': subject,
    'published_at': publishedAt?.toIso8601String(),
    'sent_at': sentAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _asString(dynamic value) {
  final s = value?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
