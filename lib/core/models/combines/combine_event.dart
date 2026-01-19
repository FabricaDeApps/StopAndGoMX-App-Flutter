class CombineEvent {
  final int id;
  final int organizationId;
  final CategoryMini? category;
  final SeasonMini? season;
  final VenueMini? venue;

  final String name;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String? notes;

  final int? createdBy;
  final DateTime? createdAt;

  CombineEvent({
    required this.id,
    required this.organizationId,
    required this.category,
    required this.season,
    required this.venue,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory CombineEvent.fromJson(Map<String, dynamic> json) {
    return CombineEvent(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      category: json['category'] != null
          ? CategoryMini.fromAny(json['category'])
          : null,
      season: json['season'] == null
          ? null
          : SeasonMini.fromJson(json['season'] as Map<String, dynamic>),
      venue: json['venue'] == null
          ? null
          : VenueMini.fromJson(json['venue'] as Map<String, dynamic>),
      name: (json['name'] ?? '') as String,
      startsAt: DateTime.tryParse((json['starts_at'] ?? '').toString()),
      endsAt: DateTime.tryParse((json['ends_at'] ?? '').toString()),
      notes: json['notes']?.toString(),
      createdBy: json['created_by'] is int
          ? json['created_by'] as int
          : int.tryParse('${json['created_by']}'),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    //'category': category.toJson(),
    'season': season?.toJson(),
    'venue': venue?.toJson(),
    'name': name,
    'starts_at': startsAt?.toIso8601String(),
    'ends_at': endsAt?.toIso8601String(),
    'notes': notes,
    'created_by': createdBy,
    'created_at': createdAt?.toIso8601String(),
  };
}

class CategoryMini {
  final int id;
  final String? name;

  CategoryMini({required this.id, this.name});

  /// Cuando viene como objeto
  factory CategoryMini.fromJson(Map<String, dynamic> json) {
    return CategoryMini(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString(),
    );
  }

  /// Cuando viene solo como ID (int)
  factory CategoryMini.fromId(dynamic value) {
    if (value is num) {
      return CategoryMini(id: value.toInt());
    }
    throw ArgumentError('CategoryMini.fromId esperaba int/num');
  }

  /// 🔥 Factory universal (usa esta SIEMPRE)
  factory CategoryMini.fromAny(dynamic value) {
    if (value == null) {
      throw ArgumentError('CategoryMini.fromAny recibió null');
    }

    if (value is Map) {
      return CategoryMini.fromJson(Map<String, dynamic>.from(value));
    }

    if (value is num) {
      return CategoryMini.fromId(value);
    }

    throw ArgumentError('CategoryMini.fromAny no soporta ${value.runtimeType}');
  }
}

class SeasonMini {
  final int id;
  final String? name;

  SeasonMini({required this.id, required this.name});

  factory SeasonMini.fromJson(Map<String, dynamic> json) =>
      SeasonMini(id: (json['id'] ?? 0) as int, name: json['name']?.toString());

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class VenueMini {
  final int id;
  final String? name;

  VenueMini({required this.id, required this.name});

  factory VenueMini.fromJson(Map<String, dynamic> json) =>
      VenueMini(id: (json['id'] ?? 0) as int, name: json['name']?.toString());

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
