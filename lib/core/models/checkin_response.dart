class CheckinResponse {
  final bool ok;
  final String? status;
  final String? reason;
  final String message;
  final Map<String, dynamic>? data;

  CheckinResponse({
    required this.ok,
    required this.message,
    this.status,
    this.reason,
    this.data,
  });

  factory CheckinResponse.fromJson(Map<String, dynamic> json) {
    return CheckinResponse(
      ok: json['ok'] == true,
      status: json['status'],
      reason: json['reason'],
      message: json['message'] ?? 'Ocurrió un error',
      data: json['data'],
    );
  }
}
