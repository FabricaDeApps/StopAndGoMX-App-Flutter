import 'package:stopandgo/core/models/gazzetta/gazetta_detail.dart';

class GazettaFeedResponse {
  final GazettaDetail? data;

  const GazettaFeedResponse({required this.data});

  factory GazettaFeedResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    if (raw is Map<String, dynamic>) {
      return GazettaFeedResponse(data: GazettaDetail.fromJson(raw));
    }
    if (raw is Map) {
      return GazettaFeedResponse(
        data: GazettaDetail.fromJson(Map<String, dynamic>.from(raw)),
      );
    }
    return const GazettaFeedResponse(data: null);
  }
}
