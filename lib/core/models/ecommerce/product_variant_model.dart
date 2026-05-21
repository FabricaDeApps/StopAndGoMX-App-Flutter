import 'product_variant_pricing_model.dart';

class ProductVariantListModel {
  final int id;
  final String title;
  final int priceCents;
  final double? priceUsd;
  final int stock;
  final bool isActive;
  final List<int> valueIds;
  final List<String> values; // ["M", "Roja"]
  final ProductVariantPricingModel pricing;

  ProductVariantListModel({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.priceUsd,
    required this.stock,
    required this.isActive,
    required this.valueIds,
    required this.values,
    required this.pricing,
  });

  String get displayCurrency => pricing.currency;
  double get displayAmount => pricing.amount;
  bool get hasDisplayPrice => pricing.hasPrice;

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory ProductVariantListModel.fromJson(Map<String, dynamic> json) {
    final valuesJson = (json['values'] as List?) ?? const [];
    final values = valuesJson
        .map(
          (e) {
            final valueMap = e as Map;
            return valueMap['label']?.toString() ??
                valueMap['value']?.toString() ??
                '';
          },
        )
        .where((v) => v.isNotEmpty)
        .toList();
    final valueIdsJson = (json['value_ids'] as List?) ?? const [];
    final pricing = ProductVariantPricingModel.fromJson(json);

    return ProductVariantListModel(
      id: _toInt(json['id'] ?? json['variant_id']),
      title: (json['title'] ?? '') as String,
      priceCents: pricing.priceCentsMxn ?? _toInt(json['price_cents']),
      priceUsd: pricing.priceUsd ?? _toNullableDouble(json['price_usd']),
      stock: _toInt(json['stock']),
      isActive: (json['is_active'] as bool?) ?? true,
      valueIds: valueIdsJson.map((e) => _toInt(e)).toList(),
      values: values,
      pricing: pricing,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price_cents': priceCents,
        'price_usd': priceUsd,
        'pricing': pricing.toJson(),
        'stock': stock,
        'is_active': isActive,
        'value_ids': valueIds,
        'values': values.map((v) => {'value': v}).toList(),
      };
}
