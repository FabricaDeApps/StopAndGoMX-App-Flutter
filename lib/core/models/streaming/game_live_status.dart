class GameLiveStatus {
  final bool hasLive;
  final String? status;
  final int? liveEventId;

  GameLiveStatus({required this.hasLive, this.status, this.liveEventId});

  factory GameLiveStatus.fromJson(Map<String, dynamic> json) {
    return GameLiveStatus(
      hasLive: json['has_live'],
      status: json['status'],
      liveEventId: json['live_event_id'],
    );
  }
}
