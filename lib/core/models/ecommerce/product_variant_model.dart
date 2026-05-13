class ProductVariantListModel {
  final int id;
  final String title;
  final int priceCents;
  final int stock;
  final bool isActive;
  final List<int> valueIds;
  final List<String> values; // ["M", "Roja"]

  ProductVariantListModel({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.stock,
    required this.isActive,
    required this.valueIds,
    required this.values,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory ProductVariantListModel.fromJson(Map<String, dynamic> json) {
    final valuesJson = (json['values'] as List?) ?? const [];
    final values = valuesJson
        .map((e) => (e as Map)['value']?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();
    final valueIdsJson = (json['value_ids'] as List?) ?? const [];

    return ProductVariantListModel(
      id: _toInt(json['id'] ?? json['variant_id']),
      title: (json['title'] ?? '') as String,
      priceCents: _toInt(json['price_cents']),
      stock: _toInt(json['stock']),
      isActive: (json['is_active'] as bool?) ?? true,
      valueIds: valueIdsJson.map((e) => _toInt(e)).toList(),
      values: values,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price_cents': priceCents,
    'stock': stock,
    'is_active': isActive,
    'value_ids': valueIds,
    'values': values.map((v) => {'value': v}).toList(),
  };
}
