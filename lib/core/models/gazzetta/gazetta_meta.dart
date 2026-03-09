class GazettaMeta {
  final int id;
  final bool seen;
  final DateTime? seenAt;
  final DateTime? updatedAt;

  const GazettaMeta({
    required this.id,
    this.seen = false,
    this.seenAt,
    this.updatedAt,
  });

  factory GazettaMeta.fromJson(Map<String, dynamic> json) {
    return GazettaMeta(
      id: _asInt(json['id']) ?? 0,
      seen: _asBool(json['seen']) ?? false,
      seenAt: _asDate(json['seen_at']),
      updatedAt: _asDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seen': seen,
    'seen_at': seenAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return null;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
