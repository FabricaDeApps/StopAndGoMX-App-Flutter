class MeritCreditLedgerEntry {
  final int id;
  final int playerId;
  final String entryType;
  final double amountMxn;
  final double balanceAfterMxn;
  final String sourceType;
  final String? appliedToType;
  final int? appliedToPaymentId;
  final DateTime? createdAt;

  const MeritCreditLedgerEntry({
    required this.id,
    required this.playerId,
    required this.entryType,
    required this.amountMxn,
    required this.balanceAfterMxn,
    required this.sourceType,
    this.appliedToType,
    this.appliedToPaymentId,
    this.createdAt,
  });

  bool get isCredit => entryType == 'credit';

  factory MeritCreditLedgerEntry.fromJson(Map<String, dynamic> json) {
    return MeritCreditLedgerEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      playerId: (json['player_id'] as num?)?.toInt() ?? 0,
      entryType: (json['entry_type'] ?? '').toString(),
      amountMxn: double.tryParse(json['amount_mxn']?.toString() ?? '') ?? 0,
      balanceAfterMxn:
          double.tryParse(json['balance_after_mxn']?.toString() ?? '') ?? 0,
      sourceType: (json['source_type'] ?? '').toString(),
      appliedToType: json['applied_to_type']?.toString(),
      appliedToPaymentId: (json['applied_to_payment_id'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
