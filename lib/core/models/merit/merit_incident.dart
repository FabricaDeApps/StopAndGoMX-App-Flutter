class MeritIncidentPerson {
  final int id;
  final String name;

  const MeritIncidentPerson({required this.id, required this.name});

  factory MeritIncidentPerson.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name']?.toString();
    final lastName = json['last_name']?.toString();
    final composedName = (firstName != null || lastName != null)
        ? '${firstName ?? ''} ${lastName ?? ''}'.trim()
        : null;

    return MeritIncidentPerson(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? composedName ?? '').toString(),
    );
  }
}

class MeritIncident {
  final int id;
  final MeritIncidentPerson? coach;
  final MeritIncidentPerson? player;
  final MeritIncidentPerson? reportedBy;
  final String incidentType;
  final String? description;
  final String? sanctionApplied;
  final bool isRepeat;
  final bool resultedInExpulsion;
  final DateTime? occurredAt;

  const MeritIncident({
    required this.id,
    this.coach,
    this.player,
    this.reportedBy,
    required this.incidentType,
    this.description,
    this.sanctionApplied,
    required this.isRepeat,
    required this.resultedInExpulsion,
    this.occurredAt,
  });

  factory MeritIncident.fromJson(Map<String, dynamic> json) {
    final rawCoach = json['coach'];
    final rawPlayer = json['player'];
    final rawReportedBy = json['reported_by'];

    return MeritIncident(
      id: (json['id'] as num?)?.toInt() ?? 0,
      coach: rawCoach is Map
          ? MeritIncidentPerson.fromJson(Map<String, dynamic>.from(rawCoach))
          : null,
      player: rawPlayer is Map
          ? MeritIncidentPerson.fromJson(Map<String, dynamic>.from(rawPlayer))
          : null,
      reportedBy: rawReportedBy is Map
          ? MeritIncidentPerson.fromJson(
              Map<String, dynamic>.from(rawReportedBy),
            )
          : null,
      incidentType: (json['incident_type'] ?? '').toString(),
      description: json['description']?.toString(),
      sanctionApplied: json['sanction_applied']?.toString(),
      isRepeat: (json['is_repeat'] ?? false) == true,
      resultedInExpulsion: (json['resulted_in_expulsion'] ?? false) == true,
      occurredAt: DateTime.tryParse(json['occurred_at']?.toString() ?? ''),
    );
  }
}
