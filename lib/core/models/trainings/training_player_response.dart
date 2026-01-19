class TrainingPlayerResponse {
  final PlayerMini player;
  final TrainingFilters filters;
  final TrainingSummary summary;
  final List<TrainingCategoryBlock> categories;

  TrainingPlayerResponse({
    required this.player,
    required this.filters,
    required this.summary,
    required this.categories,
  });

  factory TrainingPlayerResponse.fromJson(Map<String, dynamic> json) {
    return TrainingPlayerResponse(
      player: PlayerMini.fromJson(
        (json['player'] ?? {}) as Map<String, dynamic>,
      ),
      filters: TrainingFilters.fromJson(
        (json['filters'] ?? {}) as Map<String, dynamic>,
      ),
      summary: TrainingSummary.fromJson(
        (json['summary'] ?? {}) as Map<String, dynamic>,
      ),
      categories: ((json['categories'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => TrainingCategoryBlock.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'player': player.toJson(),
    'filters': filters.toJson(),
    'summary': summary.toJson(),
    'categories': categories.map((e) => e.toJson()).toList(),
  };
}

class PlayerMini {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? photo;
  final int organizationId;

  PlayerMini({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.photo,
    required this.organizationId,
  });

  factory PlayerMini.fromJson(Map<String, dynamic> json) {
    return PlayerMini(
      id: (json['id'] ?? 0) as int,
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      name: json['name']?.toString(),
      photo: json['photo']?.toString(),
      organizationId: (json['organization_id'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'first_name': firstName,
    'last_name': lastName,
    'name': name,
    'photo': photo,
    'organization_id': organizationId,
  };
}

class TrainingFilters {
  final DateTime? from;
  final DateTime? to;
  final int? seasonId;
  final int? categoryId;
  final bool countJustified;

  TrainingFilters({
    required this.from,
    required this.to,
    required this.seasonId,
    required this.categoryId,
    required this.countJustified,
  });

  factory TrainingFilters.fromJson(Map<String, dynamic> json) {
    return TrainingFilters(
      from: DateTime.tryParse((json['from'] ?? '').toString()),
      to: DateTime.tryParse((json['to'] ?? '').toString()),
      seasonId: json['season_id'] == null
          ? null
          : int.tryParse('${json['season_id']}'),
      categoryId: json['category_id'] == null
          ? null
          : int.tryParse('${json['category_id']}'),
      countJustified: (json['count_justified'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'from': from?.toIso8601String(),
    'to': to?.toIso8601String(),
    'season_id': seasonId,
    'category_id': categoryId,
    'count_justified': countJustified,
  };
}

class TrainingSummary {
  final int totalTrainings;
  final int markedTrainings;
  final int present;
  final int absent;
  final int justified;
  final int markedTotal;
  final double attendancePercent;

  TrainingSummary({
    required this.totalTrainings,
    required this.markedTrainings,
    required this.present,
    required this.absent,
    required this.justified,
    required this.markedTotal,
    required this.attendancePercent,
  });

  factory TrainingSummary.fromJson(Map<String, dynamic> json) {
    return TrainingSummary(
      totalTrainings: (json['total_trainings'] ?? 0) as int,
      markedTrainings: (json['marked_trainings'] ?? 0) as int,
      present: (json['present'] ?? 0) as int,
      absent: (json['absent'] ?? 0) as int,
      justified: (json['justified'] ?? 0) as int,
      markedTotal: (json['marked_total'] ?? 0) as int,
      attendancePercent:
          double.tryParse('${json['attendance_percent']}') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_trainings': totalTrainings,
    'marked_trainings': markedTrainings,
    'present': present,
    'absent': absent,
    'justified': justified,
    'marked_total': markedTotal,
    'attendance_percent': attendancePercent,
  };
}

class TrainingCategoryBlock {
  final CategoryWithJersey category;
  final TrainingSummary summary;
  final List<TrainingHistoryItem> history;

  TrainingCategoryBlock({
    required this.category,
    required this.summary,
    required this.history,
  });

  factory TrainingCategoryBlock.fromJson(Map<String, dynamic> json) {
    return TrainingCategoryBlock(
      category: CategoryWithJersey.fromJson(
        (json['category'] ?? {}) as Map<String, dynamic>,
      ),
      summary: TrainingSummary.fromJson(
        (json['summary'] ?? {}) as Map<String, dynamic>,
      ),
      history: ((json['history'] ?? []) as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => TrainingHistoryItem.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category.toJson(),
    'summary': summary.toJson(),
    'history': history.map((e) => e.toJson()).toList(),
  };
}

class CategoryWithJersey {
  final int id;
  final String? name;
  final int? jerseyNumber;
  final bool isCaptain;
  final String? status;

  CategoryWithJersey({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.isCaptain,
    required this.status,
  });

  factory CategoryWithJersey.fromJson(Map<String, dynamic> json) {
    return CategoryWithJersey(
      id: (json['id'] ?? 0) as int,
      name: json['name']?.toString(),
      jerseyNumber: json['jersey_number'] == null
          ? null
          : int.tryParse('${json['jersey_number']}'),
      isCaptain: (json['is_captain'] ?? false) == true,
      status: json['status']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'jersey_number': jerseyNumber,
    'is_captain': isCaptain,
    'status': status,
  };
}

class TrainingHistoryItem {
  final int id;
  final DateTime? startsAt;
  final int? durationMinutes;
  final String? venue; // puede venir null o string
  final String? address;
  final String? city;
  final String? status;
  final String? notes;

  final CategoryMini category;
  final AttendanceMini? attendance;

  TrainingHistoryItem({
    required this.id,
    required this.startsAt,
    required this.durationMinutes,
    required this.venue,
    required this.address,
    required this.city,
    required this.status,
    required this.notes,
    required this.category,
    required this.attendance,
  });

  factory TrainingHistoryItem.fromJson(Map<String, dynamic> json) {
    return TrainingHistoryItem(
      id: (json['id'] ?? 0) as int,
      startsAt: DateTime.tryParse((json['starts_at'] ?? '').toString()),
      durationMinutes: json['duration_minutes'] == null
          ? null
          : int.tryParse('${json['duration_minutes']}'),
      venue: json['venue']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      status: json['status']?.toString(),
      notes: json['notes']?.toString(),
      category: CategoryMini.fromJson(
        (json['category'] ?? {}) as Map<String, dynamic>,
      ),
      attendance: json['attendance'] == null
          ? null
          : AttendanceMini.fromJson(json['attendance'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'starts_at': startsAt?.toIso8601String(),
    'duration_minutes': durationMinutes,
    'venue': venue,
    'address': address,
    'city': city,
    'status': status,
    'notes': notes,
    'category': category.toJson(),
    'attendance': attendance?.toJson(),
  };
}

class CategoryMini {
  final int id;
  final String? name;

  CategoryMini({required this.id, required this.name});

  factory CategoryMini.fromJson(Map<String, dynamic> json) => CategoryMini(
    id: (json['id'] ?? 0) as int,
    name: json['name']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AttendanceMini {
  final int id;
  final String? status;
  final int? minutesLate;
  final String? notes;
  final DateTime? checkedAt;
  final CheckedByMini? checkedBy;

  AttendanceMini({
    required this.id,
    required this.status,
    required this.minutesLate,
    required this.notes,
    required this.checkedAt,
    required this.checkedBy,
  });

  factory AttendanceMini.fromJson(Map<String, dynamic> json) {
    return AttendanceMini(
      id: (json['id'] ?? 0) as int,
      status: json['status']?.toString(),
      minutesLate: json['minutes_late'] == null
          ? null
          : int.tryParse('${json['minutes_late']}'),
      notes: json['notes']?.toString(),
      checkedAt: DateTime.tryParse((json['checked_at'] ?? '').toString()),
      checkedBy: json['checked_by'] == null
          ? null
          : CheckedByMini.fromJson(json['checked_by'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'minutes_late': minutesLate,
    'notes': notes,
    'checked_at': checkedAt?.toIso8601String(),
    'checked_by': checkedBy?.toJson(),
  };
}

class CheckedByMini {
  final int id;
  final String? name;

  CheckedByMini({required this.id, required this.name});

  factory CheckedByMini.fromJson(Map<String, dynamic> json) => CheckedByMini(
    id: (json['id'] ?? 0) as int,
    name: json['name']?.toString(),
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
