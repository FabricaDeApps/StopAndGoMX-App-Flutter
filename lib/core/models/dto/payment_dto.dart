// lib/core/models/dto/payment_dto.dart
import 'receipt_dto.dart';
import 'discount_dto.dart';

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

  /// 👇 NUEVO: descuentos
  final List<DiscountDto> discounts;
  final int discountsCount;
  final double discountsSumAmount;
  final bool hasDiscount;
  final double netAmount;

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
    required this.discounts,
    required this.discountsCount,
    required this.discountsSumAmount,
    required this.hasDiscount,
    required this.netAmount,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(String? s) =>
        (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

    final player = json['player'] as Map<String, dynamic>?;
    final recs = (json['receipts'] as List?) ?? const [];
    final discs = (json['discounts'] as List?) ?? const [];

    final double _amount = (json['amount'] ?? 0).toDouble();
    final double _discountsSum = (json['discounts_sum_amount'] ?? 0).toDouble();
    final double _netAmount = (json['net_amount'] ?? (_amount - _discountsSum))
        .toDouble();

    return PaymentDto(
      id: (json['id'] ?? 0) as int,
      organizationId: (json['organization_id'] ?? 0) as int,
      playerId: player?['id'] as int?,
      playerName: player?['name']?.toString(),
      concept: (json['concept'] ?? '').toString(),
      amount: _amount,
      status: (json['status'] ?? '').toString(),
      dueDate: _d(json['due_date']?.toString()),
      paidAt: _d(json['paid_at']?.toString()),

      receipts: recs
          .map((e) => ReceiptDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      receiptsCount: (json['receipts_count'] ?? 0) as int,

      // 👇 descuentos
      discounts: discs
          .map((e) => DiscountDto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      discountsCount: (json['discounts_count'] ?? discs.length) as int,
      discountsSumAmount: _discountsSum,
      hasDiscount: (json['has_discount'] ?? (_discountsSum > 0)) as bool,
      netAmount: _netAmount,
    );
  }

  /// Si quieres, puedes agregar helpers:
  double get totalReceipts => receipts.fold(0.0, (sum, r) => sum + r.amount);

  double get remainingAfterDiscountsAndReceipts =>
      (netAmount - totalReceipts).clamp(0, double.infinity);
}
