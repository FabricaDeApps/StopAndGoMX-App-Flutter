// lib/core/models/dto/receipt_dto.dart
class ReceiptDto {
  final int id;
  final double amount;
  final DateTime? paidAt;
  final String method;
  final String? reference;
  final String? url;
  final DateTime? createdAt;

  ReceiptDto({
    required this.id,
    required this.amount,
    this.paidAt,
    required this.method,
    this.reference,
    this.url,
    this.createdAt,
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(String? s) =>
        (s == null || s.isEmpty) ? null : DateTime.tryParse(s);
    return ReceiptDto(
      id: (json['id'] ?? 0) as int,
      amount: (json['amount'] ?? 0).toDouble(),
      paidAt: _d(json['paid_at']?.toString()),
      method: (json['method'] ?? '').toString(),
      reference: json['reference']?.toString(),
      url: json['url']?.toString(),
      createdAt: _d(json['created_at']?.toString()),
    );
  }
}
