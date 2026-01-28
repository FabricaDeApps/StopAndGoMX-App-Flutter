class CheckinModel {
  final double lat;
  final double lng;
  final int? accuracyM;
  final String? source;

  CheckinModel({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.source,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracyM: json['accuracy_m'] as int?,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (source != null) 'source': source,
    };
  }
}
