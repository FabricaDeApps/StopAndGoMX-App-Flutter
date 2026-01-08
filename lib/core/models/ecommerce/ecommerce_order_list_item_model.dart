class EcommerceOrderListItemModel {
  final int id;
  final int orgFolio;
  final String status;
  final int totalCents;
  final DateTime? createdAt;

  EcommerceOrderListItemModel({
    required this.id,
    required this.orgFolio,
    required this.status,
    required this.totalCents,
    this.createdAt,
  });

  String get folio => 'ORG-${orgFolio.toString().padLeft(6, '0')}';
  double get total => totalCents / 100.0;

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  factory EcommerceOrderListItemModel.fromJson(Map<String, dynamic> json) {
    return EcommerceOrderListItemModel(
      id: _toInt(json['id']),
      orgFolio: _toInt(json['org_folio']),
      status: (json['status'] ?? '').toString(),
      totalCents: _toInt(json['total_cents']),
      createdAt: _toDate(json['created_at']),
    );
  }
}
