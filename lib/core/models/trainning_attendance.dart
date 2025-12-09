class TrainingAttendanceItem {
  final int id;
  final int playerId;
  final String playerName;
  final String playerPhoto;

  String status;
  int minutesLate;
  String? notes;

  final int? checkedBy;
  final String? checkedByName;

  final DateTime? checkedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TrainingAttendanceItem({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerPhoto,
    required this.status,
    required this.minutesLate,
    this.notes,
    this.checkedBy,
    this.checkedByName,
    this.checkedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory TrainingAttendanceItem.fromJson(Map<String, dynamic> json) {
    return TrainingAttendanceItem(
      id: json['id'],
      playerId: json['player_id'],
      playerName: json['player_name'] ?? '',
      playerPhoto: json['player_photo'] ?? '',
      status: json['status'] ?? 'absent',
      minutesLate: json['minutes_late'] ?? 0,
      notes: json['notes'],

      checkedBy: json['checked_by'],
      checkedByName: json['checked_by_name'],

      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'])
          : null,

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,

      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'player_name': playerName,
      'player_photo': playerPhoto,
      'status': status,
      'minutes_late': minutesLate,
      'notes': notes,
      'checked_by': checkedBy,
      'checked_by_name': checkedByName,
      'checked_at': checkedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
