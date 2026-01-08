class EcommerceOrderDetailModel {
  final int id;
  final int orgFolio;
  final String status;
  final String fulfillmentType; // pickup | delivery
  final int subtotalCents;
  final int deliveryFeeCents;
  final int totalCents;
  final DateTime? createdAt;

  final List<EcommerceOrderDetailItemModel> items;

  EcommerceOrderDetailModel({
    required this.id,
    required this.orgFolio,
    required this.status,
    required this.fulfillmentType,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.totalCents,
    required this.items,
    this.createdAt,
  });

  String get folio => 'ORG-${orgFolio.toString().padLeft(6, '0')}';
  double get subtotal => subtotalCents / 100.0;
  double get deliveryFee => deliveryFeeCents / 100.0;
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

  factory EcommerceOrderDetailModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : json;

    final itemsJson = (data['items'] is List)
        ? (data['items'] as List)
        : const [];

    return EcommerceOrderDetailModel(
      id: _toInt(data['id']),
      orgFolio: _toInt(data['org_folio']),
      status: (data['status'] ?? '').toString(),
      fulfillmentType: (data['fulfillment_type'] ?? 'pickup').toString(),
      subtotalCents: _toInt(data['subtotal_cents']),
      deliveryFeeCents: _toInt(data['delivery_fee_cents']),
      totalCents: _toInt(data['total_cents']),
      createdAt: _toDate(data['created_at']),
      items: itemsJson
          .map(
            (e) => EcommerceOrderDetailItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class EcommerceOrderDetailItemModel {
  final int id;
  final int qty;
  final String productName;
  final String variantTitle;
  final int lineTotalCents;
  final String? imagePathSnapshot;

  EcommerceOrderDetailItemModel({
    required this.id,
    required this.qty,
    required this.productName,
    required this.variantTitle,
    required this.lineTotalCents,
    this.imagePathSnapshot,
  });

  double get lineTotal => lineTotalCents / 100.0;

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory EcommerceOrderDetailItemModel.fromJson(Map<String, dynamic> json) {
    return EcommerceOrderDetailItemModel(
      id: _toInt(json['id']),
      qty: _toInt(json['qty'], fallback: 1),
      productName: (json['product_name_snapshot'] ?? '').toString(),
      variantTitle: (json['variant_title_snapshot'] ?? '').toString(),
      lineTotalCents: _toInt(json['line_total_cents_snapshot']),
      imagePathSnapshot: json['image_path_snapshot']?.toString(),
    );
  }
}
