class ProductVariantPricingModel {
  final String currency;
  final double amount;
  final int? priceCentsMxn;
  final double? priceUsd;

  const ProductVariantPricingModel({
    required this.currency,
    required this.amount,
    required this.priceCentsMxn,
    required this.priceUsd,
  });

  bool get hasPrice => amount > 0;

  static int? _toNullableInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _toNullableDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory ProductVariantPricingModel.fromJson(Map<String, dynamic> json) {
    final pricingJson = json['pricing'];
    final pricing = pricingJson is Map<String, dynamic>
        ? pricingJson
        : (pricingJson is Map ? Map<String, dynamic>.from(pricingJson) : null);

    final priceCentsMxn = _toNullableInt(pricing?['price_cents_mxn']) ??
        _toNullableInt(json['price_cents']);
    final priceUsd = _toNullableDouble(pricing?['price_usd']) ??
        _toNullableDouble(json['price_usd']);

    final explicitCurrency =
        (pricing?['currency'] ?? json['currency'])?.toString().trim();
    final explicitAmount = _toNullableDouble(pricing?['amount']) ??
        _toNullableDouble(json['amount']);

    if (explicitCurrency != null &&
        explicitCurrency.isNotEmpty &&
        explicitAmount != null) {
      return ProductVariantPricingModel(
        currency: explicitCurrency.toUpperCase(),
        amount: explicitAmount,
        priceCentsMxn: priceCentsMxn,
        priceUsd: priceUsd,
      );
    }

    if (priceCentsMxn != null) {
      return ProductVariantPricingModel(
        currency: 'MXN',
        amount: priceCentsMxn / 100.0,
        priceCentsMxn: priceCentsMxn,
        priceUsd: priceUsd,
      );
    }

    if (priceUsd != null) {
      return ProductVariantPricingModel(
        currency: 'USD',
        amount: priceUsd,
        priceCentsMxn: null,
        priceUsd: priceUsd,
      );
    }

    return const ProductVariantPricingModel(
      currency: 'MXN',
      amount: 0,
      priceCentsMxn: null,
      priceUsd: null,
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'amount': amount,
        'price_cents_mxn': priceCentsMxn,
        'price_usd': priceUsd,
      };
}
