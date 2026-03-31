// lib/core/models/player.dart
class Player {
  final int id;
  final int organizationId;
  final int? categoryId;
  final int? categoryPlayerId;
  final int? number;
  final int? positionId;
  final bool isCaptain;
  final String status;
  final DateTime? assignedAt;
  final String firstName;
  final String lastName;
  final String position;
  final String? positionCatalogName;
  final String name;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  Player({
    required this.id,
    required this.organizationId,
    this.categoryId,
    this.categoryPlayerId,
    this.number,
    this.positionId,
    required this.isCaptain,
    required this.status,
    this.assignedAt,
    required this.firstName,
    required this.lastName,
    required this.position,
    this.positionCatalogName,
    required this.name,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return Player(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      categoryId: json['category_id'] ?? 0,
      categoryPlayerId: json['category_player_id'] ?? 0,
      number: json['number'] is int
          ? json['number']
          : int.tryParse('${json['number']}'),
      positionId: (json['position_id'] as num?)?.toInt(),
      isCaptain: json['is_captain'] == true,
      status: json['status']?.toString() ?? '',
      assignedAt: parseDate(json['assigned_at']?.toString()),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      positionCatalogName: json['position_catalog_name']?.toString(),
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      createdAt: parseDate(json['created_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'category_id': categoryId,
    'category_player_id': categoryPlayerId,
    'number': number,
    'position_id': positionId,
    'is_captain': isCaptain,
    'status': status,
    'assigned_at': assignedAt?.toIso8601String(),
    'first_name': firstName,
    'last_name': lastName,
    'position': position,
    'position_catalog_name': positionCatalogName,
    'name': name,
    'display_name': displayName,
    'photo_url': photoUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  String get initials {
    if (firstName.isEmpty && lastName.isEmpty) return '?';
    final fn = firstName.isNotEmpty ? firstName[0] : '';
    final ln = lastName.isNotEmpty ? lastName[0] : '';
    return (fn + ln).toUpperCase();
  }
}

class PlayerPositionOption {
  final int id;
  final String label;
  final bool active;

  const PlayerPositionOption({
    required this.id,
    required this.label,
    required this.active,
  });

  factory PlayerPositionOption.fromJson(Map<String, dynamic> json) {
    return PlayerPositionOption(
      id: (json['id'] as num?)?.toInt() ?? 0,
      label:
          (json['label'] ??
                  json['name'] ??
                  json['position'] ??
                  json['title'] ??
                  '')
              .toString(),
      active: json['active'] != false && json['is_active'] != false,
    );
  }
}

class PlayerPositionsCatalog {
  final List<PlayerPositionOption> options;
  final bool allowsCustomPosition;

  const PlayerPositionsCatalog({
    required this.options,
    required this.allowsCustomPosition,
  });
}
