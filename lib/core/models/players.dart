// lib/core/models/player.dart
class Player {
  final int id;
  final int organizationId;
  final int categoryId;
  final int? number;
  final bool isCaptain;
  final String status;
  final DateTime? assignedAt;
  final String firstName;
  final String lastName;
  final String position;
  final String name;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  Player({
    required this.id,
    required this.organizationId,
    required this.categoryId,
    this.number,
    required this.isCaptain,
    required this.status,
    this.assignedAt,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.name,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(String? s) {
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s);
    }

    return Player(
      id: json['id'] as int,
      organizationId: json['organization_id'] as int,
      categoryId: json['category_id'] as int,
      number: json['number'] is int
          ? json['number']
          : int.tryParse('${json['number']}'),
      isCaptain: json['is_captain'] == true,
      status: json['status']?.toString() ?? '',
      assignedAt: _parseDate(json['assigned_at']?.toString()),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      photoUrl: json['photo_url']?.toString(),
      createdAt: _parseDate(json['created_at']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'organization_id': organizationId,
    'category_id': categoryId,
    'number': number,
    'is_captain': isCaptain,
    'status': status,
    'assigned_at': assignedAt?.toIso8601String(),
    'first_name': firstName,
    'last_name': lastName,
    'position': position,
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
