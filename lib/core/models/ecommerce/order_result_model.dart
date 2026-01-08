class OrderResultModel {
  final int id;
  final String folio;
  final String status;
  final int totalCents;
  final int subtotalCents;
  final int deliveryFeeCents;
  final String fulfillmentType;

  final List<OrderResultItemModel> items;

  OrderResultModel({
    required this.id,
    required this.folio,
    required this.status,
    required this.totalCents,
    required this.subtotalCents,
    required this.deliveryFeeCents,
    required this.fulfillmentType,
    required this.items,
  });

  double get total => totalCents / 100.0;

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory OrderResultModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'])
        : json;

    final itemsJson = (data['items'] is List)
        ? (data['items'] as List)
        : const [];

    final orgFolio = _toInt(data['org_folio']);
    final folio = orgFolio > 0
        ? 'ORG-${orgFolio.toString().padLeft(6, '0')}'
        : 'Pedido #${_toInt(data['id'])}';

    return OrderResultModel(
      id: _toInt(data['id']),
      folio: folio,
      status: (data['status'] ?? '').toString(),
      totalCents: _toInt(data['total_cents']),
      subtotalCents: _toInt(data['subtotal_cents']),
      deliveryFeeCents: _toInt(data['delivery_fee_cents']),
      fulfillmentType: (data['fulfillment_type'] ?? 'pickup').toString(),
      items: itemsJson
          .map(
            (e) => OrderResultItemModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class OrderResultItemModel {
  final int id;
  final int qty;
  final String productName;
  final String variantTitle;
  final int unitPriceCents;
  final int lineTotalCents;
  final String? imagePathSnapshot;

  OrderResultItemModel({
    required this.id,
    required this.qty,
    required this.productName,
    required this.variantTitle,
    required this.unitPriceCents,
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

  factory OrderResultItemModel.fromJson(Map<String, dynamic> json) {
    return OrderResultItemModel(
      id: _toInt(json['id']),
      qty: _toInt(json['qty'], fallback: 1),
      productName: (json['product_name_snapshot'] ?? '').toString(),
      variantTitle: (json['variant_title_snapshot'] ?? '').toString(),
      unitPriceCents: _toInt(json['unit_price_cents_snapshot']),
      lineTotalCents: _toInt(json['line_total_cents_snapshot']),
      imagePathSnapshot: json['image_path_snapshot']?.toString(),
    );
  }
}
