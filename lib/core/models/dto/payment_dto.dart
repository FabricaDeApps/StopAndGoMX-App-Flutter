// lib/core/models/dto/payment_dto.dart
import 'receipt_dto.dart';

class PaymentDto {
  final int id;
  final int organizationId;
  final int? playerId;
  final String? playerName;

  final String concept;
  final double amount;
  final String status; // "pending" | "partial" | "paid"
  final DateTime? dueDate;
  final DateTime? paidAt;

  final List<ReceiptDto> receipts;
  final int receiptsCount;

  PaymentDto({
    required this.id,
    required this.organizationId,
    required this.playerId,
    required this.playerName,
    required this.concept,
    required this.amount,
    required this.status,
    required this.dueDate,
    required this.paidAt,
    required this.receipts,
    required this.receiptsCount,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(String? s) =>
        (s == null || s.isEmpty) ? null : DateTime.tryParse(s);
    final player = json['player'] as Map<String, dynamic>?;
    final recs = (json['receipts'] as List?) ?? const [];

    return PaymentDto(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      playerId: player?['id'] as int?,
      playerName: player?['name']?.toString(),
      concept: (json['concept'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      status: (json['status'] ?? '').toString(),
      dueDate: _d(json['due_date']?.toString()),
      paidAt: _d(json['paid_at']?.toString()),
      receipts: recs
          .map((e) => ReceiptDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receiptsCount: (json['receipts_count'] ?? 0) as int,
    );
  }
}
