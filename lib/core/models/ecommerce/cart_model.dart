import 'cart_item_model.dart';

class CartModel {
  final int id;
  final int organizationId;
  final int userId;
  final String status;
  final List<CartItemModel> items;

  CartModel({
    required this.id,
    required this.organizationId,
    required this.userId,
    required this.status,
    required this.items,
  });

  factory CartModel.empty() {
    return CartModel(
      id: 0,
      organizationId: 0,
      userId: 0,
      status: 'active',
      items: const [],
    );
  }

  double get subtotal => items.fold<double>(0, (sum, it) => sum + it.lineTotal);

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static Map<String, dynamic>? _asMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  factory CartModel.fromJson(Map<String, dynamic> json) {
    // A) wrapper normal: {data: {...}}
    final data1 = _asMap(json['data']);
    // B) wrapper alternativo: {data: {cart: {...}}}
    final data2 = _asMap(data1?['cart']);
    // C) sin wrapper: {...} (ya viene el cart)
    final data = data2 ?? data1 ?? json;

    // Si ni así hay cart válido, regresamos empty en vez de tronar
    final itemsRaw = data['items'];
    final itemsJson = (itemsRaw is List) ? itemsRaw : const [];

    return CartModel(
      id: _toInt(data['id']),
      organizationId: _toInt(data['organization_id']),
      userId: _toInt(data['user_id']),
      status: (data['status'] ?? '').toString(),
      items: itemsJson
          .map(
            (e) => CartItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }
}
