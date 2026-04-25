class CheckinCheckoutRequest {
  final double lat;
  final double lng;
  final int? accuracyM;

  const CheckinCheckoutRequest({
    required this.lat,
    required this.lng,
    this.accuracyM,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (accuracyM != null) 'accuracy_m': accuracyM,
    };
  }
}
