class CheckinTodayStatus {
  final bool hasCheckin;
  final bool hasCheckout;
  final DateTime? checkedInAt;
  final DateTime? checkedOutAt;
  final int? durationMinutes;
  final int? distanceM;
  final int? radiusM;
  final String? locationType;
  final String? locationLabel;
  final String? date;
  final int? checkinId;

  const CheckinTodayStatus({
    required this.hasCheckin,
    required this.hasCheckout,
    this.checkedInAt,
    this.checkedOutAt,
    this.durationMinutes,
    this.distanceM,
    this.radiusM,
    this.locationType,
    this.locationLabel,
    this.date,
    this.checkinId,
  });

  bool get canCheckout => hasCheckin && !hasCheckout;

  factory CheckinTodayStatus.fromJson(Map<String, dynamic> json) {
    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      final raw = value.toString().trim();
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    int? toInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    bool toBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final raw = value?.toString().trim().toLowerCase() ?? '';
      return raw == 'true' || raw == '1';
    }

    final data = json['data'];
    final payload = data is Map<String, dynamic>
        ? data
        : data is Map
        ? data.map((key, value) => MapEntry(key.toString(), value))
        : json;

    return CheckinTodayStatus(
      hasCheckin: toBool(payload['has_checkin']),
      hasCheckout: toBool(payload['has_checkout']),
      checkedInAt: toDate(
        payload['checked_in_at'] ??
            payload['checkin_at'] ??
            payload['today_checkin_at'],
      ),
      checkedOutAt: toDate(
        payload['checked_out_at'] ??
            payload['checkout_at'] ??
            payload['today_checkout_at'],
      ),
      durationMinutes: toInt(payload['duration_minutes']),
      distanceM: toInt(payload['distance_m']),
      radiusM: toInt(payload['radius_m']),
      locationType: payload['location_type']?.toString(),
      locationLabel: payload['location_label']?.toString(),
      date: payload['date']?.toString(),
      checkinId: toInt(payload['checkin_id'] ?? payload['id']),
    );
  }

  static const empty = CheckinTodayStatus(
    hasCheckin: false,
    hasCheckout: false,
  );
}
