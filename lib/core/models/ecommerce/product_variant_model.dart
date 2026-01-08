class ProductVariantListModel {
  final int id;
  final String title;
  final int priceCents;
  final int stock;
  final List<String> values; // ["M", "Roja"]

  ProductVariantListModel({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.stock,
    required this.values,
  });

  factory ProductVariantListModel.fromJson(Map<String, dynamic> json) {
    final valuesJson = (json['values'] as List?) ?? const [];
    final values = valuesJson
        .map((e) => (e as Map)['value']?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .toList();

    return ProductVariantListModel(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      values: values,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price_cents': priceCents,
    'stock': stock,
    'values': values.map((v) => {'value': v}).toList(),
  };
}
