import 'cart_item_variant_model.dart';

class CartItemModel {
  final int id;
  final int cartId;
  final int variantId;
  final int qty;

  final int priceCentsAtAdd;
  final String? variantTitleAtAdd;

  final CartItemVariantModel? variant;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.variantId,
    required this.qty,
    required this.priceCentsAtAdd,
    this.variantTitleAtAdd,
    this.variant,
  });

  double get unitPrice => priceCentsAtAdd / 100.0;
  double get lineTotal => unitPrice * qty;

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final variantJson = json['variant'];
    return CartItemModel(
      id: _toInt(json['id']),
      cartId: _toInt(json['cart_id']),
      variantId: _toInt(json['variant_id']),
      qty: _toInt(json['qty'], fallback: 1),
      priceCentsAtAdd: _toInt(json['price_cents_at_add']),
      variantTitleAtAdd: json['variant_title_at_add']?.toString(),
      variant: (variantJson is Map)
          ? CartItemVariantModel.fromJson(
              Map<String, dynamic>.from(variantJson),
            )
          : null,
    );
  }
}
