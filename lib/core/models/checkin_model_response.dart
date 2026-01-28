class CheckinModelResponse {
  final int id;
  final int organizationId;
  final int userId;

  final DateTime checkinDate;
  final DateTime checkedInAt;

  final double lat;
  final double lng;
  final int? accuracyM;

  final double hqLat;
  final double hqLng;
  final int radiusM;
  final int distanceM;

  final String status; // accepted | rejected
  final String? rejectReason;

  final String source;
  final String? ip;
  final String? userAgent;

  final DateTime createdAt;
  final DateTime updatedAt;

  CheckinModelResponse({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.checkinDate,
    required this.checkedInAt,
    required this.lat,
    required this.lng,
    this.accuracyM,
    required this.hqLat,
    required this.hqLng,
    required this.radiusM,
    required this.distanceM,
    required this.status,
    this.rejectReason,
    required this.source,
    this.ip,
    this.userAgent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CheckinModelResponse.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      return DateTime.parse(v.toString());
    }

    return CheckinModelResponse(
      id: json['id'],
      organizationId: json['organization_id'],
      userId: json['user_id'],
      checkinDate: toDate(json['checkin_date']),
      checkedInAt: toDate(json['checked_in_at']),
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
      accuracyM: toInt(json['accuracy_m']),
      hqLat: toDouble(json['hq_lat']),
      hqLng: toDouble(json['hq_lng']),
      radiusM: json['radius_m'] is int
          ? json['radius_m']
          : int.parse(json['radius_m'].toString()),
      distanceM: json['distance_m'] is int
          ? json['distance_m']
          : int.parse(json['distance_m'].toString()),
      status: json['status'],
      rejectReason: json['reject_reason'],
      source: json['source'],
      ip: json['ip'],
      userAgent: json['user_agent'],
      createdAt: toDate(json['created_at']),
      updatedAt: toDate(json['updated_at']),
    );
  }
}
