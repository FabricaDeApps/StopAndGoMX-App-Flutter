class DiscountDto {
  final int id;
  final double amount;
  final DateTime? createdAt;
  // Si luego agregas más campos en el backend (reason, type, etc.), los metemos aquí.

  DiscountDto({required this.id, required this.amount, this.createdAt});

  factory DiscountDto.fromJson(Map<String, dynamic> json) {
    DateTime? _d(String? s) =>
        (s == null || s.isEmpty) ? null : DateTime.tryParse(s);

    return DiscountDto(
      id: (json['id'] ?? 0) as int,
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: _d(json['created_at']?.toString()),
    );
  }
}
