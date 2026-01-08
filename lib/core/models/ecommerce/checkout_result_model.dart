class CheckoutResultModel {
  final int? orderId;
  final int? paymentId;
  final String? status;

  final String? intentCreateUrl;
  final String? intentCreateMethod;

  CheckoutResultModel({
    this.orderId,
    this.paymentId,
    this.status,
    this.intentCreateUrl,
    this.intentCreateMethod,
  });

  static int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  factory CheckoutResultModel.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;
    final order = _asMap(data['order']);
    final payment = _asMap(data['payment']);
    final intentCreate = _asMap(data['intent_create']);

    return CheckoutResultModel(
      orderId: _toIntOrNull(order?['id']),
      paymentId: _toIntOrNull(payment?['id']),
      status: (order?['status'] ?? payment?['status'])?.toString(),
      intentCreateUrl: intentCreate?['url']?.toString(),
      intentCreateMethod: intentCreate?['method']?.toString(),
    );
  }
}
