class LiveEventModel {
  final int id;
  final String status;

  final String cloudflareUid;

  final String? rtmpsUrl;
  final String? rtmpsStreamKey;

  final String? webrtcPublishUrl;
  final String? webrtcPlayUrl;

  final int? deleteRecordingAfterDays;

  // Estos NO siempre vienen (por ejemplo en create response)
  final int? organizationId;
  final int? categoryId;
  final int? gameId;

  LiveEventModel({
    required this.id,
    required this.status,
    required this.cloudflareUid,
    this.rtmpsUrl,
    this.rtmpsStreamKey,
    this.webrtcPublishUrl,
    this.webrtcPlayUrl,
    this.deleteRecordingAfterDays,
    this.organizationId,
    this.categoryId,
    this.gameId,
  });

  factory LiveEventModel.fromJson(Map<String, dynamic> json) {
    int? _asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return LiveEventModel(
      id: _asInt(json['id']) ?? 0,
      status: (json['status'] ?? 'scheduled').toString(),
      cloudflareUid: (json['cloudflare_uid'] ?? '').toString(),

      rtmpsUrl: json['rtmps_url']?.toString(),
      rtmpsStreamKey: json['rtmps_stream_key']?.toString(),

      webrtcPublishUrl: json['webrtc_publish_url']?.toString(),
      webrtcPlayUrl: json['webrtc_play_url']?.toString(),

      deleteRecordingAfterDays: _asInt(json['delete_recording_after_days']),

      organizationId: _asInt(json['organization_id']),
      categoryId: _asInt(json['category_id']),
      gameId: _asInt(json['game_id']),
    );
  }
}
