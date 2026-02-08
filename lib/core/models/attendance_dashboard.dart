class AttendanceDashboard {
  final int trainingsMarkedTotal;
  final int present;
  final int absent;
  final int justified;
  final double percent;
  final double percentWithJustified;

  const AttendanceDashboard({
    required this.trainingsMarkedTotal,
    required this.present,
    required this.absent,
    required this.justified,
    required this.percent,
    required this.percentWithJustified,
  });

  factory AttendanceDashboard.fromJson(Map<String, dynamic> json) {
    double _safePercent(dynamic raw) {
      final value = (raw as num?)?.toDouble() ?? 0.0;
      if (!value.isFinite) return 0.0;
      return value.clamp(0.0, 100.0).toDouble();
    }

    return AttendanceDashboard(
      trainingsMarkedTotal:
          (json['trainings_marked_total'] as num?)?.toInt() ?? 0,
      present: (json['present'] as num?)?.toInt() ?? 0,
      absent: (json['absent'] as num?)?.toInt() ?? 0,
      justified: (json['justified'] as num?)?.toInt() ?? 0,
      percent: _safePercent(json['percent']),
      percentWithJustified: _safePercent(json['percent_with_justified']),
    );
  }

  static const empty = AttendanceDashboard(
    trainingsMarkedTotal: 0,
    present: 0,
    absent: 0,
    justified: 0,
    percent: 0.0,
    percentWithJustified: 0.0,
  );
}
